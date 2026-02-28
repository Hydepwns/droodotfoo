defmodule Mix.Tasks.Wiki do
  @shortdoc "Wiki management commands"
  @moduledoc """
  Wiki management tasks.

  ## Commands

      mix wiki.status          # Show wiki status (article counts, storage)
      mix wiki.sync SOURCE     # Trigger sync for a source (osrs, nlab, wikipedia, machines)
      mix wiki.sync --full     # Full sync all sources
      mix wiki.import URL      # Import a Wikipedia article by URL or title

  ## Examples

      # Check status
      mix wiki.status

      # Initial setup - full sync of all sources
      mix wiki.sync --full

      # Sync specific source
      mix wiki.sync osrs
      mix wiki.sync nlab

      # Import Wikipedia article
      mix wiki.import "Riemann hypothesis"
      mix wiki.import "https://en.wikipedia.org/wiki/Category_theory"

  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    case args do
      ["status" | _] -> status()
      ["sync", "--full" | _] -> full_sync()
      ["sync", source | _] -> sync_source(source)
      ["dump", "osrs" | rest] -> dump_osrs(rest)
      ["dump", "wikipedia" | rest] -> dump_wikipedia(rest)
      ["wayback" | rest] -> sync_wayback(rest)
      ["import" | rest] -> import_wikipedia(Enum.join(rest, " "))
      _ -> usage()
    end
  end

  defp usage do
    Mix.shell().info("""
    Wiki management commands:

      mix wiki status          # Show wiki status
      mix wiki sync SOURCE     # Sync source (osrs, nlab, wikipedia, machines)
      mix wiki sync --full     # Full sync all sources
      mix wiki dump osrs       # Full OSRS Wiki dump (~40k pages)
      mix wiki dump osrs --resume "Title"  # Resume from title
      mix wiki dump osrs --limit 1000      # Limit pages (testing)
      mix wiki dump wikipedia --download   # Download Wikipedia dump (~24GB)
      mix wiki dump wikipedia              # Process downloaded dump
      mix wiki dump wikipedia --categories "Mathematics,Physics"  # Filter by category
      mix wiki dump wikipedia --offset 1000000 --limit 100000     # Resume
      mix wiki wayback         # Sync VintageMachinery from Wayback Machine
      mix wiki wayback --limit 100         # Limit pages (testing)
      mix wiki import TITLE    # Import Wikipedia article

    Examples:
      mix wiki sync osrs
      mix wiki dump osrs
      mix wiki dump wikipedia --download
      mix wiki dump wikipedia --categories "Mathematics,Physics,Computer science"
      mix wiki import "Category theory"
    """)
  end

  defp status do
    Mix.Task.run("app.start")

    alias Droodotfoo.Wiki.Content

    Mix.shell().info("\n=== Wiki Status ===\n")

    # Article counts by source
    counts = Content.count_by_source()

    if map_size(counts) == 0 do
      Mix.shell().info("No articles synced yet. Run: mix wiki.sync --full\n")
    else
      Mix.shell().info("Articles by source:")

      Enum.each(counts, fn {source, count} ->
        Mix.shell().info("  #{format_source(source)}: #{count}")
      end)

      total = counts |> Map.values() |> Enum.sum()
      Mix.shell().info("  Total: #{total}\n")
    end

    # Check MinIO connectivity
    check_storage()

    # Check Ollama
    check_ollama()
  end

  defp check_storage do
    Mix.shell().info("Storage (MinIO):")

    case ExAws.S3.list_buckets() |> ExAws.request() do
      {:ok, %{body: %{buckets: buckets}}} ->
        bucket_names = Enum.map(buckets, & &1.name)

        Mix.shell().info(
          "  Connected - #{length(buckets)} buckets: #{Enum.join(bucket_names, ", ")}"
        )

      {:error, reason} ->
        Mix.shell().error("  Not connected: #{inspect(reason)}")
        Mix.shell().info("  Run MinIO locally or connect via Tailscale to mini-axol")
    end
  end

  defp check_ollama do
    ollama_url = Application.get_env(:droodotfoo, Droodotfoo.Wiki.Ollama)[:base_url]
    Mix.shell().info("\nOllama (embeddings):")

    case Req.get("#{ollama_url}/api/tags", receive_timeout: 5_000) do
      {:ok, %{status: 200}} ->
        Mix.shell().info("  Connected at #{ollama_url}")

      _ ->
        Mix.shell().info("  Not available at #{ollama_url}")
        Mix.shell().info("  Semantic search will be disabled")
    end
  end

  defp sync_source(source) do
    Mix.Task.run("app.start")

    source_atom =
      case source do
        "osrs" -> :osrs
        "nlab" -> :nlab
        "wikipedia" -> :wikipedia
        "machines" -> :vintage_machinery
        "vintage_machinery" -> :vintage_machinery
        _ -> nil
      end

    if source_atom do
      Mix.shell().info("Queuing full sync for #{format_source(source_atom)}...")
      queue_sync(source_atom, full: true)
      Mix.shell().info("Sync queued. Check progress at http://localhost:4000/admin/sync")
    else
      Mix.shell().error("Unknown source: #{source}")
      Mix.shell().info("Valid sources: osrs, nlab, wikipedia, machines")
    end
  end

  defp full_sync do
    Mix.Task.run("app.start")

    Mix.shell().info("Queuing full sync for all sources...")

    sources = [:osrs, :nlab, :vintage_machinery]

    Enum.each(sources, fn source ->
      queue_sync(source, full: true)
      Mix.shell().info("  Queued: #{format_source(source)}")
    end)

    Mix.shell().info("""

    All syncs queued. This may take a while depending on source size:
    - OSRS Wiki: ~10-30 minutes (thousands of pages)
    - nLab: ~5-10 minutes (git clone + process)
    - Vintage Machinery: ~2-5 minutes

    Check progress at http://localhost:4000/admin/sync
    or watch logs: mix phx.server
    """)
  end

  defp import_wikipedia(input) do
    Mix.Task.run("app.start")

    # Extract slug from URL or use as-is
    slug =
      input
      |> String.trim()
      |> extract_wikipedia_slug()

    if slug == "" do
      Mix.shell().error("Please provide a Wikipedia article title or URL")
    else
      Mix.shell().info("Importing Wikipedia article: #{slug}")

      %{"slug" => slug}
      |> Droodotfoo.Wiki.Ingestion.WikipediaSyncWorker.new()
      |> Oban.insert()

      Mix.shell().info("Import queued. Check http://localhost:4000/wikipedia/#{slug}")
    end
  end

  defp extract_wikipedia_slug(input) do
    cond do
      String.contains?(input, "wikipedia.org/wiki/") ->
        input
        |> String.split("/wiki/")
        |> List.last()
        |> URI.decode()
        |> String.replace(" ", "_")

      true ->
        String.replace(input, " ", "_")
    end
  end

  defp queue_sync(:osrs, opts) do
    args = if opts[:full], do: %{full_sync: true}, else: %{}
    args |> Droodotfoo.Wiki.Ingestion.OSRSSyncWorker.new() |> Oban.insert()
  end

  defp queue_sync(:nlab, opts) do
    args = if opts[:full], do: %{full_sync: true}, else: %{}
    args |> Droodotfoo.Wiki.Ingestion.NLabSyncWorker.new() |> Oban.insert()
  end

  defp queue_sync(:vintage_machinery, opts) do
    args = if opts[:full], do: %{"strategy" => "full"}, else: %{}
    args |> Droodotfoo.Wiki.Ingestion.VintageMachinerySyncWorker.new() |> Oban.insert()
  end

  defp queue_sync(:wikipedia, _opts) do
    %{"strategy" => "refresh"}
    |> Droodotfoo.Wiki.Ingestion.WikipediaSyncWorker.new()
    |> Oban.insert()
  end

  defp sync_wayback(args) do
    Mix.Task.run("app.start")

    {opts, _} = OptionParser.parse!(args, strict: [limit: :integer, prefix: :string])
    limit = opts[:limit]
    prefix = opts[:prefix]

    args =
      %{}
      |> maybe_put("limit", limit)
      |> maybe_put("prefix", prefix)

    Mix.shell().info("Starting VintageMachinery sync from Wayback Machine...")

    if limit do
      Mix.shell().info("  Limit: #{limit} pages")
    end

    if prefix do
      Mix.shell().info("  Prefix: #{prefix}")
    end

    args
    |> Droodotfoo.Wiki.Ingestion.VintageMachineryWaybackWorker.new()
    |> Oban.insert()

    Mix.shell().info("""

    Wayback sync queued. This will fetch archived pages from web.archive.org.
    Rate-limited to 1 request/second to respect Wayback Machine.

    Monitor progress in Phoenix server logs or:
      SELECT * FROM sync_runs WHERE source = 'vintage_machinery' ORDER BY started_at DESC LIMIT 1;
    """)
  end

  defp dump_osrs(args) do
    Mix.Task.run("app.start")

    {opts, _} = OptionParser.parse!(args, strict: [resume: :string, limit: :integer])
    resume_from = opts[:resume]
    limit = opts[:limit]

    args =
      %{}
      |> maybe_put("resume_from", resume_from)
      |> maybe_put("limit", limit)

    Mix.shell().info("Starting OSRS full dump...")

    if resume_from do
      Mix.shell().info("  Resuming from: #{resume_from}")
    end

    if limit do
      Mix.shell().info("  Limit: #{limit} pages")
    end

    args
    |> Droodotfoo.Wiki.Ingestion.OSRSFullDumpWorker.new()
    |> Oban.insert()

    Mix.shell().info("""

    Full dump queued. This will process ~40,000 pages.
    Estimated time: 4-8 hours (rate-limited to respect the wiki).

    Monitor progress:
      - Logs: watch the Phoenix server output
      - Database: SELECT * FROM sync_runs WHERE source = 'osrs' ORDER BY started_at DESC LIMIT 1;
      - Admin UI: http://localhost:4000/admin/sync

    If interrupted, resume with:
      mix wiki dump osrs --resume "Last_Title_Processed"
    """)
  end

  defp dump_wikipedia(args) do
    {opts, _} =
      OptionParser.parse!(args,
        strict: [download: :boolean, categories: :string, offset: :integer, limit: :integer]
      )

    if opts[:download] do
      download_wikipedia_dump()
    else
      process_wikipedia_dump(opts)
    end
  end

  defp download_wikipedia_dump do
    Mix.shell().info("""
    Downloading Wikipedia dump (~24GB compressed)...

    This will take a while depending on your connection.
    Download is resumable if interrupted.
    """)

    alias Droodotfoo.Wiki.Ingestion.WikipediaDumpClient

    case WikipediaDumpClient.download_dump() do
      {:ok, path} ->
        Mix.shell().info("""

        Download complete: #{path}

        Next steps:
          mix wiki dump wikipedia                    # Process all articles
          mix wiki dump wikipedia --categories "Mathematics,Physics"  # Filter
        """)

      {:error, reason} ->
        Mix.shell().error("Download failed: #{inspect(reason)}")
    end
  end

  defp process_wikipedia_dump(opts) do
    Mix.Task.run("app.start")

    categories =
      case opts[:categories] do
        nil -> []
        str -> String.split(str, ",") |> Enum.map(&String.trim/1)
      end

    offset = opts[:offset] || 0
    limit = opts[:limit]

    args =
      %{}
      |> maybe_put("categories", if(categories == [], do: nil, else: categories))
      |> maybe_put("offset", if(offset == 0, do: nil, else: offset))
      |> maybe_put("limit", limit)

    Mix.shell().info("Starting Wikipedia dump import...")

    if categories != [] do
      Mix.shell().info("  Categories: #{Enum.join(categories, ", ")}")
    end

    if offset > 0 do
      Mix.shell().info("  Offset: #{offset}")
    end

    if limit do
      Mix.shell().info("  Limit: #{limit}")
    end

    args
    |> Droodotfoo.Wiki.Ingestion.WikipediaDumpWorker.new()
    |> Oban.insert()

    Mix.shell().info("""

    Import queued. Processing ~7 million articles.

    For filtered imports (recommended):
      mix wiki dump wikipedia --categories "Mathematics,Physics,Computer science"

    Monitor progress:
      - Logs: watch the Phoenix server output
      - Database: SELECT * FROM sync_runs WHERE source = 'wikipedia' ORDER BY started_at DESC LIMIT 1;

    If interrupted, resume with:
      mix wiki dump wikipedia --offset LAST_PROCESSED_COUNT
    """)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp format_source(:osrs), do: "OSRS Wiki"
  defp format_source(:nlab), do: "nLab"
  defp format_source(:wikipedia), do: "Wikipedia"
  defp format_source(:vintage_machinery), do: "Vintage Machinery"
  defp format_source(:wikiart), do: "WikiArt"
  defp format_source(s), do: to_string(s)
end
