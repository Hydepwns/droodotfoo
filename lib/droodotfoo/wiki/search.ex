defmodule Droodotfoo.Wiki.Search do
  @moduledoc """
  Cross-source search via PostgreSQL with multiple modes.

  Supports three search modes:
  - `:keyword` - Traditional full-text search (default for fast results)
  - `:semantic` - Vector similarity search using embeddings
  - `:hybrid` - Combines keyword and semantic using Reciprocal Rank Fusion

  Uses PostgreSQL's built-in full-text search with:
  - `to_tsvector` for indexing title + extracted_text
  - `plainto_tsquery` for user queries
  - `ts_rank` for relevance ordering
  - `ts_headline` for result snippets

  Uses pgvector for semantic search with:
  - `<=>` operator for cosine distance
  - HNSW index for fast approximate nearest neighbor
  """

  import Ecto.Query

  alias Droodotfoo.Wiki.Content.Article
  alias Droodotfoo.Wiki.Ollama
  alias Droodotfoo.Repo

  @type source :: :osrs | :nlab | :wikipedia | :vintage_machinery | :wikiart
  @type search_mode :: :keyword | :semantic | :hybrid

  @type result :: %{
          id: integer(),
          source: source(),
          slug: String.t(),
          title: String.t(),
          snippet: String.t(),
          rank: float()
        }

  # RRF constant (typically 60)
  @rrf_k 60

  @doc """
  Search articles by query string.

  Options:
  - `:source` - Filter to a specific source (default: all sources)
  - `:limit` - Max results (default: 30)
  - `:offset` - Pagination offset (default: 0)
  - `:mode` - Search mode: :keyword, :semantic, or :hybrid (default: :keyword)

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
      mode = Keyword.get(opts, :mode, :keyword)

      case mode do
        :keyword -> keyword_search(query, source, limit, offset)
        :semantic -> semantic_search(query, source, limit, offset)
        :hybrid -> hybrid_search(query, source, limit, offset)
      end
    end
  end

  @doc """
  Keyword-based full-text search.

  Fast lexical matching using PostgreSQL FTS.
  """
  @spec keyword_search(String.t(), source() | nil, integer(), integer()) :: [result()]
  def keyword_search(query, source, limit, offset) do
    base_query()
    |> maybe_filter_source(source)
    |> where_matches(query)
    |> order_by_rank(query)
    |> select_with_snippet(query)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  @doc """
  Semantic search using vector similarity.

  Generates embedding for query and finds nearest neighbors.
  Falls back to keyword search if embedding fails.
  """
  @spec semantic_search(String.t(), source() | nil, integer(), integer()) :: [result()]
  def semantic_search(query, source, limit, offset) do
    case Ollama.embed(query) do
      {:ok, query_embedding} ->
        do_semantic_search(query, query_embedding, source, limit, offset)

      {:error, _reason} ->
        keyword_search(query, source, limit, offset)
    end
  end

  defp do_semantic_search(query, query_embedding, source, limit, offset) do
    base_query()
    |> maybe_filter_source(source)
    |> where([a], not is_nil(a.embedding))
    |> order_by([a], asc: fragment("? <=> ?::vector", a.embedding, ^query_embedding))
    |> select_semantic(query)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  defp select_semantic(db_query, search_term) do
    select(db_query, [a], %{
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
      rank: 1.0
    })
  end

  @doc """
  Hybrid search combining keyword and semantic results.

  Uses Reciprocal Rank Fusion (RRF) to merge rankings:
    RRF(d) = sum(1 / (k + rank_i(d)))

  Falls back to keyword search if embedding fails.
  """
  @spec hybrid_search(String.t(), source() | nil, integer(), integer()) :: [result()]
  def hybrid_search(query, source, limit, offset) do
    case Ollama.embed(query) do
      {:ok, query_embedding} ->
        do_hybrid_search(query, query_embedding, source, limit, offset)

      {:error, _reason} ->
        keyword_search(query, source, limit, offset)
    end
  end

  defp do_hybrid_search(query, query_embedding, source, limit, offset) do
    # Fetch enough results from each method to cover offset + limit after merging
    # We need at least (offset + limit) from each source since RRF can interleave
    fetch_limit = max(limit * 2, offset + limit)

    keyword_results = keyword_search(query, source, fetch_limit, 0)
    semantic_results = do_semantic_search(query, query_embedding, source, fetch_limit, 0)

    merge_rrf(keyword_results, semantic_results)
    |> Enum.drop(offset)
    |> Enum.take(limit)
  end

  defp merge_rrf(keyword_results, semantic_results) do
    keyword_ranks = rank_map(keyword_results)
    semantic_ranks = rank_map(semantic_results)

    all_ids =
      MapSet.union(MapSet.new(Map.keys(keyword_ranks)), MapSet.new(Map.keys(semantic_ranks)))

    results_by_id =
      (keyword_results ++ semantic_results)
      |> Enum.uniq_by(& &1.id)
      |> Map.new(&{&1.id, &1})

    all_ids
    |> Enum.map(fn id ->
      keyword_rank = Map.get(keyword_ranks, id)
      semantic_rank = Map.get(semantic_ranks, id)

      rrf_score = rrf_score(keyword_rank, semantic_rank)
      result = Map.get(results_by_id, id)

      Map.put(result, :rank, rrf_score)
    end)
    |> Enum.sort_by(& &1.rank, :desc)
  end

  defp rank_map(results) do
    results
    |> Enum.with_index(1)
    |> Map.new(fn {result, rank} -> {result.id, rank} end)
  end

  defp rrf_score(nil, semantic_rank), do: 1 / (@rrf_k + semantic_rank)
  defp rrf_score(keyword_rank, nil), do: 1 / (@rrf_k + keyword_rank)

  defp rrf_score(keyword_rank, semantic_rank) do
    1 / (@rrf_k + keyword_rank) + 1 / (@rrf_k + semantic_rank)
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

  Useful for pagination. Only counts keyword matches.
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

  @doc """
  Get count of articles with embeddings.
  """
  @spec embedded_count() :: integer()
  def embedded_count do
    from(a in Article, where: not is_nil(a.embedding))
    |> Repo.aggregate(:count)
  end
end
