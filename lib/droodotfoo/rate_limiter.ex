defmodule Droodotfoo.RateLimiter do
  @moduledoc """
  Simple rate limiter using ETS sliding window.

  ## Usage

      defmodule MyApp.ContactRateLimiter do
        use Droodotfoo.RateLimiter,
          table_name: :contact_rate_limit,
          windows: [
            {:hourly, 3_600, 3},
            {:daily, 86_400, 10}
          ]
      end

  ## Options

    * `:table_name` - Required. Atom for the ETS table name.
    * `:windows` - Required. List of `{name, seconds, limit}` tuples.
    * `:error_message` - Custom error message (default: generates from window name).
    * `:log_prefix` - Prefix for log messages (default: "Rate limiter").
  """

  @callback check_rate_limit(ip :: String.t()) :: {:ok, :allowed} | {:error, String.t()}
  @callback record(ip :: String.t()) :: :ok
  @callback get_status(ip :: String.t()) :: {:ok, map()}

  defmacro __using__(opts) do
    table_name = Keyword.fetch!(opts, :table_name)
    windows = Keyword.fetch!(opts, :windows)
    error_message = Keyword.get(opts, :error_message)
    log_prefix = Keyword.get(opts, :log_prefix, "Rate limiter")

    max_window = windows |> Enum.map(fn {_, s, _} -> s end) |> Enum.max(fn -> 86_400 end)

    quote do
      @behaviour Droodotfoo.RateLimiter

      use GenServer
      require Logger

      @table unquote(table_name)
      @windows unquote(windows)
      @max_window unquote(max_window)
      @error_msg unquote(error_message)
      @log_prefix unquote(log_prefix)

      def start_link(opts \\ []), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

      @impl true
      def init(_) do
        :ets.new(@table, [:named_table, :public, :set])
        schedule_cleanup()
        {:ok, %{}}
      end

      @impl Droodotfoo.RateLimiter
      def check_rate_limit(ip), do: GenServer.call(__MODULE__, {:check, ip})

      @impl Droodotfoo.RateLimiter
      def record(ip), do: GenServer.cast(__MODULE__, {:record, ip})

      # Aliases for backward compatibility
      def record_submission(ip), do: record(ip)
      def record_request(ip), do: record(ip)

      @impl Droodotfoo.RateLimiter
      def get_status(ip), do: GenServer.call(__MODULE__, {:status, ip})

      @impl true
      def handle_call({:check, ip}, _from, state) do
        now = System.system_time(:second)
        entries = get_entries(ip)

        result =
          Enum.find_value(@windows, {:ok, :allowed}, fn {name, secs, limit} ->
            cutoff = now - secs
            count = Enum.count(entries, fn ts -> ts > cutoff end)
            if count >= limit, do: {:error, error_message(name, limit)}
          end)

        {:reply, result, state}
      end

      def handle_call({:status, ip}, _from, state) do
        now = System.system_time(:second)
        entries = get_entries(ip)

        windows =
          Map.new(@windows, fn {name, secs, limit} ->
            cutoff = now - secs
            count = Enum.count(entries, fn ts -> ts > cutoff end)
            {name, %{count: count, limit: limit}}
          end)

        can_submit =
          Enum.all?(@windows, fn {_, secs, limit} ->
            cutoff = now - secs
            Enum.count(entries, fn ts -> ts > cutoff end) < limit
          end)

        {:reply, {:ok, %{ip_address: ip, windows: windows, can_submit: can_submit}}, state}
      end

      @impl true
      def handle_cast({:record, ip}, state) do
        now = System.system_time(:second)
        key = {ip, System.unique_integer([:positive, :monotonic])}
        :ets.insert(@table, {key, now})
        {:noreply, state}
      end

      @impl true
      def handle_info(:cleanup, state) do
        cleanup()
        schedule_cleanup()
        {:noreply, state}
      end

      defp get_entries(ip) do
        :ets.select(@table, [{{{ip, :_}, :"$1"}, [], [:"$1"]}])
      end

      defp cleanup do
        cutoff = System.system_time(:second) - @max_window
        entries = :ets.tab2list(@table)
        old = Enum.filter(entries, fn {_, ts} -> ts < cutoff end)
        Enum.each(old, fn {key, _} -> :ets.delete(@table, key) end)

        if old != [] do
          Logger.debug("#{@log_prefix}: cleaned #{length(old)} entries")
        end
      end

      defp schedule_cleanup, do: Process.send_after(self(), :cleanup, :timer.minutes(5))

      defp error_message(name, limit) do
        case @error_msg do
          nil ->
            period =
              case name do
                :per_second -> "second"
                :per_minute -> "minute"
                :hourly -> "hour"
                :daily -> "day"
                other -> to_string(other)
              end

            "Rate limit exceeded: maximum #{limit} per #{period}"

          msg ->
            msg
        end
      end
    end
  end
end
