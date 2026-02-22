defmodule Wiki.Search do
  @moduledoc """
  Cross-source full-text search via PostgreSQL.

  Uses PostgreSQL's built-in full-text search with:
  - `to_tsvector` for indexing title + extracted_text
  - `plainto_tsquery` for user queries
  - `ts_rank` for relevance ordering
  - `ts_headline` for result snippets
  """

  import Ecto.Query

  alias Wiki.Content.Article
  alias Wiki.Repo

  @type source :: :osrs | :nlab | :wikipedia | :vintage_machinery | :wikiart

  @type result :: %{
          id: integer(),
          source: source(),
          slug: String.t(),
          title: String.t(),
          snippet: String.t(),
          rank: float()
        }

  @doc """
  Search articles by query string.

  Options:
  - `:source` - Filter to a specific source (default: all sources)
  - `:limit` - Max results (default: 30)
  - `:offset` - Pagination offset (default: 0)

  Returns results ordered by relevance with highlighted snippets.
  """
  @spec search(String.t(), keyword()) :: [result()]
  def search(query, opts \\ []) when is_binary(query) do
    query = String.trim(query)

    if query == "" do
      []
    else
      source = Keyword.get(opts, :source)
      limit = Keyword.get(opts, :limit, 30)
      offset = Keyword.get(opts, :offset, 0)

      do_search(query, source, limit, offset)
    end
  end

  defp do_search(query, source, limit, offset) do
    base_query()
    |> maybe_filter_source(source)
    |> where_matches(query)
    |> order_by_rank(query)
    |> select_with_snippet(query)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  defp base_query do
    from(a in Article, as: :article)
  end

  defp maybe_filter_source(query, nil), do: query
  defp maybe_filter_source(query, source), do: where(query, [a], a.source == ^source)

  defp where_matches(query, search_term) do
    where(
      query,
      [a],
      fragment(
        "to_tsvector('english', coalesce(?, '') || ' ' || coalesce(?, '')) @@ plainto_tsquery('english', ?)",
        a.title,
        a.extracted_text,
        ^search_term
      )
    )
  end

  defp order_by_rank(query, search_term) do
    order_by(
      query,
      [a],
      desc:
        fragment(
          "ts_rank(to_tsvector('english', coalesce(?, '') || ' ' || coalesce(?, '')), plainto_tsquery('english', ?))",
          a.title,
          a.extracted_text,
          ^search_term
        )
    )
  end

  defp select_with_snippet(query, search_term) do
    select(query, [a], %{
      id: a.id,
      source: a.source,
      slug: a.slug,
      title: a.title,
      snippet:
        fragment(
          "ts_headline('english', coalesce(?, ''), plainto_tsquery('english', ?), 'MaxFragments=2,MaxWords=30,StartSel=<mark>,StopSel=</mark>')",
          a.extracted_text,
          ^search_term
        ),
      rank:
        fragment(
          "ts_rank(to_tsvector('english', coalesce(?, '') || ' ' || coalesce(?, '')), plainto_tsquery('english', ?))",
          a.title,
          a.extracted_text,
          ^search_term
        )
    })
  end

  @doc """
  Suggest article titles matching a prefix.

  Uses trigram similarity for fuzzy matching.
  Useful for autocomplete.
  """
  @spec suggest(String.t(), keyword()) :: [
          %{title: String.t(), source: source(), slug: String.t()}
        ]
  def suggest(prefix, opts \\ []) when is_binary(prefix) do
    prefix = String.trim(prefix)

    if String.length(prefix) < 2 do
      []
    else
      source = Keyword.get(opts, :source)
      limit = Keyword.get(opts, :limit, 10)

      from(a in Article)
      |> maybe_filter_source(source)
      |> where([a], ilike(a.title, ^"#{prefix}%"))
      |> or_where([a], fragment("? % ?", a.title, ^prefix))
      |> order_by([a], desc: fragment("similarity(?, ?)", a.title, ^prefix))
      |> select([a], %{title: a.title, source: a.source, slug: a.slug})
      |> limit(^limit)
      |> Repo.all()
    end
  end

  @doc """
  Count total search results for a query.

  Useful for pagination.
  """
  @spec count(String.t(), keyword()) :: integer()
  def count(query, opts \\ []) when is_binary(query) do
    query = String.trim(query)

    if query == "" do
      0
    else
      source = Keyword.get(opts, :source)

      base_query()
      |> maybe_filter_source(source)
      |> where_matches(query)
      |> Repo.aggregate(:count)
    end
  end

  @doc """
  Get available sources with article counts.
  """
  @spec source_counts() :: %{source() => integer()}
  def source_counts do
    from(a in Article, group_by: a.source, select: {a.source, count(a.id)})
    |> Repo.all()
    |> Map.new()
  end
end
