defmodule Droodotfoo.Wiki.Ingestion.VintageMachineryWaybackPipeline do
  @moduledoc """
  Pipeline for ingesting VintageMachinery.org content from the Wayback Machine.

  Used when the live site is unavailable (403 errors).

  ## Manual Invocation

      # Sync all archived pages
      VintageMachineryWaybackPipeline.sync_all()

      # Sync specific path prefix
      VintageMachineryWaybackPipeline.sync_prefix("pubs/")

      # Process single URL
      VintageMachineryWaybackPipeline.process_url("http://vintagemachinery.org/pubs/123.html")

  """

  require Logger

  alias Droodotfoo.Wiki.Content.Article
  alias Droodotfoo.Wiki.Ingestion.{Common, WaybackClient}
  alias Droodotfoo.Wiki.{Cache, Storage}

  @source :vintage_machinery
  @license "Used with permission (archived)"
  # Use the wiki subdomain which has actual content archived
  @domain "wiki.vintagemachinery.org"
  # Empty prefix to get all pages, filter by .ashx extension
  @prefixes [""]

  @type result :: {:created | :updated | :unchanged, Article.t()} | {:error, term()}

  @doc """
  Sync all archived VintageMachinery pages.
  """
  @spec sync_all(keyword()) ::
          {:ok,
           %{created: integer(), updated: integer(), unchanged: integer(), errors: integer()}}
          | {:error, term()}
  def sync_all(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50_000)
    progress_fn = Keyword.get(opts, :progress)

    Logger.info("Starting VintageMachinery Wayback sync")

    results =
      @prefixes
      |> Enum.flat_map(fn prefix ->
        case WaybackClient.list_archived_urls(@domain, prefix: prefix, limit: limit) do
          {:ok, urls} ->
            Logger.info("Found #{length(urls)} archived URLs for #{prefix}")
            urls

          {:error, reason} ->
            Logger.error("Failed to list #{prefix}: #{inspect(reason)}")
            []
        end
      end)
      |> Enum.take(limit)
      |> process_urls_with_progress(progress_fn)

    {:ok, Common.aggregate_stats(results)}
  end

  @doc """
  Sync a specific path prefix.
  """
  @spec sync_prefix(String.t(), keyword()) ::
          {:ok,
           %{created: integer(), updated: integer(), unchanged: integer(), errors: integer()}}
          | {:error, term()}
  def sync_prefix(prefix, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10_000)

    case WaybackClient.list_archived_urls(@domain, prefix: prefix, limit: limit) do
      {:ok, urls} ->
        Logger.info("Processing #{length(urls)} archived URLs for #{prefix}")
        results = process_urls(urls)
        {:ok, Common.aggregate_stats(results)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Process a single archived URL.
  """
  @spec process_url(String.t()) :: result()
  def process_url(url) do
    with {:ok, meta} <- WaybackClient.fetch_snapshot_with_meta(url),
         {:ok, parsed} <- parse_page(meta),
         {status, article} when status in [:created, :updated, :unchanged] <-
           upsert_article(parsed) do
      {status, article}
    else
      {:error, :not_found} ->
        Logger.debug("No archive found for: #{url}")
        {:error, :not_found}

      {:error, reason} = error ->
        Logger.error("Failed to process #{url}: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Process a URL from archived metadata (already have timestamp).
  """
  @spec process_archived(map()) :: result()
  def process_archived(%{url: url, timestamp: timestamp}) do
    with {:ok, html} <- WaybackClient.fetch_snapshot(url, timestamp),
         {:ok, parsed} <- parse_page(%{html: html, original_url: url, timestamp: timestamp}),
         {status, article} when status in [:created, :updated, :unchanged] <-
           upsert_article(parsed) do
      {status, article}
    else
      {:error, :not_found} ->
        {:error, :not_found}

      {:error, reason} = error ->
        Logger.error("Failed to process archived #{url}: #{inspect(reason)}")
        error
    end
  end

  # Private functions

  defp process_urls(urls) do
    urls
    |> Enum.map(fn %{url: url} = meta ->
      result = process_archived(meta)
      # Rate limit
      Process.sleep(500)
      {url, result}
    end)
    |> Map.new()
  end

  defp process_urls_with_progress(urls, nil), do: process_urls(urls)

  defp process_urls_with_progress(urls, progress_fn) when is_function(progress_fn) do
    urls
    |> Enum.with_index(1)
    |> Enum.map(fn {%{url: url} = meta, idx} ->
      if rem(idx, 50) == 0, do: progress_fn.(idx, length(urls))
      {url, process_archived(meta)}
    end)
    |> Map.new()
  end

  defp parse_page(%{html: html, original_url: url, timestamp: timestamp}) do
    {:ok, doc} = Floki.parse_document(html)

    title = extract_title(doc, url)
    content = extract_content(doc)
    slug = url_to_slug(url)

    {:ok,
     %{
       slug: slug,
       title: title,
       content: content,
       raw_html: html,
       original_url: url,
       archived_at: parse_timestamp(timestamp),
       category: extract_category(url)
     }}
  rescue
    e ->
      Logger.error("Parse error for #{url}: #{inspect(e)}")
      {:error, {:parse_error, e}}
  end

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
      upstream_url: page.original_url,
      upstream_hash: content_hash,
      status: :synced,
      license: @license,
      metadata: %{
        "category" => page.category,
        "archived_at" => page.archived_at && DateTime.to_iso8601(page.archived_at),
        "source" => "wayback_machine"
      },
      synced_at: DateTime.utc_now()
    }
  end

  defp log_operation(:insert, title),
    do: Logger.info("Created VintageMachinery article (Wayback): #{title}")

  defp log_operation(:update, title),
    do: Logger.info("Updated VintageMachinery article (Wayback): #{title}")

  defp extract_title(doc, fallback_url) do
    case Floki.find(doc, "title") do
      [{_, _, [title]}] -> String.trim(title)
      _ -> url_to_title(fallback_url)
    end
  end

  defp extract_content(doc) do
    selectors = ["#content", "#main-content", ".content", "main", "article", "body"]

    Enum.find_value(selectors, "", fn selector ->
      case Floki.find(doc, selector) do
        [element | _] ->
          element
          |> Floki.text(sep: " ")
          |> String.replace(~r/\s+/, " ")
          |> String.trim()

        [] ->
          nil
      end
    end)
  end

  defp extract_category(url) do
    cond do
      String.contains?(url, "/pubs/") -> "publications"
      String.contains?(url, "/mfgindex/") -> "manufacturers"
      true -> nil
    end
  end

  @unwanted_selectors ~w(nav header footer .navigation .sidebar #menu script style noscript)

  defp clean_html(html) do
    Common.clean_html(html, fn doc ->
      doc
      |> Common.filter_out_all(@unwanted_selectors)
      |> rewrite_wayback_links()
    end)
  end

  defp rewrite_wayback_links(doc) do
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
        {"href", clean_wayback_url(href)}

      other ->
        other
    end)
  end

  defp rewrite_src(attrs) do
    Enum.map(attrs, fn
      {"src", src} when is_binary(src) ->
        {"src", clean_wayback_url(src)}

      other ->
        other
    end)
  end

  defp clean_wayback_url(url) do
    # Remove Wayback Machine prefix if present
    case Regex.run(~r{web\.archive\.org/web/\d+(?:id_)?/(.+)}, url) do
      [_, original] -> original
      _ -> url
    end
  end

  defp url_to_slug(url) do
    url
    |> URI.parse()
    |> Map.get(:path, "")
    |> String.trim_leading("/")
    |> String.replace(~r/\.html?$/i, "")
    |> String.replace("/", "__")
    |> String.downcase()
    |> then(fn slug ->
      if slug == "", do: "index", else: slug
    end)
  end

  defp url_to_title(url) do
    url
    |> url_to_slug()
    |> String.replace("__", " - ")
    |> String.replace(~r/[-_]/, " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp parse_timestamp(ts) when is_binary(ts) and byte_size(ts) >= 8 do
    # Wayback timestamps are YYYYMMDDHHMMSS
    with {year, _} <- Integer.parse(String.slice(ts, 0, 4)),
         {month, _} <- Integer.parse(String.slice(ts, 4, 2)),
         {day, _} <- Integer.parse(String.slice(ts, 6, 2)) do
      case Date.new(year, month, day) do
        {:ok, date} -> DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
        _ -> nil
      end
    else
      _ -> nil
    end
  end

  defp parse_timestamp(_), do: nil
end
