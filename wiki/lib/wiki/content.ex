defmodule Wiki.Content do
  @moduledoc """
  Context module for wiki content operations.

  Provides high-level functions for querying and managing articles
  across all sources.
  """

  import Ecto.Query

  alias Wiki.Content.{Article, Redirect}
  alias Wiki.{Cache, Repo}

  @type source :: :osrs | :nlab | :wikipedia | :vintage_machinery | :wikiart

  @doc """
  Get an article by source and slug.

  Follows redirects automatically. Returns the article with HTML content
  loaded from storage.
  """
  @spec get_article(source(), String.t()) :: {:ok, Article.t(), String.t()} | {:error, :not_found}
  def get_article(source, slug) do
    slug = resolve_redirect(source, slug)

    case Repo.one(from a in Article, where: a.source == ^source and a.slug == ^slug) do
      nil ->
        {:error, :not_found}

      article ->
        html = load_html(article)
        {:ok, article, html}
    end
  end

  @doc """
  Get an article by ID.
  """
  @spec get_article_by_id(integer()) :: Article.t() | nil
  def get_article_by_id(id) do
    Repo.get(Article, id)
  end

  @doc """
  List articles for a source.

  Options:
  - :limit - max results (default 50)
  - :offset - pagination offset
  - :order_by - :title | :updated_at (default :title)
  """
  @spec list_articles(source(), keyword()) :: [Article.t()]
  def list_articles(source, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)
    order_by = Keyword.get(opts, :order_by, :title)

    from(a in Article, where: a.source == ^source)
    |> order_by_field(order_by)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  @doc """
  Search articles by title or content.

  Uses PostgreSQL full-text search on the extracted_text field.
  """
  @spec search(String.t(), keyword()) :: [Article.t()]
  def search(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    source = Keyword.get(opts, :source)

    tsquery = to_tsquery(query)

    from(a in Article)
    |> maybe_filter_source(source)
    |> where(
      [a],
      fragment(
        "to_tsvector('english', coalesce(?, '') || ' ' || coalesce(?, '')) @@ to_tsquery('english', ?)",
        a.title,
        a.extracted_text,
        ^tsquery
      )
    )
    |> order_by([a],
      desc:
        fragment(
          "ts_rank(to_tsvector('english', coalesce(?, '') || ' ' || coalesce(?, '')), to_tsquery('english', ?))",
          a.title,
          a.extracted_text,
          ^tsquery
        )
    )
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Count articles per source.
  """
  @spec count_by_source() :: %{source() => integer()}
  def count_by_source do
    from(a in Article, group_by: a.source, select: {a.source, count(a.id)})
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Get recent articles across all sources.
  """
  @spec recent_articles(integer()) :: [Article.t()]
  def recent_articles(limit \\ 20) do
    from(a in Article, order_by: [desc: a.synced_at], limit: ^limit)
    |> Repo.all()
  end

  # Redirects

  defp resolve_redirect(source, slug) do
    case Repo.one(from r in Redirect, where: r.source == ^source and r.from_slug == ^slug) do
      nil -> slug
      redirect -> redirect.to_slug
    end
  end

  @doc """
  Create a redirect from one slug to another.
  """
  @spec create_redirect(source(), String.t(), String.t()) ::
          {:ok, Redirect.t()} | {:error, Ecto.Changeset.t()}
  def create_redirect(source, from_slug, to_slug) do
    %Redirect{}
    |> Redirect.changeset(%{source: source, from_slug: from_slug, to_slug: to_slug})
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:source, :from_slug])
  end

  # Private helpers

  defp load_html(%Article{} = article) do
    Cache.fetch_html(article)
  end

  defp order_by_field(query, :title), do: order_by(query, [a], asc: a.title)
  defp order_by_field(query, :updated_at), do: order_by(query, [a], desc: a.updated_at)
  defp order_by_field(query, _), do: order_by(query, [a], asc: a.title)

  defp maybe_filter_source(query, nil), do: query
  defp maybe_filter_source(query, source), do: where(query, [a], a.source == ^source)

  defp to_tsquery(query) do
    query
    |> String.split(~r/\s+/)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.replace(&1, ~r/[^\w]/, ""))
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" & ")
  end
end
