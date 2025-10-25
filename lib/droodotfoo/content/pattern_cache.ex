defmodule Droodotfoo.Content.PatternCache do
  @moduledoc """
  ETS-based cache for generated SVG patterns with TTL support.

  Since patterns are deterministic (same slug + options = same SVG),
  they can be cached indefinitely. We use a 24-hour TTL to allow for
  occasional pattern regeneration in case of updates to the generator.

  ## Performance Impact

  Pattern generation is CPU-intensive (SVG string building). Caching reduces:
  - CPU usage on homepage (shows 5 patterns)
  - Response time for repeated pattern requests
  - Server load during traffic spikes

  ## Cache Strategy

  - Cache key: {slug, opts} tuple
  - TTL: 24 hours (patterns are deterministic)
  - Cleanup: Every 10 minutes (removes expired entries)
  - Read concurrency: Enabled for high performance
  """

  use GenServer
  require Logger

  @table_name :pattern_cache
  @default_ttl :timer.hours(24)
  @cleanup_interval :timer.minutes(10)

  @type cache_key :: {String.t(), keyword()}
  @type cache_value :: String.t()

  ## Client API

  @doc """
  Starts the pattern cache GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets a cached pattern or generates and caches it.

  ## Examples

      iex> PatternCache.get_or_generate("my-post", [style: :waves])
      "<?xml version=\\"1.0\\"...>"
  """
  @spec get_or_generate(String.t(), keyword()) :: cache_value()
  def get_or_generate(slug, opts \\ []) do
    cache_key = normalize_cache_key(slug, opts)

    case get(cache_key) do
      {:ok, svg} ->
        Logger.debug("Pattern cache hit for #{slug}")
        svg

      :miss ->
        Logger.debug("Pattern cache miss for #{slug}, generating...")
        svg = Droodotfoo.Content.PatternGenerator.generate_svg(slug, opts)
        put(cache_key, svg)
        svg
    end
  end

  @doc """
  Gets a value from the cache.

  Returns `{:ok, svg}` if found and not expired, `:miss` otherwise.
  """
  @spec get(cache_key()) :: {:ok, cache_value()} | :miss
  def get(key) do
    try do
      case :ets.lookup(@table_name, key) do
        [{^key, svg, expires_at}] ->
          if System.system_time(:millisecond) < expires_at do
            {:ok, svg}
          else
            :ets.delete(@table_name, key)
            :miss
          end

        [] ->
          :miss
      end
    rescue
      ArgumentError ->
        Logger.warning("Pattern cache table not initialized")
        :miss
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
    expires_at = System.system_time(:millisecond) + ttl

    try do
      :ets.insert(@table_name, {key, svg, expires_at})
      :ok
    rescue
      ArgumentError ->
        Logger.error("Failed to insert into pattern cache table")
        :ok
    end
  end

  @doc """
  Clears the entire cache.
  """
  @spec clear() :: :ok
  def clear do
    try do
      :ets.delete_all_objects(@table_name)
      Logger.info("Pattern cache cleared")
      :ok
    rescue
      ArgumentError ->
        Logger.warning("Pattern cache table not initialized")
        :ok
    end
  end

  @doc """
  Clears a specific pattern from the cache.
  """
  @spec delete(String.t(), keyword()) :: :ok
  def delete(slug, opts \\ []) do
    cache_key = normalize_cache_key(slug, opts)

    try do
      :ets.delete(@table_name, cache_key)
      :ok
    rescue
      ArgumentError ->
        :ok
    end
  end

  @doc """
  Returns cache statistics.

  ## Returns

    * `size` - Number of cached patterns
    * `memory_bytes` - Memory used by cache
    * `hit_rate` - Cache hit rate (if tracking enabled)
  """
  @spec stats() :: map()
  def stats do
    try do
      size = :ets.info(@table_name, :size)
      memory = :ets.info(@table_name, :memory)

      %{
        size: size,
        memory_words: memory,
        memory_bytes: memory * :erlang.system_info(:wordsize),
        ttl_hours: @default_ttl / :timer.hours(1)
      }
    rescue
      ArgumentError ->
        %{size: 0, memory_words: 0, memory_bytes: 0, ttl_hours: 24}
    end
  end

  ## GenServer Callbacks

  @impl true
  def init(_opts) do
    :ets.new(@table_name, [
      :named_table,
      :public,
      :set,
      read_concurrency: true,
      write_concurrency: true
    ])

    schedule_cleanup()
    Logger.info("Pattern cache initialized (TTL: #{@default_ttl / 1000 / 60 / 60}h)")

    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_expired()
    schedule_cleanup()
    {:noreply, state}
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

  defp cleanup_expired do
    now = System.system_time(:millisecond)

    expired_keys =
      @table_name
      |> :ets.select([{{:"$1", :"$2", :"$3"}, [{:<, :"$3", now}], [:"$1"]}])

    expired_count = length(expired_keys)

    if expired_count > 0 do
      Enum.each(expired_keys, &:ets.delete(@table_name, &1))
      Logger.debug("Cleaned up #{expired_count} expired pattern cache entries")
    end
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end
end
