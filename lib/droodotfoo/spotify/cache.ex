defmodule Droodotfoo.Spotify.Cache do
  @moduledoc """
  ETS-based cache for Spotify data with TTL support.
  Runs as a GenServer to manage cache lifecycle and cleanup.
  """

  use GenServer
  require Logger

  @table_name :spotify_cache
  @default_ttl :timer.minutes(5)
  @cleanup_interval :timer.minutes(1)
  @max_entries 100

  @type cache_key :: atom() | String.t()
  @type cache_value :: term()

  ## Client API

  @doc """
  Starts the cache GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets a cached value by key.

  Returns `{:ok, value}` if found and not expired, `{:error, :not_found}` otherwise.
  """
  @spec get(cache_key()) :: {:ok, cache_value()} | {:error, :not_found}
  def get(key) do
    case :ets.lookup(@table_name, key) do
      [{^key, value, expires_at, _cached_at}] ->
        if System.system_time(:millisecond) < expires_at do
          {:ok, value}
        else
          :ets.delete(@table_name, key)
          {:error, :not_found}
        end

      [] ->
        {:error, :not_found}
    end
  rescue
    ArgumentError ->
      {:error, :not_found}
  end

  @doc """
  Puts a value in the cache with optional TTL in milliseconds.
  """
  @spec put(cache_key(), cache_value(), integer()) :: :ok
  def put(key, value, ttl_ms \\ @default_ttl) do
    now = System.system_time(:millisecond)
    expires_at = now + ttl_ms

    maybe_evict_oldest()
    :ets.insert(@table_name, {key, value, expires_at, now})
    :ok
  rescue
    ArgumentError ->
      Logger.error("Failed to insert into Spotify cache table")
      :ok
  end

  @doc """
  Deletes a key from the cache.
  """
  @spec delete(cache_key()) :: :ok
  def delete(key) do
    :ets.delete(@table_name, key)
    :ok
  rescue
    ArgumentError ->
      Logger.warning("Spotify cache: cannot delete key, table not initialized")
      :ok
  end

  @doc """
  Clears all cached data.
  """
  @spec clear() :: :ok
  def clear do
    :ets.delete_all_objects(@table_name)
    :ok
  rescue
    ArgumentError ->
      Logger.warning("Spotify cache: cannot clear, table not initialized")
      :ok
  end

  @doc """
  Returns cache statistics.
  """
  @spec stats() :: map()
  def stats do
    now = System.system_time(:millisecond)
    all_entries = :ets.tab2list(@table_name)

    active_count = Enum.count(all_entries, fn {_k, _v, exp, _c} -> exp > now end)
    total = length(all_entries)

    %{
      total_keys: total,
      active_keys: active_count,
      expired_keys: total - active_count,
      memory_bytes: :ets.info(@table_name, :memory) * :erlang.system_info(:wordsize)
    }
  rescue
    ArgumentError ->
      %{total_keys: 0, active_keys: 0, expired_keys: 0, memory_bytes: 0}
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
    Logger.info("Spotify cache initialized")

    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_expired()
    schedule_cleanup()
    {:noreply, state}
  end

  ## Private Functions

  defp maybe_evict_oldest do
    size = :ets.info(@table_name, :size)

    if size >= @max_entries do
      case :ets.select(@table_name, [{{:"$1", :_, :_, :"$4"}, [], [{{:"$4", :"$1"}}]}], 1) do
        {[{_oldest_time, oldest_key} | _], _} ->
          :ets.delete(@table_name, oldest_key)

        _ ->
          :ok
      end
    end
  rescue
    ArgumentError ->
      Logger.debug("Spotify cache: eviction skipped, table not ready")
  end

  defp cleanup_expired do
    now = System.system_time(:millisecond)

    expired_keys =
      @table_name
      |> :ets.select([{{:"$1", :_, :"$3", :_}, [{:<, :"$3", now}], [:"$1"]}])

    Enum.each(expired_keys, &:ets.delete(@table_name, &1))
  rescue
    ArgumentError ->
      Logger.debug("Spotify cache: cleanup skipped, table not ready")
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval)
  end
end
