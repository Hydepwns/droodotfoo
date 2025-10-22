defmodule Droodotfoo.Performance.Cache do
  @moduledoc """
  ETS-based caching system with TTL support for performance optimization.

  This module provides a simple yet powerful caching layer for API responses,
  computed values, and frequently accessed data. It uses ETS for fast in-memory
  storage and supports automatic expiration via TTL (time-to-live).

  ## Features

  - Fast ETS-based storage for sub-microsecond reads
  - TTL (time-to-live) support with automatic expiration
  - Namespace isolation for different cache types
  - Cache statistics (hits, misses, size, memory)
  - Bulk operations (clear, prune expired entries)
  - Pattern-based cache invalidation

  ## Usage

      # Start the cache (typically in Application.start/2)
      Droodotfoo.Performance.Cache.start_link()

      # Store a value with 5-minute TTL
      Cache.put(:spotify, "track:123", track_data, ttl: 300_000)

      # Retrieve a value
      case Cache.get(:spotify, "track:123") do
        {:ok, track_data} -> track_data
        :error -> fetch_from_api()
      end

      # Cache with fetch callback (fetch-on-miss pattern)
      Cache.fetch(:github, "repo:droodotfoo", fn ->
        GitHub.fetch_repo("droodotfoo")
      end, ttl: 600_000)

      # Get cache statistics
      Cache.stats(:spotify)
      # => %{hits: 1234, misses: 56, size: 100, memory_bytes: 524288}

  ## Cache Namespaces

  Common namespaces used throughout the application:

  - `:spotify` - Spotify API responses (tracks, playlists, devices)
  - `:github` - GitHub API responses (repos, commits, stars)
  - `:web3` - Web3 data (ENS, NFTs, tokens, transactions)
  - `:ipfs` - IPFS content and metadata
  - `:portal` - Portal P2P session data
  - `:computed` - Computed/derived values (charts, summaries)
  """

  use GenServer
  require Logger

  @type namespace :: atom()
  @type key :: term()
  @type value :: term()
  @type ttl :: pos_integer() | :infinity
  @type cache_entry :: {key, value, expires_at :: integer() | :infinity}
  @type stats :: %{
          hits: non_neg_integer(),
          misses: non_neg_integer(),
          size: non_neg_integer(),
          memory_bytes: non_neg_integer()
        }

  @default_ttl 300_000
  # 5 minutes
  @cleanup_interval 60_000
  # 1 minute
  @table_name :droodotfoo_cache

  ## Public API

  @doc """
  Starts the cache GenServer.

  ## Options

  - `:name` - Registered name (default: `__MODULE__`)
  - `:cleanup_interval` - Interval for expired entry cleanup in ms (default: 60_000)
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc """
  Stores a value in the cache with optional TTL.

  ## Parameters

  - `namespace` - Cache namespace (atom)
  - `key` - Cache key (any term)
  - `value` - Value to cache
  - `opts` - Options
    - `:ttl` - Time-to-live in milliseconds (default: 300_000)

  ## Examples

      Cache.put(:spotify, "track:123", %{name: "Song", artist: "Artist"})
      Cache.put(:github, "stars", 1234, ttl: 3600_000)
      Cache.put(:web3, "ens:vitalik.eth", "0x123...", ttl: :infinity)
  """
  @spec put(namespace(), key(), value(), keyword()) :: :ok
  def put(namespace, key, value, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    expires_at = calculate_expiration(ttl)

    cache_key = {namespace, key}
    entry = {value, expires_at}

    :ets.insert(@table_name, {cache_key, entry})
    :ok
  end

  @doc """
  Retrieves a value from the cache.

  Returns `{:ok, value}` if found and not expired, `:error` otherwise.

  ## Examples

      case Cache.get(:spotify, "track:123") do
        {:ok, track} -> track
        :error -> fetch_from_spotify()
      end
  """
  @spec get(namespace(), key()) :: {:ok, value()} | :error
  def get(namespace, key) do
    cache_key = {namespace, key}

    case :ets.lookup(@table_name, cache_key) do
      [{^cache_key, {value, expires_at}}] ->
        if expired?(expires_at) do
          :ets.delete(@table_name, cache_key)
          record_miss(namespace)
          :error
        else
          record_hit(namespace)
          {:ok, value}
        end

      [] ->
        record_miss(namespace)
        :error
    end
  end

  @doc """
  Fetch-on-miss pattern: get cached value or execute function and cache result.

  ## Examples

      track = Cache.fetch(:spotify, "track:123", fn ->
        Spotify.get_track("123")
      end, ttl: 300_000)
  """
  @spec fetch(namespace(), key(), (-> value()), keyword()) :: value()
  def fetch(namespace, key, fun, opts \\ []) when is_function(fun, 0) do
    case get(namespace, key) do
      {:ok, value} ->
        value

      :error ->
        value = fun.()
        put(namespace, key, value, opts)
        value
    end
  end

  @doc """
  Deletes a specific cache entry.

  ## Examples

      Cache.delete(:spotify, "track:123")
  """
  @spec delete(namespace(), key()) :: :ok
  def delete(namespace, key) do
    cache_key = {namespace, key}
    :ets.delete(@table_name, cache_key)
    :ok
  end

  @doc """
  Clears all entries in a namespace.

  ## Examples

      Cache.clear(:spotify)  # Clear all Spotify cache
      Cache.clear(:all)      # Clear entire cache
  """
  @spec clear(namespace() | :all) :: :ok
  def clear(:all) do
    :ets.delete_all_objects(@table_name)
    clear_stats(:all)
    :ok
  end

  def clear(namespace) do
    match_spec = [{{{{namespace, :_}, :_}}, [], [true]}]
    :ets.select_delete(@table_name, match_spec)
    clear_stats(namespace)
    :ok
  end

  @doc """
  Removes expired entries from cache.

  Returns the number of entries deleted.

  ## Examples

      deleted = Cache.prune_expired()
      # => 42
  """
  @spec prune_expired() :: non_neg_integer()
  def prune_expired do
    now = System.monotonic_time(:millisecond)

    match_spec = [
      {{:_, {:"$1", :"$2"}}, [{:andalso, {:is_integer, :"$2"}, {:<, :"$2", now}}], [true]}
    ]

    :ets.select_delete(@table_name, match_spec)
  end

  @doc """
  Returns cache statistics for a namespace.

  ## Examples

      Cache.stats(:spotify)
      # => %{hits: 1234, misses: 56, size: 100, memory_bytes: 524288}

      Cache.stats(:all)
      # => %{hits: 5678, misses: 234, size: 500, memory_bytes: 2097152}
  """
  @spec stats(namespace() | :all) :: stats()
  def stats(:all) do
    info = :ets.info(@table_name)
    stats_data = get_stats(:all)

    %{
      hits: stats_data.hits,
      misses: stats_data.misses,
      size: Keyword.get(info, :size, 0),
      memory_bytes: Keyword.get(info, :memory, 0) * :erlang.system_info(:wordsize)
    }
  end

  def stats(namespace) do
    # Count entries in namespace
    match_spec = [{{{{namespace, :_}, :_}}, [], [true]}]
    size = :ets.select_count(@table_name, match_spec)

    stats_data = get_stats(namespace)

    %{
      hits: stats_data.hits,
      misses: stats_data.misses,
      size: size,
      memory_bytes: estimate_namespace_memory(namespace)
    }
  end

  ## GenServer Callbacks

  @impl true
  def init(opts) do
    # Create ETS table for cache entries
    :ets.new(@table_name, [
      :set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: true
    ])

    # Create ETS table for statistics
    :ets.new(:droodotfoo_cache_stats, [
      :set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: true
    ])

    cleanup_interval = Keyword.get(opts, :cleanup_interval, @cleanup_interval)
    schedule_cleanup(cleanup_interval)

    {:ok, %{cleanup_interval: cleanup_interval}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    prune_expired()
    schedule_cleanup(state.cleanup_interval)
    {:noreply, state}
  end

  ## Private Functions

  defp calculate_expiration(:infinity), do: :infinity

  defp calculate_expiration(ttl) when is_integer(ttl) and ttl > 0 do
    System.monotonic_time(:millisecond) + ttl
  end

  defp expired?(:infinity), do: false
  defp expired?(expires_at), do: System.monotonic_time(:millisecond) > expires_at

  defp schedule_cleanup(interval) do
    Process.send_after(self(), :cleanup, interval)
  end

  defp record_hit(namespace) do
    key = {:hits, namespace}
    :ets.update_counter(:droodotfoo_cache_stats, key, {2, 1}, {key, 0})
    :ets.update_counter(:droodotfoo_cache_stats, {:hits, :all}, {2, 1}, {{:hits, :all}, 0})
  end

  defp record_miss(namespace) do
    key = {:misses, namespace}
    :ets.update_counter(:droodotfoo_cache_stats, key, {2, 1}, {key, 0})
    :ets.update_counter(:droodotfoo_cache_stats, {:misses, :all}, {2, 1}, {{:misses, :all}, 0})
  end

  defp get_stats(namespace) do
    hits = get_stat_value({:hits, namespace})
    misses = get_stat_value({:misses, namespace})

    %{hits: hits, misses: misses}
  end

  defp get_stat_value(key) do
    case :ets.lookup(:droodotfoo_cache_stats, key) do
      [{^key, value}] -> value
      [] -> 0
    end
  end

  defp clear_stats(:all) do
    :ets.delete_all_objects(:droodotfoo_cache_stats)
  end

  defp clear_stats(namespace) do
    :ets.delete(:droodotfoo_cache_stats, {:hits, namespace})
    :ets.delete(:droodotfoo_cache_stats, {:misses, namespace})
  end

  defp estimate_namespace_memory(namespace) do
    # Rough estimation based on entry count
    match_spec = [{{{{namespace, :_}, :_}}, [], [true]}]
    count = :ets.select_count(@table_name, match_spec)
    # Assume ~1KB average per entry
    count * 1024
  end
end
