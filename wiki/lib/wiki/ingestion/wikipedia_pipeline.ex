defmodule Wiki.Ingestion.WikipediaPipeline do
  @moduledoc """
  Pipeline for ingesting Wikipedia content.

  Wikipedia provides pre-rendered HTML via their REST API,
  so we don't need to parse wikitext ourselves.

  This pipeline:
  1. Fetches page HTML and summary from REST API
  2. Cleans and rewrites links
  3. Stores content in MinIO
  4. Creates/updates article records

  Note: This is a curated ingestion - we ingest specific pages
  that are relevant to our other sources (OSRS, nLab, etc.)
  rather than mirroring all of Wikipedia.
  """

  require Logger

  alias Wiki.Content.Article
  alias Wiki.Ingestion.WikipediaClient
  alias Wiki.{Cache, Repo, Storage}

  import Ecto.Query

  @source :wikipedia
  @license "CC BY-SA 4.0"
  @upstream_base "https://en.wikipedia.org/wiki/"

  @type result :: {:created | :updated | :unchanged, Article.t()} | {:error, term()}

  @doc """
  Process a single page by slug.
  """
  @spec process_page(String.t()) :: result()
  def process_page(slug) do
    with {:ok, page} <- WikipediaClient.get_page(slug),
         {:ok, article} <- upsert_article(page) do
      article
    else
      {:error, :not_found} ->
        Logger.debug("Wikipedia page not found: #{slug}")
        {:error, :not_found}

      {:error, reason} = error ->
        Logger.error("Failed to process Wikipedia page #{slug}: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Process multiple pages by slug.
  """
  @spec process_pages([String.t()]) :: %{String.t() => result()}
  def process_pages(slugs) when is_list(slugs) do
    slugs
    |> Task.async_stream(&process_page/1, max_concurrency: 2, timeout: 60_000)
    |> Enum.zip(slugs)
    |> Enum.map(fn
      {{:ok, result}, slug} -> {slug, result}
      {{:exit, reason}, slug} -> {slug, {:error, reason}}
    end)
    |> Map.new()
  end

  @doc """
  Import pages related to a search query.

  Searches Wikipedia and imports matching pages.
  """
  @spec import_search(String.t(), keyword()) ::
          {:ok,
           %{created: integer(), updated: integer(), unchanged: integer(), errors: integer()}}
          | {:error, term()}
  def import_search(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    with {:ok, results} <- WikipediaClient.search(query, limit: limit) do
      slugs = Enum.map(results, & &1["key"])
      Logger.info("Importing #{length(slugs)} Wikipedia pages for query: #{query}")

      results = process_pages(slugs)
      {:ok, aggregate_stats(results)}
    end
  end

  @doc """
  Import pages related to an existing article.

  Fetches Wikipedia's "related pages" and imports them.
  """
  @spec import_related(String.t(), keyword()) ::
          {:ok,
           %{created: integer(), updated: integer(), unchanged: integer(), errors: integer()}}
          | {:error, term()}
  def import_related(slug, opts \\ []) do
    limit = Keyword.get(opts, :limit, 5)

    with {:ok, related} <- WikipediaClient.get_related(slug, limit: limit) do
      slugs = Enum.map(related, & &1["title"])
      Logger.info("Importing #{length(slugs)} related Wikipedia pages for: #{slug}")

      results = process_pages(slugs)
      {:ok, aggregate_stats(results)}
    end
  end

  @doc """
  Refresh all existing Wikipedia articles.

  Re-fetches content for all articles we've already ingested.
  """
  @spec refresh_all(keyword()) ::
          {:ok,
           %{created: integer(), updated: integer(), unchanged: integer(), errors: integer()}}
          | {:error, term()}
  def refresh_all(opts \\ []) do
    limit = Keyword.get(opts, :limit, 1000)

    slugs =
      from(a in Article, where: a.source == @source, select: a.slug, limit: ^limit)
      |> Repo.all()

    Logger.info("Refreshing #{length(slugs)} Wikipedia articles")

    results = process_pages(slugs)
    {:ok, aggregate_stats(results)}
  end

  # Private functions

  defp upsert_article(page) do
    html = clean_html(page.html)
    content_hash = hash_content(html)

    @source
    |> find_existing(page.slug)
    |> do_upsert(page, html, content_hash)
  end

  defp find_existing(source, slug) do
    Repo.one(from a in Article, where: a.source == ^source and a.slug == ^slug)
  end

  defp do_upsert(nil, page, html, content_hash) do
    save_article(:insert, nil, page, html, content_hash)
  end

  defp do_upsert(%Article{upstream_hash: hash} = existing, _page, _html, hash) do
    {:unchanged, existing}
  end

  defp do_upsert(existing, page, html, content_hash) do
    save_article(:update, existing, page, html, content_hash)
  end

  defp save_article(operation, existing, page, html, content_hash) do
    with {:ok, html_key} <- Storage.put_html(@source, page.slug, html),
         {:ok, raw_key} <- Storage.put_raw(@source, page.slug, page.html),
         attrs = build_article_attrs(page, html_key, raw_key, content_hash),
         {:ok, article} <- persist_article(operation, existing, attrs) do
      Cache.invalidate(@source, page.slug)
      log_operation(operation, page.title)
      {operation_result(operation), article}
    else
      {:error, changeset} -> {:error, {:"#{operation}_failed", changeset}}
    end
  end

  defp build_article_attrs(page, html_key, raw_key, content_hash) do
    %{
      source: @source,
      slug: page.slug,
      title: page.title,
      extracted_text: page.extract,
      rendered_html_key: html_key,
      raw_content_key: raw_key,
      upstream_url: upstream_url(page.slug),
      upstream_hash: content_hash,
      status: :synced,
      license: @license,
      metadata: %{
        "description" => page.description,
        "image_url" => page.image_url
      },
      synced_at: DateTime.utc_now()
    }
  end

  defp persist_article(:insert, _existing, attrs) do
    Repo.insert(Article.changeset(attrs))
  end

  defp persist_article(:update, existing, attrs) do
    Repo.update(Article.changeset(existing, attrs))
  end

  defp operation_result(:insert), do: :created
  defp operation_result(:update), do: :updated

  defp log_operation(:insert, title), do: Logger.info("Created Wikipedia article: #{title}")
  defp log_operation(:update, title), do: Logger.info("Updated Wikipedia article: #{title}")

  defp clean_html(html) do
    case Floki.parse_document(html) do
      {:ok, doc} ->
        doc
        |> remove_unwanted_elements()
        |> rewrite_links()
        |> Floki.raw_html()

      _ ->
        html
    end
  end

  defp remove_unwanted_elements(doc) do
    doc
    |> Floki.filter_out("script")
    |> Floki.filter_out("style")
    |> Floki.filter_out(".mw-editsection")
    |> Floki.filter_out(".navbox")
    |> Floki.filter_out(".sistersitebox")
    |> Floki.filter_out(".noprint")
    |> Floki.filter_out("#coordinates")
  end

  defp rewrite_links(doc) do
    Floki.traverse_and_update(doc, fn
      {"a", attrs, children} ->
        {"a", rewrite_href(attrs), children}

      {"img", attrs, children} ->
        {"img", rewrite_src(attrs), children}

      other ->
        other
    end)
  end

  defp rewrite_href(attrs) do
    Enum.map(attrs, fn
      {"href", "./wiki/" <> slug} -> {"href", "/wikipedia/#{slug}"}
      {"href", "/wiki/" <> slug} -> {"href", "/wikipedia/#{slug}"}
      other -> other
    end)
  end

  defp rewrite_src(attrs) do
    Enum.map(attrs, fn
      {"src", "//" <> rest} -> {"src", "https://#{rest}"}
      other -> other
    end)
  end

  defp hash_content(html) do
    :crypto.hash(:sha256, html) |> Base.encode16(case: :lower)
  end

  defp upstream_url(slug) do
    @upstream_base <> URI.encode(slug)
  end

  defp aggregate_stats(results) do
    Enum.reduce(results, %{created: 0, updated: 0, unchanged: 0, errors: 0}, fn
      {_slug, {:created, _}}, acc -> Map.update!(acc, :created, &(&1 + 1))
      {_slug, {:updated, _}}, acc -> Map.update!(acc, :updated, &(&1 + 1))
      {_slug, {:unchanged, _}}, acc -> Map.update!(acc, :unchanged, &(&1 + 1))
      {_slug, {:error, _}}, acc -> Map.update!(acc, :errors, &(&1 + 1))
    end)
  end
end
