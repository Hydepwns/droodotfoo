defmodule Droodotfoo.GitHub.Cache do
  @moduledoc """
  ETS-based cache for GitHub API data with TTL support.
  Runs as a GenServer to manage cache lifecycle and cleanup.
  """

  use GenServer
  require Logger

  @table_name :github_repo_cache
  @default_ttl :timer.hours(1)

  @type cache_key :: {String.t(), String.t()}
  @type cache_value :: term()

  ## Client API

  @doc """
  Starts the cache GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets a value from the cache.

  Returns `{:ok, value, cached_at}` if found and not expired, `:miss` otherwise.
  """
  @spec get(cache_key()) :: {:ok, cache_value(), integer()} | :miss
  def get(key) do
    case :ets.lookup(@table_name, key) do
      [{^key, value, expires_at, cached_at}] ->
        if System.system_time(:millisecond) < expires_at do
          {:ok, value, cached_at}
        else
          :ets.delete(@table_name, key)
          :miss
        end

      [] ->
        :miss
    end
  rescue
    ArgumentError ->
      Logger.warning("Cache table not initialized")
      :miss
  end

  @doc """
  Puts a value into the cache with optional TTL.

  ## Options

    * `:ttl` - Time to live in milliseconds (default: 1 hour)
  """
  @spec put(cache_key(), cache_value(), keyword()) :: :ok
  def put(key, value, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    now = System.system_time(:millisecond)
    expires_at = now + ttl

    :ets.insert(@table_name, {key, value, expires_at, now})
    :ok
  rescue
    ArgumentError ->
      Logger.error("Failed to insert into cache table")
      :ok
  end

  @doc """
  Clears the entire cache.
  """
  @spec clear() :: :ok
  def clear do
    try do
      :ets.delete_all_objects(@table_name)
      :ok
    rescue
      ArgumentError ->
        Logger.warning("Cache table not initialized")
        :ok
    end
  end

  @doc """
  Clears a specific key from the cache.
  """
  @spec delete(cache_key()) :: :ok
  def delete(key) do
    try do
      :ets.delete(@table_name, key)
      :ok
    rescue
      ArgumentError ->
        :ok
    end
  end

  @doc """
  Returns cache statistics.
  """
  @spec stats() :: map()
  def stats do
    try do
      size = :ets.info(@table_name, :size)
      memory = :ets.info(@table_name, :memory)

      %{
        size: size,
        memory_words: memory,
        memory_bytes: memory * :erlang.system_info(:wordsize)
      }
    rescue
      ArgumentError ->
        %{size: 0, memory_words: 0, memory_bytes: 0}
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
    Logger.info("GitHub cache initialized")

    {:ok, %{}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_expired()
    schedule_cleanup()
    {:noreply, state}
  end

  ## Private Functions

  defp cleanup_expired do
    now = System.system_time(:millisecond)

    expired_count =
      @table_name
      |> :ets.select([{{:"$1", :"$2", :"$3", :"$4"}, [{:<, :"$3", now}], [:"$1"]}])
      |> Enum.each(&:ets.delete(@table_name, &1))
      |> length()

    if expired_count > 0 do
      Logger.debug("Cleaned up #{expired_count} expired cache entries")
    end
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, :timer.minutes(5))
  end
end
