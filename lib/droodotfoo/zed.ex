defmodule Droodotfoo.Zed do
  @moduledoc """
  Fetches extension metadata from the Zed extensions API.
  Caches results in the shared GitHub ETS cache with a 4-hour TTL.
  """

  require Logger

  alias Droodotfoo.GitHub.Cache
  alias Droodotfoo.HttpClient

  @api_url "https://api.zed.dev"
  @cache_ttl :timer.hours(4)

  @doc "Returns the download count for a Zed extension by ID."
  @spec download_count(String.t()) :: {:ok, integer()} | {:error, term()}
  def download_count(extension_id) do
    cache_key = {:zed_downloads, extension_id}

    case Cache.get(cache_key) do
      {:ok, count, _cached_at} -> {:ok, count}
      :miss -> fetch_and_cache(extension_id, cache_key)
    end
  end

  @doc "Formats a download count as a human-readable string (e.g. 19.6k)."
  @spec format_count(integer()) :: String.t()
  def format_count(n) when n >= 1_000_000, do: "#{Float.round(n / 1_000_000, 1)}M"
  def format_count(n) when n >= 1_000, do: "#{Float.round(n / 1_000, 1)}k"
  def format_count(n), do: to_string(n)

  defp fetch_and_cache(extension_id, cache_key) do
    client =
      HttpClient.new(
        @api_url,
        [{"accept", "application/json"}, {"user-agent", "droodotfoo"}],
        timeout: 5_000,
        max_retries: 1
      )

    case HttpClient.get(client, "/extensions?filter=#{extension_id}") do
      {:ok, %{body: %{"data" => extensions}}} ->
        count =
          case Enum.find(extensions, &(&1["id"] == extension_id)) do
            %{"download_count" => c} -> c
            _ -> 0
          end

        Cache.put(cache_key, count, ttl: @cache_ttl)
        {:ok, count}

      {:error, reason} ->
        Logger.warning("Zed API error for #{extension_id}: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
