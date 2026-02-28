defmodule Droodotfoo.Wiki.Ingestion.VintageMachineryPipeline do
  @moduledoc """
  Pipeline for ingesting VintageMachinery.org content.

  VintageMachinery is a site with vintage machinery documentation,
  manuals, and manufacturer information.

  This pipeline:
  1. Syncs the site via wget --mirror
  2. Parses HTML pages
  3. Cleans and normalizes content
  4. Stores content in MinIO
  5. Creates/updates article records
  """

  require Logger

  alias Droodotfoo.Wiki.Content.Article
  alias Droodotfoo.Wiki.Ingestion.{Common, VintageMachineryClient}
  alias Droodotfoo.Wiki.{Cache, Storage}

  @source :vintage_machinery
  @license "Used with permission"
  @upstream_base "https://vintagemachinery.org/"

  @type result :: {:created | :updated | :unchanged, Article.t()} | {:error, term()}

  @doc """
  Process a single page by slug.
  """
  @spec process_page(String.t()) :: result()
  def process_page(slug) do
    with {:ok, page} <- VintageMachineryClient.get_page(slug),
         {status, article} when status in [:created, :updated, :unchanged] <- upsert_article(page) do
      {status, article}
    else
      {:error, :not_found} ->
        Logger.debug("VintageMachinery page not found: #{slug}")
        {:error, :not_found}

      {:error, reason} = error ->
        Logger.error("Failed to process VintageMachinery page #{slug}: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Process multiple pages by slug.
  """
  @spec process_pages([String.t()]) :: %{String.t() => result()}
  def process_pages(slugs) when is_list(slugs) do
    Common.process_pages_concurrent(slugs, &process_page/1, max_concurrency: 4)
  end

  @doc """
  Full sync - mirror site and process all pages.
  """
  @spec sync_all(keyword()) ::
          {:ok,
           %{created: integer(), updated: integer(), unchanged: integer(), errors: integer()}}
          | {:error, term()}
  def sync_all(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50_000)

    with {:ok, _path} <- VintageMachineryClient.sync_site(full: true),
         {:ok, slugs} <- VintageMachineryClient.list_pages() do
      slugs = Enum.take(slugs, limit)
      Logger.info("Processing #{length(slugs)} VintageMachinery pages")

      results = process_pages(slugs)
      {:ok, Common.aggregate_stats(results)}
    end
  end

  @doc """
  Incremental sync - process pages modified since last successful sync.
  """
  @spec sync_recent_changes(DateTime.t() | nil) ::
          {:ok,
           %{created: integer(), updated: integer(), unchanged: integer(), errors: integer()}}
          | {:error, term()}
  def sync_recent_changes(since \\ nil) do
    since = since || default_since()

    with {:ok, _path} <- VintageMachineryClient.sync_site(),
         {:ok, slugs} <- VintageMachineryClient.list_modified_pages(since) do
      if slugs == [] do
        Logger.info("No VintageMachinery pages modified since #{since}")
        {:ok, %{created: 0, updated: 0, unchanged: 0, errors: 0}}
      else
        Logger.info("Processing #{length(slugs)} modified VintageMachinery pages")
        results = process_pages(slugs)
        {:ok, Common.aggregate_stats(results)}
      end
    end
  end

  # Private functions

  defp upsert_article(page) do
    html = clean_html(page.raw_html)
    content_hash = Common.hash_content(html)

    @source
    |> Common.find_article(page.slug)
    |> do_upsert(page, html, content_hash)
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
         {:ok, raw_key} <- Storage.put_raw(@source, page.slug, page.raw_html),
         attrs = build_article_attrs(page, html_key, raw_key, content_hash),
         {:ok, article} <- Common.persist_article(operation, existing, attrs) do
      Cache.invalidate(@source, page.slug)
      log_operation(operation, page.title)
      {Common.operation_result(operation), article}
    else
      {:error, changeset} -> {:error, {:"#{operation}_failed", changeset}}
    end
  end

  defp build_article_attrs(page, html_key, raw_key, content_hash) do
    %{
      source: @source,
      slug: page.slug,
      title: page.title,
      extracted_text: page.content,
      rendered_html_key: html_key,
      raw_content_key: raw_key,
      upstream_url: upstream_url(page.slug),
      upstream_hash: content_hash,
      status: :synced,
      license: @license,
      metadata: %{"category" => page.category, "image_count" => length(page.images)},
      synced_at: DateTime.utc_now()
    }
  end

  defp log_operation(:insert, title),
    do: Logger.info("Created VintageMachinery article: #{title}")

  defp log_operation(:update, title),
    do: Logger.info("Updated VintageMachinery article: #{title}")

  @unwanted_selectors ~w(nav header footer .navigation .sidebar #menu script style noscript)

  defp clean_html(html) do
    Common.clean_html(html, fn doc ->
      doc
      |> Common.filter_out_all(@unwanted_selectors)
      |> rewrite_links()
    end)
  end

  defp rewrite_links(doc) do
    Floki.traverse_and_update(doc, fn
      {"a", attrs, children} ->
        new_attrs = rewrite_href(attrs)
        {"a", new_attrs, children}

      {"img", attrs, children} ->
        new_attrs = rewrite_src(attrs)
        {"img", new_attrs, children}

      other ->
        other
    end)
  end

  defp rewrite_href(attrs) do
    Enum.map(attrs, fn
      {"href", href} when is_binary(href) ->
        new_href = normalize_link(href)
        {"href", new_href}

      other ->
        other
    end)
  end

  defp rewrite_src(attrs) do
    Enum.map(attrs, fn
      {"src", src} when is_binary(src) ->
        new_src = normalize_image_link(src)
        {"src", new_src}

      other ->
        other
    end)
  end

  defp normalize_link("http" <> _ = href), do: href
  defp normalize_link("#" <> _ = href), do: href

  defp normalize_link("/" <> _ = href) do
    slug = href |> String.trim_leading("/") |> String.replace("/", "__")
    "/machines/#{slug}"
  end

  defp normalize_link(href), do: href

  defp normalize_image_link("http" <> _ = src), do: src
  defp normalize_image_link("data:" <> _ = src), do: src
  defp normalize_image_link("/" <> _ = src), do: "https://vintagemachinery.org#{src}"
  defp normalize_image_link(src), do: "https://vintagemachinery.org/#{src}"

  defp upstream_url(slug) do
    path = String.replace(slug, "__", "/")
    @upstream_base <> path
  end

  defp default_since do
    # Default to 30 days ago (site updates infrequently)
    DateTime.utc_now() |> DateTime.add(-30 * 24 * 3600, :second)
  end
end
