defmodule Droodotfoo.Wiki.Ingestion.WikipediaDumpClient do
  @moduledoc """
  Client for downloading and streaming Wikipedia database dumps.

  Downloads from dumps.wikimedia.org and streams decompressed XML
  for memory-efficient processing of multi-GB dump files.

  ## Usage

      # Download latest dump to local storage
      {:ok, path} = WikipediaDumpClient.download_dump()

      # Stream articles from dump file
      WikipediaDumpClient.stream_articles(path)
      |> Stream.take(100)
      |> Enum.each(&process_article/1)

  ## Dump Files

  The main article dump is `enwiki-latest-pages-articles.xml.bz2`:
  - ~24GB compressed, ~80GB uncompressed
  - Contains all current article revisions (no history)
  - Updated monthly

  """

  require Logger

  @dumps_base "https://dumps.wikimedia.org/enwiki/latest"
  @dump_file "enwiki-latest-pages-articles.xml.bz2"

  @type article :: %{
          title: String.t(),
          text: String.t(),
          id: integer(),
          ns: integer(),
          redirect: String.t() | nil,
          categories: [String.t()]
        }

  @doc """
  Get the URL for the latest Wikipedia dump.
  """
  @spec dump_url() :: String.t()
  def dump_url, do: "#{@dumps_base}/#{@dump_file}"

  @doc """
  Download the Wikipedia dump to local storage.

  Returns the path to the downloaded file.

  ## Options

    * `:dest_dir` - Directory to save dump (default: priv/wikipedia-dump)
    * `:force` - Re-download even if file exists (default: false)

  """
  @spec download_dump(keyword()) :: {:ok, String.t()} | {:error, term()}
  def download_dump(opts \\ []) do
    dest_dir = Keyword.get(opts, :dest_dir, default_dump_dir())
    force = Keyword.get(opts, :force, false)
    dest_path = Path.join(dest_dir, @dump_file)

    File.mkdir_p!(dest_dir)

    if File.exists?(dest_path) && !force do
      Logger.info("Wikipedia dump already exists: #{dest_path}")
      {:ok, dest_path}
    else
      Logger.info("Downloading Wikipedia dump to #{dest_path}...")
      Logger.info("This is ~24GB and will take a while.")

      case download_with_progress(dump_url(), dest_path) do
        :ok ->
          Logger.info("Download complete: #{dest_path}")
          {:ok, dest_path}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc """
  Stream articles from a downloaded dump file.

  Returns a stream of article maps. Only articles in namespace 0
  (main articles) are included by default.

  ## Options

    * `:namespace` - Namespace to filter (default: 0 for main articles)
    * `:skip_redirects` - Skip redirect pages (default: true)

  """
  @spec stream_articles(String.t(), keyword()) :: Enumerable.t()
  def stream_articles(dump_path, opts \\ []) do
    namespace = Keyword.get(opts, :namespace, 0)
    skip_redirects = Keyword.get(opts, :skip_redirects, true)

    dump_path
    |> stream_xml_pages()
    |> Stream.filter(fn page ->
      page.ns == namespace &&
        (!skip_redirects || is_nil(page.redirect))
    end)
    |> Stream.map(&parse_article/1)
  end

  @doc """
  Count total articles in a dump (for progress tracking).

  This streams through the entire dump, so it's slow but accurate.
  """
  @spec count_articles(String.t(), keyword()) :: integer()
  def count_articles(dump_path, opts \\ []) do
    dump_path
    |> stream_articles(opts)
    |> Enum.count()
  end

  @doc """
  Check if a dump file exists and get its info.
  """
  @spec dump_info(String.t()) :: {:ok, map()} | {:error, :not_found}
  def dump_info(dump_path) do
    case File.stat(dump_path) do
      {:ok, stat} ->
        {:ok,
         %{
           path: dump_path,
           size: stat.size,
           size_human: format_bytes(stat.size),
           modified: stat.mtime
         }}

      {:error, :enoent} ->
        {:error, :not_found}
    end
  end

  # Private functions

  defp default_dump_dir do
    Path.join(:code.priv_dir(:droodotfoo), "wikipedia-dump")
  end

  defp download_with_progress(url, dest_path) do
    # Use curl for resumable downloads with progress
    args = [
      # Follow redirects
      "-L",
      # Resume if interrupted
      "-C",
      "-",
      # Progress bar
      "-#",
      "-o",
      dest_path,
      url
    ]

    case System.cmd("curl", args, stderr_to_stdout: true, into: IO.stream(:stdio, :line)) do
      {_, 0} -> :ok
      {output, code} -> {:error, {:download_failed, code, output}}
    end
  end

  defp stream_xml_pages(dump_path) do
    Stream.resource(
      fn -> open_dump(dump_path) end,
      fn state -> read_next_page(state) end,
      fn state -> close_dump(state) end
    )
  end

  defp open_dump(path) do
    # Use bzcat for streaming decompression
    port =
      Port.open(
        {:spawn_executable, System.find_executable("bzcat")},
        [:binary, :exit_status, :use_stdio, :stream, args: [path]]
      )

    %{
      port: port,
      buffer: "",
      done: false
    }
  end

  defp read_next_page(%{done: true} = state) do
    {:halt, state}
  end

  defp read_next_page(state) do
    case extract_page(state.buffer) do
      {:ok, page_xml, rest} ->
        page = parse_page_xml(page_xml)
        {[page], %{state | buffer: rest}}

      :need_more ->
        case receive_data(state) do
          {:data, data} ->
            read_next_page(%{state | buffer: state.buffer <> data})

          :done ->
            # Process any remaining content
            case extract_page(state.buffer) do
              {:ok, page_xml, _rest} ->
                page = parse_page_xml(page_xml)
                {[page], %{state | done: true}}

              :need_more ->
                {:halt, %{state | done: true}}
            end
        end
    end
  end

  defp receive_data(%{port: port}) do
    receive do
      {^port, {:data, data}} ->
        {:data, data}

      {^port, {:exit_status, 0}} ->
        :done

      {^port, {:exit_status, _code}} ->
        :done
    after
      60_000 ->
        :done
    end
  end

  defp close_dump(%{port: port}) do
    Port.close(port)
  rescue
    _ -> :ok
  end

  defp extract_page(buffer) do
    case :binary.match(buffer, "<page>") do
      :nomatch ->
        :need_more

      {start_pos, _} ->
        case :binary.match(buffer, "</page>") do
          :nomatch ->
            :need_more

          {end_pos, end_len} ->
            page_end = end_pos + end_len
            page_xml = :binary.part(buffer, start_pos, page_end - start_pos)
            rest = :binary.part(buffer, page_end, byte_size(buffer) - page_end)
            {:ok, page_xml, rest}
        end
    end
  end

  defp parse_page_xml(xml) do
    # Simple regex-based parsing (faster than full XML parser for our needs)
    %{
      title: extract_tag(xml, "title"),
      id: extract_tag(xml, "id") |> parse_int(),
      ns: extract_tag(xml, "ns") |> parse_int(),
      redirect: extract_redirect(xml),
      text: extract_tag(xml, "text")
    }
  end

  defp extract_tag(xml, tag) do
    case Regex.run(~r/<#{tag}[^>]*>([^<]*)<\/#{tag}>/s, xml) do
      [_, content] -> content
      _ -> nil
    end
  end

  defp extract_redirect(xml) do
    case Regex.run(~r/<redirect title="([^"]+)"/, xml) do
      [_, title] -> title
      _ -> nil
    end
  end

  defp parse_int(nil), do: 0

  defp parse_int(str) do
    case Integer.parse(str) do
      {n, _} -> n
      :error -> 0
    end
  end

  defp parse_article(page) do
    %{
      title: page.title,
      text: page.text || "",
      id: page.id,
      ns: page.ns,
      redirect: page.redirect,
      categories: extract_categories(page.text || "")
    }
  end

  defp extract_categories(text) do
    ~r/\[\[Category:([^\]|]+)/i
    |> Regex.scan(text)
    |> Enum.map(fn [_, cat] -> String.trim(cat) end)
  end

  defp format_bytes(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_bytes(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"

  defp format_bytes(bytes) when bytes < 1024 * 1024 * 1024,
    do: "#{Float.round(bytes / 1024 / 1024, 1)} MB"

  defp format_bytes(bytes), do: "#{Float.round(bytes / 1024 / 1024 / 1024, 2)} GB"
end
