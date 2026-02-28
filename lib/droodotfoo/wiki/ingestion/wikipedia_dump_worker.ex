defmodule Droodotfoo.Wiki.Ingestion.WikipediaDumpWorker do
  @moduledoc """
  Oban worker for processing Wikipedia database dump.

  Streams the ~24GB compressed dump file and processes articles.
  Supports category filtering to import only specific topics.

  ## Manual Invocation

      # Download dump first
      Droodotfoo.Wiki.Ingestion.WikipediaDumpClient.download_dump()

      # Process all articles (millions - will take days)
      %{} |> Droodotfoo.Wiki.Ingestion.WikipediaDumpWorker.new() |> Oban.insert()

      # Process with category filter
      %{categories: ["Mathematics", "Physics"]}
      |> Droodotfoo.Wiki.Ingestion.WikipediaDumpWorker.new()
      |> Oban.insert()

      # Resume from offset
      %{offset: 1_000_000, limit: 100_000}
      |> Droodotfoo.Wiki.Ingestion.WikipediaDumpWorker.new()
      |> Oban.insert()

  ## Category Filtering

  When categories are specified, only articles in those categories
  (or subcategories) are imported. This dramatically reduces the
  import size for topic-focused wikis.

  Recommended category sets:
  - Math/Science: ["Mathematics", "Physics", "Computer science"]
  - Gaming: ["Video games", "Board games"]
  - History: ["History", "Ancient history"]

  """

  use Oban.Worker,
    queue: :ingestion,
    max_attempts: 1,
    unique: [period: :infinity, states: [:available, :scheduled, :executing]]

  require Logger

  alias Droodotfoo.Wiki.Content.Article
  alias Droodotfoo.Wiki.Ingestion.{Common, SyncRun, WikipediaDumpClient}
  alias Droodotfoo.Wiki.{Cache, Storage}

  @batch_size 100
  @progress_interval 1000
  @source :wikipedia
  @license "CC BY-SA 4.0"
  @upstream_base "https://en.wikipedia.org/wiki/"

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    categories = Map.get(args, "categories", [])
    offset = Map.get(args, "offset", 0)
    limit = Map.get(args, "limit")
    dump_path = Map.get(args, "dump_path") || default_dump_path()

    # Verify dump exists
    case WikipediaDumpClient.dump_info(dump_path) do
      {:ok, info} ->
        Logger.info("Wikipedia dump found: #{info.size_human}")
        run_import(dump_path, categories, offset, limit)

      {:error, :not_found} ->
        Logger.error("Wikipedia dump not found at #{dump_path}")
        Logger.error("Download first: WikipediaDumpClient.download_dump()")
        {:error, :dump_not_found}
    end
  end

  defp run_import(dump_path, categories, offset, limit) do
    run = SyncRun.start!(@source, "dump_import")
    category_set = MapSet.new(categories)

    Logger.info(
      "Wikipedia dump import starting" <>
        if(categories != [], do: " (filtering: #{Enum.join(categories, ", ")})", else: "") <>
        if(offset > 0, do: " (offset: #{offset})", else: "")
    )

    result =
      dump_path
      |> WikipediaDumpClient.stream_articles()
      |> maybe_offset(offset)
      |> maybe_limit(limit)
      |> maybe_filter_categories(category_set)
      |> Stream.chunk_every(@batch_size)
      |> Stream.with_index(1)
      |> Enum.reduce_while({:ok, initial_stats()}, fn {batch, batch_num}, {:ok, acc} ->
        case process_batch(batch, batch_num, acc, run, offset) do
          {:ok, new_acc} -> {:cont, {:ok, new_acc}}
          {:error, _} = error -> {:halt, error}
        end
      end)

    case result do
      {:ok, stats} ->
        SyncRun.complete!(run, {:ok, stats})
        log_final_stats(stats)
        :ok

      {:error, reason} ->
        SyncRun.complete!(run, {:error, inspect(reason)})
        {:error, reason}
    end
  end

  defp maybe_offset(stream, 0), do: stream
  defp maybe_offset(stream, offset), do: Stream.drop(stream, offset)

  defp maybe_limit(stream, nil), do: stream
  defp maybe_limit(stream, limit), do: Stream.take(stream, limit)

  defp maybe_filter_categories(stream, categories) when map_size(categories) == 0 do
    stream
  end

  defp maybe_filter_categories(stream, categories) do
    Stream.filter(stream, fn article ->
      article.categories
      |> Enum.any?(fn cat -> MapSet.member?(categories, cat) end)
    end)
  end

  defp process_batch(articles, batch_num, acc, run, offset) do
    results =
      articles
      |> Task.async_stream(&process_article/1, max_concurrency: 4, timeout: 30_000)
      |> Enum.map(fn
        {:ok, result} -> result
        {:exit, reason} -> {:error, reason}
      end)

    batch_stats = aggregate_batch(results)
    new_acc = merge_stats(acc, batch_stats)

    total_processed = new_acc.created + new_acc.updated + new_acc.unchanged + new_acc.errors

    if rem(total_processed, @progress_interval) < @batch_size do
      log_progress(batch_num, new_acc, offset)
      update_run_progress(run, new_acc)
    end

    {:ok, new_acc}
  rescue
    e ->
      Logger.error("Batch #{batch_num} failed: #{inspect(e)}")
      {:error, {:batch_failed, batch_num, e}}
  end

  defp process_article(article) do
    slug = normalize_slug(article.title)

    # Convert wikitext to HTML (simplified - Wikipedia wikitext is complex)
    html = wikitext_to_html(article.text, article.title)
    content_hash = Common.hash_content(html)

    @source
    |> Common.find_article(slug)
    |> do_upsert(article, slug, html, content_hash)
  end

  defp do_upsert(nil, article, slug, html, content_hash) do
    save_article(:insert, nil, article, slug, html, content_hash)
  end

  defp do_upsert(%Article{upstream_hash: hash} = existing, _article, _slug, _html, hash) do
    {:unchanged, existing}
  end

  defp do_upsert(existing, article, slug, html, content_hash) do
    save_article(:update, existing, article, slug, html, content_hash)
  end

  defp save_article(operation, existing, article, slug, html, content_hash) do
    with {:ok, html_key} <- Storage.put_html(@source, slug, html),
         {:ok, raw_key} <- Storage.put_raw(@source, slug, article.text),
         attrs = build_article_attrs(article, slug, html_key, raw_key, content_hash),
         {:ok, saved} <- Common.persist_article(operation, existing, attrs) do
      Cache.invalidate(@source, slug)
      {Common.operation_result(operation), saved}
    else
      {:error, reason} -> {:error, {:"#{operation}_failed", reason}}
    end
  end

  defp build_article_attrs(article, slug, html_key, raw_key, content_hash) do
    %{
      source: @source,
      slug: slug,
      title: article.title,
      extracted_text: extract_summary(article.text),
      rendered_html_key: html_key,
      raw_content_key: raw_key,
      upstream_url: Common.upstream_url(@upstream_base, slug),
      upstream_hash: content_hash,
      status: :synced,
      license: @license,
      metadata: %{
        "categories" => article.categories,
        "wikipedia_id" => article.id
      },
      synced_at: DateTime.utc_now()
    }
  end

  defp normalize_slug(title) do
    title
    |> String.replace(" ", "_")
    |> URI.encode()
  end

  # Extract first paragraph as summary
  defp extract_summary(wikitext) when is_binary(wikitext) do
    wikitext
    |> String.split("\n\n", parts: 2)
    |> List.first()
    |> String.slice(0, 500)
    |> strip_wikitext()
  end

  defp extract_summary(_), do: ""

  # Strip common wikitext markup for plain text
  defp strip_wikitext(text) do
    text
    # [[link|text]] -> text
    |> String.replace(~r/\[\[([^\]|]+\|)?([^\]]+)\]\]/, "\\2")
    # '''bold''' -> bold
    |> String.replace(~r/'''?([^']+)'''?/, "\\1")
    # {{templates}}
    |> String.replace(~r/\{\{[^}]+\}\}/, "")
    # <ref>...</ref>
    |> String.replace(~r/<ref[^>]*>.*?<\/ref>/s, "")
    # other HTML tags
    |> String.replace(~r/<[^>]+>/, "")
    |> String.trim()
  end

  # Basic wikitext to HTML conversion
  # For full fidelity, would need Parsoid or similar
  defp wikitext_to_html(nil, _title), do: "<p>No content</p>"

  defp wikitext_to_html(wikitext, title) do
    html_body =
      wikitext
      |> convert_headings()
      |> convert_links()
      |> convert_formatting()
      |> convert_paragraphs()

    """
    <article class="wikipedia-article">
      <h1>#{escape_html(title)}</h1>
      #{html_body}
    </article>
    """
  end

  defp convert_headings(text) do
    text
    |> String.replace(~r/^======\s*(.+?)\s*======$/m, "<h6>\\1</h6>")
    |> String.replace(~r/^=====\s*(.+?)\s*=====$/m, "<h5>\\1</h5>")
    |> String.replace(~r/^====\s*(.+?)\s*====$/m, "<h4>\\1</h4>")
    |> String.replace(~r/^===\s*(.+?)\s*===$/m, "<h3>\\1</h3>")
    |> String.replace(~r/^==\s*(.+?)\s*==$/m, "<h2>\\1</h2>")
  end

  defp convert_links(text) do
    # Internal wiki links: [[Page|text]]
    text =
      Regex.replace(~r/\[\[([^\]|]+)\|([^\]]+)\]\]/, text, fn _, page, label ->
        slug = normalize_slug(page)
        "<a href=\"/wikipedia/#{slug}\">#{escape_html(label)}</a>"
      end)

    # Internal wiki links: [[Page]]
    text =
      Regex.replace(~r/\[\[([^\]]+)\]\]/, text, fn _, page ->
        slug = normalize_slug(page)
        "<a href=\"/wikipedia/#{slug}\">#{escape_html(page)}</a>"
      end)

    # External links: [http://example.com text]
    String.replace(
      text,
      ~r/\[([^\s\]]+)\s+([^\]]+)\]/,
      "<a href=\"\\1\" rel=\"external\">\\2</a>"
    )
  end

  defp convert_formatting(text) do
    text
    |> String.replace(~r/'''([^']+)'''/, "<strong>\\1</strong>")
    |> String.replace(~r/''([^']+)''/, "<em>\\1</em>")
    # Remove templates and refs for now (complex to parse)
    |> String.replace(~r/\{\{[^}]+\}\}/s, "")
    |> String.replace(~r/<ref[^>]*>.*?<\/ref>/s, "")
    |> String.replace(~r/<ref[^>]*\/>/s, "")
  end

  defp convert_paragraphs(text) do
    text
    |> String.split(~r/\n\n+/)
    |> Enum.map(fn para ->
      para = String.trim(para)

      cond do
        para == "" -> ""
        String.starts_with?(para, "<h") -> para
        true -> "<p>#{para}</p>"
      end
    end)
    |> Enum.join("\n")
  end

  defp initial_stats do
    %{created: 0, updated: 0, unchanged: 0, errors: 0, last_title: nil}
  end

  defp aggregate_batch(results) do
    Enum.reduce(results, initial_stats(), fn result, acc ->
      case result do
        {:created, article} -> %{acc | created: acc.created + 1, last_title: article.title}
        {:updated, article} -> %{acc | updated: acc.updated + 1, last_title: article.title}
        {:unchanged, article} -> %{acc | unchanged: acc.unchanged + 1, last_title: article.title}
        {:error, _} -> %{acc | errors: acc.errors + 1}
      end
    end)
  end

  defp merge_stats(acc, batch) do
    %{
      created: acc.created + batch.created,
      updated: acc.updated + batch.updated,
      unchanged: acc.unchanged + batch.unchanged,
      errors: acc.errors + batch.errors,
      last_title: batch.last_title || acc.last_title
    }
  end

  defp log_progress(batch_num, stats, offset) do
    total = stats.created + stats.updated + stats.unchanged + stats.errors
    absolute = offset + total

    Logger.info(
      "Wikipedia dump progress: batch #{batch_num}, #{total} articles processed " <>
        "(absolute: #{absolute}, #{stats.created} new, #{stats.updated} updated) " <>
        "- last: #{stats.last_title}"
    )
  end

  defp update_run_progress(run, stats) do
    SyncRun.update_progress!(run, %{
      pages_processed: stats.created + stats.updated + stats.unchanged + stats.errors,
      pages_created: stats.created,
      pages_updated: stats.updated,
      pages_unchanged: stats.unchanged,
      last_title: stats.last_title
    })
  end

  defp log_final_stats(stats) do
    total = stats.created + stats.updated + stats.unchanged + stats.errors

    Logger.info("""
    Wikipedia dump import complete:
      Total articles: #{total}
      Created: #{stats.created}
      Updated: #{stats.updated}
      Unchanged: #{stats.unchanged}
      Errors: #{stats.errors}
    """)
  end

  defp default_dump_path do
    Path.join(:code.priv_dir(:droodotfoo), "wikipedia-dump/enwiki-latest-pages-articles.xml.bz2")
  end

  defp escape_html(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end

  defp escape_html(nil), do: ""
end
