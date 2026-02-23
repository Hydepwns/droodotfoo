defmodule Wiki.Ingestion.VintageMachineryPipeline do
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

  alias Wiki.Content.Article
  alias Wiki.Ingestion.VintageMachineryClient
  alias Wiki.{Cache, Repo, Storage}

  import Ecto.Query

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
         {:ok, article} <- upsert_article(page) do
      article
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
    slugs
    |> Task.async_stream(&process_page/1, max_concurrency: 4, timeout: 60_000)
    |> Enum.zip(slugs)
    |> Enum.map(fn
      {{:ok, result}, slug} -> {slug, result}
      {{:exit, reason}, slug} -> {slug, {:error, reason}}
    end)
    |> Map.new()
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
      {:ok, aggregate_stats(results)}
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
        {:ok, aggregate_stats(results)}
      end
    end
  end

  # Private functions

  defp upsert_article(page) do
    html = clean_html(page.raw_html)
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
         {:ok, raw_key} <- Storage.put_raw(@source, page.slug, page.raw_html),
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

  defp persist_article(:insert, _existing, attrs) do
    Repo.insert(Article.changeset(attrs))
  end

  defp persist_article(:update, existing, attrs) do
    Repo.update(Article.changeset(existing, attrs))
  end

  defp operation_result(:insert), do: :created
  defp operation_result(:update), do: :updated

  defp log_operation(:insert, title),
    do: Logger.info("Created VintageMachinery article: #{title}")

  defp log_operation(:update, title),
    do: Logger.info("Updated VintageMachinery article: #{title}")

  defp clean_html(html) do
    # Parse and clean the HTML
    case Floki.parse_document(html) do
      {:ok, doc} ->
        doc
        |> remove_navigation()
        |> remove_scripts()
        |> rewrite_links()
        |> Floki.raw_html()

      _ ->
        html
    end
  end

  defp remove_navigation(doc) do
    doc
    |> Floki.filter_out("nav")
    |> Floki.filter_out("header")
    |> Floki.filter_out("footer")
    |> Floki.filter_out(".navigation")
    |> Floki.filter_out(".sidebar")
    |> Floki.filter_out("#menu")
  end

  defp remove_scripts(doc) do
    doc
    |> Floki.filter_out("script")
    |> Floki.filter_out("style")
    |> Floki.filter_out("noscript")
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

  defp hash_content(html) do
    :crypto.hash(:sha256, html) |> Base.encode16(case: :lower)
  end

  defp upstream_url(slug) do
    path = String.replace(slug, "__", "/")
    @upstream_base <> path
  end

  defp default_since do
    # Default to 30 days ago (site updates infrequently)
    DateTime.utc_now() |> DateTime.add(-30 * 24 * 3600, :second)
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
