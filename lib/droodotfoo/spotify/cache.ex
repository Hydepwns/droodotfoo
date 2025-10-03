defmodule Droodotfoo.Spotify.Cache do
  @moduledoc """
  GenServer for caching Spotify data with TTL support.
  Reduces API calls and improves response times.
  """

  use GenServer

  # 5 minutes
  @default_ttl_ms 5 * 60 * 1000
  # 1 minute
  @cleanup_interval_ms 60 * 1000

  defstruct [:data, :expiry_times]

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets a cached value by key. Returns {:ok, value} if found and not expired,
  {:error, :not_found} otherwise.
  """
  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  @doc """
  Puts a value in the cache with optional TTL in milliseconds.
  """
  def put(key, value, ttl_ms \\ @default_ttl_ms) do
    GenServer.call(__MODULE__, {:put, key, value, ttl_ms})
  end

  @doc """
  Deletes a key from the cache.
  """
  def delete(key) do
    GenServer.call(__MODULE__, {:delete, key})
  end

  @doc """
  Clears all cached data.
  """
  def clear do
    GenServer.call(__MODULE__, :clear)
  end

  @doc """
  Returns cache statistics.
  """
  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    schedule_cleanup()

    state = %__MODULE__{
      data: %{},
      expiry_times: %{}
    }

    {:ok, state}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    now = System.monotonic_time(:millisecond)

    case Map.get(state.expiry_times, key) do
      nil ->
        {:reply, {:error, :not_found}, state}

      expiry_time when expiry_time <= now ->
        # Expired, remove and return not found
        new_data = Map.delete(state.data, key)
        new_expiry_times = Map.delete(state.expiry_times, key)
        new_state = %{state | data: new_data, expiry_times: new_expiry_times}
        {:reply, {:error, :not_found}, new_state}

      _ ->
        # Not expired, return value
        value = Map.get(state.data, key)
        {:reply, {:ok, value}, state}
    end
  end

  @impl true
  def handle_call({:put, key, value, ttl_ms}, _from, state) do
    now = System.monotonic_time(:millisecond)
    expiry_time = now + ttl_ms

    new_data = Map.put(state.data, key, value)
    new_expiry_times = Map.put(state.expiry_times, key, expiry_time)

    new_state = %{state | data: new_data, expiry_times: new_expiry_times}

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call({:delete, key}, _from, state) do
    new_data = Map.delete(state.data, key)
    new_expiry_times = Map.delete(state.expiry_times, key)

    new_state = %{state | data: new_data, expiry_times: new_expiry_times}

    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:clear, _from, state) do
    new_state = %{state | data: %{}, expiry_times: %{}}
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_call(:stats, _from, state) do
    now = System.monotonic_time(:millisecond)

    active_keys =
      state.expiry_times
      |> Enum.filter(fn {_key, expiry} -> expiry > now end)
      |> Enum.count()

    stats = %{
      total_keys: map_size(state.data),
      active_keys: active_keys,
      expired_keys: map_size(state.data) - active_keys
    }

    {:reply, stats, state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    now = System.monotonic_time(:millisecond)

    # Find expired keys
    expired_keys =
      state.expiry_times
      |> Enum.filter(fn {_key, expiry} -> expiry <= now end)
      |> Enum.map(fn {key, _expiry} -> key end)

    # Remove expired keys
    new_data =
      Enum.reduce(expired_keys, state.data, fn key, acc ->
        Map.delete(acc, key)
      end)

    new_expiry_times =
      Enum.reduce(expired_keys, state.expiry_times, fn key, acc ->
        Map.delete(acc, key)
      end)

    new_state = %{state | data: new_data, expiry_times: new_expiry_times}

    # Schedule next cleanup
    schedule_cleanup()

    {:noreply, new_state}
  end

  # Private Functions

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval_ms)
  end
end
