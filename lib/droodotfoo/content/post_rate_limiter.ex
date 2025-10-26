defmodule Droodotfoo.Content.PostRateLimiter do
  @moduledoc """
  Rate limiting for blog post API submissions.
  Prevents spam and abuse of the /api/posts endpoint.
  """

  use GenServer
  require Logger

  @table_name :post_api_rate_limits
  @max_posts_per_hour 10
  @max_posts_per_day 50
  @cleanup_interval :timer.hours(1)

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
  Checks if an IP address is within rate limits for post creation.
  Returns {:ok, :allowed} or {:error, message}.
  """
  def check_rate_limit(ip_address) do
    GenServer.call(__MODULE__, {:check_rate_limit, ip_address})
  end

  @doc """
  Records a post submission for rate limiting.
  """
  def record_submission(ip_address) do
    GenServer.call(__MODULE__, {:record_submission, ip_address})
  end

  @doc """
  Gets current rate limit status for an IP address.
  """
  def get_status(ip_address) do
    GenServer.call(__MODULE__, {:get_status, ip_address})
  end

  @impl true
  def handle_call({:check_rate_limit, ip_address}, _from, state) do
    now = DateTime.utc_now()
    one_hour_ago = DateTime.add(now, -3_600, :second)
    one_day_ago = DateTime.add(now, -86_400, :second)

    submissions = get_submissions_for_ip(ip_address)

    hourly_count =
      Enum.count(submissions, fn {_ip, _count, timestamp} ->
        DateTime.compare(timestamp, one_hour_ago) == :gt
      end)

    daily_count =
      Enum.count(submissions, fn {_ip, _count, timestamp} ->
        DateTime.compare(timestamp, one_day_ago) == :gt
      end)

    cond do
      hourly_count >= @max_posts_per_hour ->
        {:reply, {:error, "Rate limit exceeded: maximum #{@max_posts_per_hour} posts per hour"},
         state}

      daily_count >= @max_posts_per_day ->
        {:reply, {:error, "Rate limit exceeded: maximum #{@max_posts_per_day} posts per day"},
         state}

      true ->
        {:reply, {:ok, :allowed}, state}
    end
  end

  @impl true
  def handle_call({:record_submission, ip_address}, _from, state) do
    now = DateTime.utc_now()

    current_count =
      case :ets.lookup(@table_name, ip_address) do
        [{^ip_address, count, _last_submission}] -> count
        [] -> 0
      end

    :ets.insert(@table_name, {ip_address, current_count + 1, now})
    Logger.info("Post API submission recorded for IP: #{ip_address}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:get_status, ip_address}, _from, state) do
    submissions = get_submissions_for_ip(ip_address)
    now = DateTime.utc_now()
    one_hour_ago = DateTime.add(now, -3_600, :second)
    one_day_ago = DateTime.add(now, -86_400, :second)

    hourly_count =
      Enum.count(submissions, fn {_ip, _count, timestamp} ->
        DateTime.compare(timestamp, one_hour_ago) == :gt
      end)

    daily_count =
      Enum.count(submissions, fn {_ip, _count, timestamp} ->
        DateTime.compare(timestamp, one_day_ago) == :gt
      end)

    status = %{
      ip_address: ip_address,
      hourly_submissions: hourly_count,
      daily_submissions: daily_count,
      hourly_limit: @max_posts_per_hour,
      daily_limit: @max_posts_per_day,
      can_submit: hourly_count < @max_posts_per_hour and daily_count < @max_posts_per_day
    }

    {:reply, {:ok, status}, state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_old_entries()
    Process.send_after(self(), :cleanup, @cleanup_interval)
    {:noreply, state}
  end

  defp get_submissions_for_ip(ip_address) do
    :ets.select(@table_name, [
      {{:"$1", :"$2", :"$3"}, [{:"=:=", :"$1", ip_address}], [{{:"$1", :"$2", :"$3"}}]}
    ])
  end

  defp cleanup_old_entries do
    one_day_ago = DateTime.utc_now() |> DateTime.add(-86_400, :second)
    all_entries = :ets.tab2list(@table_name)

    old_entries =
      Enum.filter(all_entries, fn {_ip_address, _count, timestamp} ->
        DateTime.compare(timestamp, one_day_ago) == :lt
      end)

    deleted_count = Enum.count(old_entries)

    Enum.each(old_entries, fn {ip_address, _count, _timestamp} ->
      :ets.delete(@table_name, ip_address)
    end)

    if deleted_count > 0 do
      Logger.info("Cleaned up #{deleted_count} old post API rate limit entries")
    end
  end
end
