defmodule Droodotfoo.Contact.RateLimiter do
  @moduledoc """
  Rate limiting module for contact form submissions.
  """

  use GenServer
  require Logger
  alias Droodotfoo.Forms.Constants

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_opts) do
    # Initialize ETS table for rate limiting
    :ets.new(Constants.rate_limit_table_name(), [:named_table, :public, :set])
    # Start cleanup timer
    Process.send_after(self(), :cleanup, Constants.rate_limit_cleanup_interval())
    {:ok, %{}}
  end

  @doc """
  Checks if an IP address is within rate limits.
  """
  def check_rate_limit(ip_address) do
    GenServer.call(__MODULE__, {:check_rate_limit, ip_address})
  end

  @doc """
  Records a form submission for rate limiting.
  """
  def record_submission(ip_address) do
    GenServer.call(__MODULE__, {:record_submission, ip_address})
  end

  @doc """
  Gets current rate limit status for an IP.
  """
  def get_status(ip_address) do
    GenServer.call(__MODULE__, {:get_status, ip_address})
  end

  def handle_call({:check_rate_limit, ip_address}, _from, state) do
    now = DateTime.utc_now()
    one_hour_ago = DateTime.add(now, -3_600, :second)
    one_day_ago = DateTime.add(now, -86_400, :second)
    submissions = get_submissions_for_ip(ip_address)
    # Filter submissions by time windows
    hourly_submissions =
      Enum.filter(submissions, fn {_ip, _count, timestamp} ->
        DateTime.compare(timestamp, one_hour_ago) == :gt
      end)

    daily_submissions =
      Enum.filter(submissions, fn {_ip, _count, timestamp} ->
        DateTime.compare(timestamp, one_day_ago) == :gt
      end)

    hourly_count = length(hourly_submissions)
    daily_count = length(daily_submissions)

    cond do
      hourly_count >= Constants.max_submissions_per_hour() ->
        {:reply, {:error, Constants.get_error_message(:rate_limited)}, state}

      daily_count >= Constants.max_submissions_per_day() ->
        {:reply, {:error, Constants.get_error_message(:rate_limited)}, state}

      true ->
        {:reply, {:ok, :allowed}, state}
    end
  end

  def handle_call({:record_submission, ip_address}, _from, state) do
    now = DateTime.utc_now()
    # Get current count for this IP
    current_count =
      case :ets.lookup(Constants.rate_limit_table_name(), ip_address) do
        [{^ip_address, count, _last_submission}] -> count
        [] -> 0
      end

    # Record the submission
    :ets.insert(Constants.rate_limit_table_name(), {ip_address, current_count + 1, now})
    Logger.info("Contact form submission recorded for IP: #{ip_address}")
    {:reply, :ok, state}
  end

  def handle_call({:get_status, ip_address}, _from, state) do
    submissions = get_submissions_for_ip(ip_address)
    now = DateTime.utc_now()
    one_hour_ago = DateTime.add(now, -3_600, :second)
    one_day_ago = DateTime.add(now, -86_400, :second)

    hourly_submissions =
      Enum.filter(submissions, fn {_ip, _count, timestamp} ->
        DateTime.compare(timestamp, one_hour_ago) == :gt
      end)

    daily_submissions =
      Enum.filter(submissions, fn {_ip, _count, timestamp} ->
        DateTime.compare(timestamp, one_day_ago) == :gt
      end)

    status = %{
      ip_address: ip_address,
      hourly_submissions: length(hourly_submissions),
      daily_submissions: length(daily_submissions),
      hourly_limit: Constants.max_submissions_per_hour(),
      daily_limit: Constants.max_submissions_per_day(),
      can_submit:
        length(hourly_submissions) < Constants.max_submissions_per_hour() and
          length(daily_submissions) < Constants.max_submissions_per_day()
    }

    {:reply, {:ok, status}, state}
  end

  def handle_info(:cleanup, state) do
    cleanup_old_entries()
    Process.send_after(self(), :cleanup, Constants.rate_limit_cleanup_interval())
    {:noreply, state}
  end

  defp get_submissions_for_ip(ip_address) do
    :ets.select(Constants.rate_limit_table_name(), [
      {{:"$1", :"$2", :"$3"}, [{:"=:=", :"$1", ip_address}], [{{:"$1", :"$2", :"$3"}}]}
    ])
  end

  defp cleanup_old_entries do
    one_hour_ago = DateTime.utc_now() |> DateTime.add(-3_600, :second)

    # Get all entries and filter by timestamp
    all_entries = :ets.tab2list(Constants.rate_limit_table_name())

    old_entries =
      Enum.filter(all_entries, fn {_ip_address, _count, timestamp} ->
        DateTime.compare(timestamp, one_hour_ago) == :lt
      end)

    # Remove old entries
    deleted_count = Enum.count(old_entries)

    Enum.each(old_entries, fn {ip_address, _count, _timestamp} ->
      :ets.delete(Constants.rate_limit_table_name(), ip_address)
    end)

    if deleted_count > 0 do
      Logger.info("Cleaned up #{deleted_count} old rate limit entries")
    end
  end
end
