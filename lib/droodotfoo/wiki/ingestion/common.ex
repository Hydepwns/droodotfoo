defmodule Droodotfoo.Wiki.Ingestion.Common do
  @moduledoc """
  Shared utilities for wiki ingestion pipelines.

  Provides common functions used across OSRS, nLab, Wikipedia,
  and VintageMachinery pipelines to reduce code duplication.
  """

  alias Droodotfoo.Wiki.Content.Article
  alias Droodotfoo.Repo

  import Ecto.Query

  @doc """
  Hash content using SHA256 for change detection.

  Returns lowercase hex-encoded hash string.
  """
  @spec hash_content(String.t()) :: String.t()
  def hash_content(content) do
    :crypto.hash(:sha256, content) |> Base.encode16(case: :lower)
  end

  @doc """
  Extract plain text from HTML for full-text search indexing.

  Strips tags, normalizes whitespace, and truncates to max_length.
  """
  @spec extract_text(String.t(), pos_integer()) :: String.t()
  def extract_text(html, max_length \\ 100_000) do
    html
    |> Floki.parse_document!()
    |> Floki.text(sep: " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> String.slice(0, max_length)
  end

  @doc """
  Aggregate pipeline results into stats map.

  Takes a map of `%{key => result}` and counts created/updated/unchanged/errors.
  """
  @spec aggregate_stats(%{any() => {:created | :updated | :unchanged, any()} | {:error, any()}}) ::
          %{
            created: non_neg_integer(),
            updated: non_neg_integer(),
            unchanged: non_neg_integer(),
            errors: non_neg_integer()
          }
  def aggregate_stats(results) do
    Enum.reduce(results, %{created: 0, updated: 0, unchanged: 0, errors: 0}, fn
      {_key, {:created, _}}, acc -> Map.update!(acc, :created, &(&1 + 1))
      {_key, {:updated, _}}, acc -> Map.update!(acc, :updated, &(&1 + 1))
      {_key, {:unchanged, _}}, acc -> Map.update!(acc, :unchanged, &(&1 + 1))
      {_key, {:error, _}}, acc -> Map.update!(acc, :errors, &(&1 + 1))
    end)
  end

  @doc """
  Find an existing article by source and slug.
  """
  @spec find_article(atom(), String.t()) :: Article.t() | nil
  def find_article(source, slug) do
    Repo.one(from(a in Article, where: a.source == ^source and a.slug == ^slug))
  end

  @doc """
  List article slugs for a given source.
  """
  @spec list_article_slugs(atom(), pos_integer()) :: [String.t()]
  def list_article_slugs(source, limit) do
    from(a in Article, where: a.source == ^source, select: a.slug, limit: ^limit)
    |> Repo.all()
  end

  @doc """
  Build upstream URL from base and slug.

  Uses URI-safe encoding for the slug.
  """
  @spec upstream_url(String.t(), String.t()) :: String.t()
  def upstream_url(base, slug) do
    base <> URI.encode(slug, &URI.char_unreserved?/1)
  end

  @doc """
  Convert a slug to a human-readable title.

  Replaces underscores and hyphens with spaces, capitalizes each word.

  ## Examples

      iex> Common.humanize_slug("hello_world")
      "Hello World"

      iex> Common.humanize_slug("some-page-title")
      "Some Page Title"

  """
  @spec humanize_slug(String.t()) :: String.t()
  def humanize_slug(slug) do
    slug
    |> String.replace(~r/[-_]/, " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  @doc """
  Process multiple pages concurrently using Task.async_stream.

  Returns a map of `%{key => result}`.
  """
  @spec process_pages_concurrent([any()], (any() -> any()), keyword()) :: %{any() => any()}
  def process_pages_concurrent(items, process_fn, opts \\ []) do
    max_concurrency = Keyword.get(opts, :max_concurrency, 4)
    timeout = Keyword.get(opts, :timeout, 60_000)

    items
    |> Task.async_stream(process_fn, max_concurrency: max_concurrency, timeout: timeout)
    |> Enum.zip(items)
    |> Enum.map(fn
      {{:ok, result}, key} -> {key, result}
      {{:exit, reason}, key} -> {key, {:error, reason}}
    end)
    |> Map.new()
  end

  @doc """
  Process multiple pages sequentially.

  Returns a map of `%{key => result}`.
  """
  @spec process_pages_sequential([any()], (any() -> any())) :: %{any() => any()}
  def process_pages_sequential(items, process_fn) do
    items
    |> Enum.map(fn item -> {item, process_fn.(item)} end)
    |> Map.new()
  end

  @doc """
  Clean HTML by parsing, applying transformations, and converting back to string.

  If parsing fails, returns the original HTML unchanged.

  ## Examples

      Common.clean_html(html, fn doc ->
        doc
        |> Common.filter_out_all(["script", "style", ".navbox"])
        |> rewrite_links()
      end)

  """
  @spec clean_html(String.t(), (Floki.html_tree() -> Floki.html_tree())) :: String.t()
  def clean_html(html, transform_fn) do
    case Floki.parse_document(html) do
      {:ok, doc} ->
        doc
        |> transform_fn.()
        |> Floki.raw_html()

      _ ->
        html
    end
  end

  @doc """
  Filter out multiple selectors from a Floki document.

  ## Examples

      Common.filter_out_all(doc, ["script", "style", "nav", ".sidebar"])

  """
  @spec filter_out_all(Floki.html_tree(), [String.t()]) :: Floki.html_tree()
  def filter_out_all(doc, selectors) do
    Enum.reduce(selectors, doc, fn selector, acc ->
      Floki.filter_out(acc, selector)
    end)
  end

  @doc """
  Persist an article to the database (insert or update).

  ## Examples

      Common.persist_article(:insert, nil, attrs)
      Common.persist_article(:update, existing_article, attrs)

  """
  @spec persist_article(:insert | :update, Article.t() | nil, map()) ::
          {:ok, Article.t()} | {:error, Ecto.Changeset.t()}
  def persist_article(:insert, _existing, attrs) do
    Repo.insert(Article.changeset(attrs))
  end

  def persist_article(:update, existing, attrs) do
    Repo.update(Article.changeset(existing, attrs))
  end

  @doc """
  Convert operation atom to result atom.

  ## Examples

      iex> Common.operation_result(:insert)
      :created

      iex> Common.operation_result(:update)
      :updated

  """
  @spec operation_result(:insert | :update) :: :created | :updated
  def operation_result(:insert), do: :created
  def operation_result(:update), do: :updated
end
