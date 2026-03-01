defmodule Droodotfoo.Content.PatternCache do
  @moduledoc """
  Cache for generated SVG patterns.

  Thin wrapper around `Performance.Cache` with pattern-specific logic.
  Since patterns are deterministic (same slug + options = same SVG),
  they can be cached with a long TTL.

  ## Performance Impact

  Pattern generation is CPU-intensive (SVG string building). Caching reduces:
  - CPU usage on homepage (shows 5 patterns)
  - Response time for repeated pattern requests
  - Server load during traffic spikes
  """

  require Logger

  alias Droodotfoo.Performance.Cache

  @namespace :pattern
  @default_ttl :timer.hours(24)

  @type cache_key :: {String.t(), keyword()}
  @type cache_value :: String.t()

  @doc """
  Gets a cached pattern or generates and caches it.

  ## Examples

      iex> PatternCache.get_or_generate("my-post", [style: :waves])
      "<?xml version=\\"1.0\\"...>"
  """
  @spec get_or_generate(String.t(), keyword()) :: cache_value()
  def get_or_generate(slug, opts \\ []) do
    cache_key = normalize_cache_key(slug, opts)

    case Cache.get(@namespace, cache_key) do
      {:ok, svg} ->
        Logger.debug("Pattern cache hit for #{slug}")
        svg

      :error ->
        Logger.debug("Pattern cache miss for #{slug}, generating...")
        svg = Droodotfoo.Content.PatternGenerator.generate_svg(slug, opts)
        Cache.put(@namespace, cache_key, svg, ttl: @default_ttl)
        svg
    end
  end

  @doc """
  Gets a value from the cache.

  Returns `{:ok, svg}` if found and not expired, `:miss` otherwise.
  """
  @spec get(cache_key()) :: {:ok, cache_value()} | :miss
  def get(key) do
    case Cache.get(@namespace, key) do
      {:ok, value} -> {:ok, value}
      :error -> :miss
    end
  end

  @doc """
  Puts a value into the cache with optional TTL.

  ## Options

    * `:ttl` - Time to live in milliseconds (default: 24 hours)
  """
  @spec put(cache_key(), cache_value(), keyword()) :: :ok
  def put(key, svg, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    Cache.put(@namespace, key, svg, ttl: ttl)
  end

  @doc """
  Clears the entire pattern cache.
  """
  @spec clear() :: :ok
  def clear do
    Cache.clear(@namespace)
    Logger.info("Pattern cache cleared")
    :ok
  end

  @doc """
  Clears a specific pattern from the cache.
  """
  @spec delete(String.t(), keyword()) :: :ok
  def delete(slug, opts \\ []) do
    cache_key = normalize_cache_key(slug, opts)
    Cache.delete(@namespace, cache_key)
  end

  @doc """
  Returns cache statistics.

  ## Returns

    * `size` - Number of cached patterns
    * `memory_bytes` - Memory used by cache
    * `hits` - Cache hits
    * `misses` - Cache misses
  """
  @spec stats() :: map()
  def stats do
    stats = Cache.stats(@namespace)

    Map.merge(stats, %{
      ttl_hours: @default_ttl / :timer.hours(1)
    })
  end

  ## Private Functions

  defp normalize_cache_key(slug, opts) do
    # Sort opts for consistent cache keys
    normalized_opts =
      opts
      |> Keyword.take([:style, :width, :height, :animate])
      |> Enum.sort()

    {slug, normalized_opts}
  end
end
