defmodule Droodotfoo.Content.PatternRateLimiter do
  @moduledoc """
  Rate limiting for pattern generation endpoint.
  Prevents CPU exhaustion from excessive pattern generation requests.
  """

  use GenServer
  require Logger

  @table_name :pattern_rate_limits
  @max_requests_per_minute 30
  @max_requests_per_hour 300
  @cleanup_interval :timer.minutes(10)

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    :ets.new(@table_name, [:named_table, :public, :set])
    Process.send_after(self(), :cleanup, @cleanup_interval)
    {:ok, %{}}
  end

  @doc """
  Checks if an IP address is within rate limits for pattern requests.
  Returns {:ok, :allowed} or {:error, message}.
  """
  def check_rate_limit(ip_address) do
    GenServer.call(__MODULE__, {:check_rate_limit, ip_address})
  end

  @doc """
  Records a pattern request for rate limiting.
  """
  def record_request(ip_address) do
    GenServer.cast(__MODULE__, {:record_request, ip_address})
  end

  @impl true
  def handle_call({:check_rate_limit, ip_address}, _from, state) do
    now = DateTime.utc_now()
    one_minute_ago = DateTime.add(now, -60, :second)
    one_hour_ago = DateTime.add(now, -3_600, :second)

    requests = get_requests_for_ip(ip_address)

    minute_count =
      Enum.count(requests, fn {_ip, timestamp} ->
        DateTime.compare(timestamp, one_minute_ago) == :gt
      end)

    hourly_count =
      Enum.count(requests, fn {_ip, timestamp} ->
        DateTime.compare(timestamp, one_hour_ago) == :gt
      end)

    cond do
      minute_count >= @max_requests_per_minute ->
        {:reply,
         {:error, "Rate limit exceeded: maximum #{@max_requests_per_minute} requests per minute"},
         state}

      hourly_count >= @max_requests_per_hour ->
        {:reply,
         {:error, "Rate limit exceeded: maximum #{@max_requests_per_hour} requests per hour"},
         state}

      true ->
        {:reply, {:ok, :allowed}, state}
    end
  end

  @impl true
  def handle_cast({:record_request, ip_address}, state) do
    now = DateTime.utc_now()

    # Store each request with timestamp
    request_key = {ip_address, System.unique_integer([:positive, :monotonic])}
    :ets.insert(@table_name, {request_key, now})

    {:noreply, state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_old_entries()
    Process.send_after(self(), :cleanup, @cleanup_interval)
    {:noreply, state}
  end

  defp get_requests_for_ip(ip_address) do
    :ets.select(@table_name, [
      {{{ip_address, :_}, :"$1"}, [], [{{ip_address, :"$1"}}]}
    ])
  end

  defp cleanup_old_entries do
    one_hour_ago = DateTime.utc_now() |> DateTime.add(-3_600, :second)
    all_entries = :ets.tab2list(@table_name)

    old_entries =
      Enum.filter(all_entries, fn {_key, timestamp} ->
        DateTime.compare(timestamp, one_hour_ago) == :lt
      end)

    deleted_count = Enum.count(old_entries)

    Enum.each(old_entries, fn {key, _timestamp} ->
      :ets.delete(@table_name, key)
    end)

    if deleted_count > 0 do
      Logger.debug("Cleaned up #{deleted_count} old pattern rate limit entries")
    end
  end
end
