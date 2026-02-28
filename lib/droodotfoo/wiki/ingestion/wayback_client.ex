defmodule Droodotfoo.Wiki.Ingestion.WaybackClient do
  @moduledoc """
  Client for fetching archived content from the Wayback Machine.

  Uses the CDX API to list archived URLs and fetches snapshots.

  ## Usage

      # List all archived URLs for a domain
      {:ok, urls} = WaybackClient.list_archived_urls("vintagemachinery.org", prefix: "pubs/")

      # Fetch a specific snapshot
      {:ok, html} = WaybackClient.fetch_snapshot("http://vintagemachinery.org/pubs/123.html")

  """

  require Logger

  @cdx_api "https://web.archive.org/cdx/search/cdx"
  @wayback_base "https://web.archive.org/web"
  @rate_limit_ms 1000

  @type archived_url :: %{
          url: String.t(),
          timestamp: String.t(),
          status: String.t(),
          mime_type: String.t()
        }

  @doc """
  List all archived URLs for a domain/path prefix.

  Returns unique URLs with their most recent successful snapshot.

  ## Options

    * `:prefix` - Path prefix to filter (e.g., "pubs/")
    * `:limit` - Maximum URLs to return
    * `:from_timestamp` - Only snapshots after this timestamp (YYYYMMDD)

  """
  @spec list_archived_urls(String.t(), keyword()) :: {:ok, [archived_url()]} | {:error, term()}
  def list_archived_urls(domain, opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "")
    limit = Keyword.get(opts, :limit)
    from_ts = Keyword.get(opts, :from_timestamp)

    url_pattern = "#{domain}/#{prefix}*"

    params =
      [
        url: url_pattern,
        output: "json",
        fl: "timestamp,original,statuscode,mimetype",
        filter: "statuscode:200",
        collapse: "urlkey"
      ]
      |> maybe_add(:limit, limit)
      |> maybe_add(:from, from_ts)

    case cdx_request(params) do
      {:ok, [_header | rows]} ->
        urls =
          rows
          |> Enum.map(fn [timestamp, url, status, mime] ->
            %{
              url: url,
              timestamp: timestamp,
              status: status,
              mime_type: mime
            }
          end)
          |> filter_html_pages()

        {:ok, urls}

      {:ok, []} ->
        {:ok, []}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Count total archived URLs for a domain/prefix.
  """
  @spec count_archived_urls(String.t(), keyword()) :: {:ok, integer()} | {:error, term()}
  def count_archived_urls(domain, opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "")
    url_pattern = "#{domain}/#{prefix}*"

    params = [
      url: url_pattern,
      output: "json",
      fl: "urlkey",
      filter: "statuscode:200",
      collapse: "urlkey",
      showNumPages: true
    ]

    case cdx_request(params) do
      {:ok, [[count]]} when is_integer(count) ->
        {:ok, count}

      {:ok, rows} when is_list(rows) ->
        # Count unique URLs
        {:ok, length(rows) - 1}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Fetch the most recent snapshot of a URL.

  Returns the HTML content.
  """
  @spec fetch_snapshot(String.t(), String.t() | nil) :: {:ok, String.t()} | {:error, term()}
  def fetch_snapshot(url, timestamp \\ nil) do
    rate_limit()

    # "2" means most recent
    ts = timestamp || "2"
    wayback_url = "#{@wayback_base}/#{ts}id_/#{url}"

    case Req.get(wayback_url, receive_timeout: 30_000) do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:request_error, reason}}
    end
  end

  @doc """
  Fetch snapshot with metadata (timestamp, original URL).
  """
  @spec fetch_snapshot_with_meta(String.t()) :: {:ok, map()} | {:error, term()}
  def fetch_snapshot_with_meta(url) do
    # First get the most recent timestamp
    params = [
      url: url,
      output: "json",
      fl: "timestamp,original",
      filter: "statuscode:200",
      limit: 1,
      sort: "reverse"
    ]

    with {:ok, [_header, [timestamp, original] | _]} <- cdx_request(params),
         {:ok, html} <- fetch_snapshot(original, timestamp) do
      {:ok,
       %{
         html: html,
         timestamp: timestamp,
         original_url: original,
         wayback_url: "#{@wayback_base}/#{timestamp}/#{original}"
       }}
    else
      {:ok, [_header]} -> {:error, :not_found}
      {:ok, []} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Stream all archived URLs (paginated).

  Useful for large archives where listing all at once is impractical.
  """
  @spec stream_archived_urls(String.t(), keyword()) :: Enumerable.t()
  def stream_archived_urls(domain, opts \\ []) do
    prefix = Keyword.get(opts, :prefix, "")
    batch_size = Keyword.get(opts, :batch_size, 1000)

    Stream.resource(
      fn -> {0, false} end,
      fn
        {_page, true} ->
          {:halt, nil}

        {page, false} ->
          case list_archived_urls_page(domain, prefix, page, batch_size) do
            {:ok, []} ->
              {:halt, nil}

            {:ok, urls} when length(urls) < batch_size ->
              {urls, {page + 1, true}}

            {:ok, urls} ->
              {urls, {page + 1, false}}

            {:error, reason} ->
              Logger.error("Wayback stream error on page #{page}: #{inspect(reason)}")
              {:halt, nil}
          end
      end,
      fn _ -> :ok end
    )
  end

  defp list_archived_urls_page(domain, prefix, page, batch_size) do
    url_pattern = "#{domain}/#{prefix}*"

    params = [
      url: url_pattern,
      output: "json",
      fl: "timestamp,original,statuscode,mimetype",
      filter: "statuscode:200",
      collapse: "urlkey",
      limit: batch_size,
      page: page
    ]

    case cdx_request(params) do
      {:ok, [_header | rows]} ->
        urls =
          rows
          |> Enum.map(fn [timestamp, url, status, mime] ->
            %{url: url, timestamp: timestamp, status: status, mime_type: mime}
          end)
          |> filter_html_pages()

        {:ok, urls}

      {:ok, []} ->
        {:ok, []}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private helpers

  defp cdx_request(params) do
    rate_limit()

    case Req.get(@cdx_api, params: params, receive_timeout: 60_000) do
      {:ok, %{status: 200, body: body}} when is_list(body) ->
        {:ok, body}

      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        case Jason.decode(body) do
          {:ok, decoded} -> {:ok, decoded}
          {:error, _} -> {:error, :json_decode_error}
        end

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:request_error, reason}}
    end
  end

  defp filter_html_pages(urls) do
    Enum.filter(urls, fn %{mime_type: mime, url: url} ->
      html_mime?(mime) || html_extension?(url)
    end)
  end

  defp html_mime?(mime) do
    mime in ["text/html", "text/htm", "application/xhtml+xml"]
  end

  defp html_extension?(url) do
    ext = url |> URI.parse() |> Map.get(:path, "") |> Path.extname() |> String.downcase()
    # Include .ashx which VintageMachinery wiki uses
    ext in [".html", ".htm", ".ashx", ""]
  end

  defp maybe_add(params, _key, nil), do: params
  defp maybe_add(params, key, value), do: Keyword.put(params, key, value)

  defp rate_limit do
    Process.sleep(@rate_limit_ms)
  end
end
