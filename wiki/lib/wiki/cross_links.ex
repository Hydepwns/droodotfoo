defmodule Wiki.CrossLinks do
  @moduledoc """
  Context for cross-source article linking.

  Uses PostgreSQL pg_trgm extension for fuzzy title matching
  to automatically detect related articles across different sources.

  Relationships:
  - `:same_topic` - High confidence match (>0.8 similarity)
  - `:related` - Medium confidence match (0.5-0.8 similarity)
  - `:see_also` - Manual curation or lower confidence
  """

  import Ecto.Query

  alias Wiki.Content.{Article, CrossReference}
  alias Wiki.Repo

  require Logger

  @min_similarity 0.3
  @same_topic_threshold 0.8
  @related_threshold 0.5

  # ===========================================================================
  # Queries
  # ===========================================================================

  @doc """
  Get related articles for a given article.

  Returns articles from OTHER sources that are linked to this article.
  """
  @spec get_related(Article.t(), keyword()) :: [map()]
  def get_related(%Article{id: article_id, source: source}, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    outgoing_query =
      from(cr in CrossReference,
        join: a in Article,
        on: a.id == cr.related_article_id,
        where: cr.article_id == ^article_id and a.source != ^source,
        select: %{
          id: a.id,
          source: a.source,
          slug: a.slug,
          title: a.title,
          relationship: cr.relationship,
          confidence: cr.confidence
        }
      )

    incoming_query =
      from(cr in CrossReference,
        join: a in Article,
        on: a.id == cr.article_id,
        where: cr.related_article_id == ^article_id and a.source != ^source,
        select: %{
          id: a.id,
          source: a.source,
          slug: a.slug,
          title: a.title,
          relationship: cr.relationship,
          confidence: cr.confidence
        }
      )

    outgoing_query
    |> union_all(^incoming_query)
    |> subquery()
    |> distinct([r], r.id)
    |> order_by([r], desc: r.confidence)
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Get all cross-references for an article (both directions).
  """
  @spec list_references(integer()) :: [CrossReference.t()]
  def list_references(article_id) do
    from(cr in CrossReference,
      where: cr.article_id == ^article_id or cr.related_article_id == ^article_id,
      preload: [:article, :related_article]
    )
    |> Repo.all()
  end

  # ===========================================================================
  # Detection
  # ===========================================================================

  @doc """
  Find potential related articles using pg_trgm similarity.

  Returns articles from OTHER sources with similar titles.
  """
  @spec find_similar(Article.t(), keyword()) :: [map()]
  def find_similar(%Article{id: article_id, source: source, title: title}, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    min_sim = Keyword.get(opts, :min_similarity, @min_similarity)

    from(a in Article,
      where: a.source != ^source and a.id != ^article_id,
      where: fragment("similarity(?, ?) > ?", a.title, ^title, ^min_sim),
      select: %{
        id: a.id,
        source: a.source,
        slug: a.slug,
        title: a.title,
        similarity: fragment("similarity(?, ?)", a.title, ^title)
      },
      order_by: [desc: fragment("similarity(?, ?)", a.title, ^title)],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Detect and create cross-references for an article.

  Finds similar articles and creates CrossReference records.
  Returns the number of references created.
  """
  @spec detect_links(Article.t()) :: {:ok, integer()} | {:error, term()}
  def detect_links(%Article{} = article) do
    now = DateTime.utc_now()

    refs =
      article
      |> find_similar(min_similarity: @min_similarity)
      |> Enum.map(&build_reference(article.id, &1, now))

    case refs do
      [] ->
        {:ok, 0}

      refs ->
        {count, _} =
          Repo.insert_all(CrossReference, refs,
            on_conflict: {:replace, [:confidence, :updated_at]},
            conflict_target: [:article_id, :related_article_id]
          )

        {:ok, count}
    end
  end

  defp build_reference(article_id, match, timestamp) do
    %{
      article_id: article_id,
      related_article_id: match.id,
      relationship: classify_relationship(match.similarity),
      confidence: match.similarity,
      auto_detected: true,
      inserted_at: timestamp,
      updated_at: timestamp
    }
  end

  @doc """
  Detect cross-references for all articles from a source.

  Returns stats about references created.
  """
  @spec detect_all(atom(), keyword()) :: {:ok, map()}
  def detect_all(source, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10_000)

    articles =
      from(a in Article, where: a.source == ^source, limit: ^limit)
      |> Repo.all()

    Logger.info("Detecting cross-links for #{length(articles)} #{source} articles")

    stats =
      Enum.reduce(articles, %{total: 0, with_links: 0}, fn article, acc ->
        case detect_links(article) do
          {:ok, 0} -> acc
          {:ok, n} -> %{acc | total: acc.total + n, with_links: acc.with_links + 1}
          {:error, _} -> acc
        end
      end)

    Logger.info("Created #{stats.total} cross-references for #{stats.with_links} articles")

    {:ok,
     %{
       total_links: stats.total,
       articles_processed: length(articles),
       articles_with_links: stats.with_links
     }}
  end

  # ===========================================================================
  # Management
  # ===========================================================================

  @doc """
  Manually create a cross-reference.
  """
  @spec create_reference(integer(), integer(), atom(), keyword()) ::
          {:ok, CrossReference.t()} | {:error, Ecto.Changeset.t()}
  def create_reference(article_id, related_id, relationship, opts \\ []) do
    confidence = Keyword.get(opts, :confidence, 1.0)

    CrossReference.changeset(%{
      article_id: article_id,
      related_article_id: related_id,
      relationship: relationship,
      confidence: confidence,
      auto_detected: false
    })
    |> Repo.insert(
      on_conflict: {:replace, [:relationship, :confidence, :auto_detected, :updated_at]},
      conflict_target: [:article_id, :related_article_id]
    )
  end

  @doc """
  Delete a cross-reference.
  """
  @spec delete_reference(integer(), integer()) :: :ok
  def delete_reference(article_id, related_id) do
    from(cr in CrossReference,
      where: cr.article_id == ^article_id and cr.related_article_id == ^related_id
    )
    |> Repo.delete_all()

    :ok
  end

  @doc """
  Delete all auto-detected references for an article.
  """
  @spec clear_auto_references(integer()) :: :ok
  def clear_auto_references(article_id) do
    from(cr in CrossReference,
      where: cr.article_id == ^article_id and cr.auto_detected == true
    )
    |> Repo.delete_all()

    :ok
  end

  @doc """
  Get statistics about cross-references.
  """
  @spec stats() :: map()
  def stats do
    total =
      from(cr in CrossReference, select: count(cr.id))
      |> Repo.one()

    by_relationship =
      from(cr in CrossReference,
        group_by: cr.relationship,
        select: {cr.relationship, count(cr.id)}
      )
      |> Repo.all()
      |> Map.new()

    auto_detected =
      from(cr in CrossReference, where: cr.auto_detected == true, select: count(cr.id))
      |> Repo.one()

    %{
      total: total,
      by_relationship: by_relationship,
      auto_detected: auto_detected,
      manual: total - auto_detected
    }
  end

  # ===========================================================================
  # Private
  # ===========================================================================

  defp classify_relationship(similarity) when similarity >= @same_topic_threshold, do: :same_topic
  defp classify_relationship(similarity) when similarity >= @related_threshold, do: :related
  defp classify_relationship(_), do: :see_also
end
