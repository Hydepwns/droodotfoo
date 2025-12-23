defmodule Droodotfoo.RateLimiter do
  @moduledoc """
  Generic rate limiter using ETS with configurable time windows.

  ## Usage

      defmodule MyApp.ContactRateLimiter do
        use Droodotfoo.RateLimiter,
          table_name: :contact_rate_limit,
          windows: [
            {:hourly, 3_600, 3},
            {:daily, 86_400, 10}
          ],
          cleanup_interval: :timer.minutes(5),
          log_prefix: "Contact form"
      end

  ## Options

    * `:table_name` - Required. Atom for the ETS table name.
    * `:windows` - Required. List of `{name, seconds, limit}` tuples.
    * `:cleanup_interval` - Cleanup timer in milliseconds. Default: 10 minutes.
    * `:cleanup_retention` - Seconds to keep entries. Default: max window duration.
    * `:log_prefix` - Prefix for log messages. Default: "Rate limiter".
    * `:log_level` - Log level (:info or :debug). Default: :info.
    * `:record_mode` - :sync (call) or :async (cast). Default: :sync.
    * `:storage_mode` - :counter (one entry per IP) or :multi (entry per request). Default: :counter.
    * `:include_status` - Generate get_status/1 function. Default: true.
    * `:error_message` - Custom error message string, or nil for default. Default: nil.
  """

  @callback check_rate_limit(ip_address :: String.t()) ::
              {:ok, :allowed} | {:error, String.t()}

  @callback record_submission(ip_address :: String.t()) :: :ok
  @callback record_request(ip_address :: String.t()) :: :ok
  @optional_callbacks [record_submission: 1, record_request: 1]

  @callback get_status(ip_address :: String.t()) :: {:ok, map()}
  @optional_callbacks [get_status: 1]

  defmacro __using__(opts) do
    table_name = Keyword.fetch!(opts, :table_name)
    windows = Keyword.fetch!(opts, :windows)
    cleanup_interval = Keyword.get(opts, :cleanup_interval, :timer.minutes(10))
    log_prefix = Keyword.get(opts, :log_prefix, "Rate limiter")
    log_level = Keyword.get(opts, :log_level, :info)
    record_mode = Keyword.get(opts, :record_mode, :sync)
    storage_mode = Keyword.get(opts, :storage_mode, :counter)
    include_status = Keyword.get(opts, :include_status, true)
    error_message = Keyword.get(opts, :error_message)

    # Calculate max window for cleanup retention with validation
    max_window_seconds =
      case windows do
        [] ->
          86_400

        windows ->
          windows
          |> Enum.map(fn {_name, seconds, _limit} -> seconds end)
          |> Enum.filter(&is_integer/1)
          |> case do
            [] -> 86_400
            seconds -> Enum.max(seconds)
          end
      end

    cleanup_retention =
      opts
      |> Keyword.get(:cleanup_retention, max_window_seconds)
      |> then(fn val -> if is_integer(val) and val > 0, do: val, else: 86_400 end)

    # Determine record function name based on mode
    record_fn_name = if storage_mode == :multi, do: :record_request, else: :record_submission

    quote do
      @behaviour Droodotfoo.RateLimiter

      use GenServer
      require Logger

      @table_name unquote(table_name)
      @windows unquote(windows)
      @cleanup_interval unquote(cleanup_interval)
      @cleanup_retention unquote(cleanup_retention)
      @log_prefix unquote(log_prefix)
      @log_level unquote(log_level)
      @storage_mode unquote(storage_mode)
      @error_message unquote(error_message)

      def start_link(opts \\ []) do
        GenServer.start_link(__MODULE__, opts, name: __MODULE__)
      end

      @impl true
      def init(_opts) do
        :ets.new(@table_name, [:named_table, :public, :set])
        Process.send_after(self(), :cleanup, @cleanup_interval)
        {:ok, %{}}
      end

      @doc """
      Checks if an IP address is within rate limits.
      Returns {:ok, :allowed} or {:error, message}.
      """
      @impl Droodotfoo.RateLimiter
      def check_rate_limit(ip_address) do
        GenServer.call(__MODULE__, {:check_rate_limit, ip_address})
      end

      @doc """
      Records a request/submission for rate limiting.
      """
      @impl Droodotfoo.RateLimiter
      def unquote(record_fn_name)(ip_address) do
        unquote(
          if record_mode == :async do
            quote do
              GenServer.cast(__MODULE__, {:record, ip_address})
            end
          else
            quote do
              GenServer.call(__MODULE__, {:record, ip_address})
            end
          end
        )
      end

      unquote(
        if include_status do
          quote do
            @doc """
            Gets current rate limit status for an IP address.
            """
            @impl Droodotfoo.RateLimiter
            def get_status(ip_address) do
              GenServer.call(__MODULE__, {:get_status, ip_address})
            end
          end
        end
      )

      @impl true
      def handle_call({:check_rate_limit, ip_address}, _from, state) do
        now = DateTime.utc_now()
        entries = get_entries_for_ip(ip_address)

        result =
          Enum.find_value(@windows, {:ok, :allowed}, fn {name, seconds, limit} ->
            cutoff = DateTime.add(now, -seconds, :second)
            count = count_entries_after(entries, cutoff)

            if count >= limit do
              message = build_error_message(name, limit)
              {:error, message}
            else
              nil
            end
          end)

        {:reply, result, state}
      end

      unquote(
        if record_mode == :async do
          quote do
            @impl true
            def handle_cast({:record, ip_address}, state) do
              do_record(ip_address)
              {:noreply, state}
            end
          end
        else
          quote do
            @impl true
            def handle_call({:record, ip_address}, _from, state) do
              do_record(ip_address)
              {:reply, :ok, state}
            end
          end
        end
      )

      unquote(
        if include_status do
          quote do
            @impl true
            def handle_call({:get_status, ip_address}, _from, state) do
              now = DateTime.utc_now()
              entries = get_entries_for_ip(ip_address)

              window_stats =
                Enum.map(@windows, fn {name, seconds, limit} ->
                  cutoff = DateTime.add(now, -seconds, :second)
                  count = count_entries_after(entries, cutoff)
                  {name, %{count: count, limit: limit}}
                end)
                |> Map.new()

              can_submit =
                Enum.all?(@windows, fn {name, seconds, limit} ->
                  cutoff = DateTime.add(now, -seconds, :second)
                  count_entries_after(entries, cutoff) < limit
                end)

              status =
                %{
                  ip_address: ip_address,
                  windows: window_stats,
                  can_submit: can_submit
                }

              {:reply, {:ok, status}, state}
            end
          end
        end
      )

      @impl true
      def handle_info(:cleanup, state) do
        cleanup_old_entries()
        Process.send_after(self(), :cleanup, @cleanup_interval)
        {:noreply, state}
      end

      # Private helpers

      defp do_log(message) do
        case @log_level do
          :debug -> Logger.debug(message)
          :info -> Logger.info(message)
          :warning -> Logger.warning(message)
          _ -> Logger.info(message)
        end
      end

      unquote(
        if storage_mode == :multi do
          quote do
            defp do_record(ip_address) do
              now = DateTime.utc_now()
              request_key = {ip_address, System.unique_integer([:positive, :monotonic])}
              :ets.insert(@table_name, {request_key, now})
            end

            defp get_entries_for_ip(ip_address) do
              :ets.select(@table_name, [
                {{{ip_address, :_}, :"$1"}, [], [{{ip_address, :"$1"}}]}
              ])
            end

            defp count_entries_after(entries, cutoff) do
              Enum.count(entries, fn {_ip, timestamp} ->
                DateTime.compare(timestamp, cutoff) == :gt
              end)
            end

            defp cleanup_old_entries do
              cutoff = DateTime.utc_now() |> DateTime.add(-@cleanup_retention, :second)
              all_entries = :ets.tab2list(@table_name)

              old_entries =
                Enum.filter(all_entries, fn {_key, timestamp} ->
                  DateTime.compare(timestamp, cutoff) == :lt
                end)

              deleted_count = length(old_entries)

              Enum.each(old_entries, fn {key, _timestamp} ->
                :ets.delete(@table_name, key)
              end)

              if deleted_count > 0 do
                do_log("#{@log_prefix}: cleaned up #{deleted_count} old entries")
              end
            end
          end
        else
          quote do
            defp do_record(ip_address) do
              now = DateTime.utc_now()

              current_count =
                case :ets.lookup(@table_name, ip_address) do
                  [{^ip_address, count, _timestamp}] -> count
                  [] -> 0
                end

              :ets.insert(@table_name, {ip_address, current_count + 1, now})
              do_log("#{@log_prefix}: recorded for IP #{ip_address}")
            end

            defp get_entries_for_ip(ip_address) do
              :ets.select(@table_name, [
                {{:"$1", :"$2", :"$3"}, [{:"=:=", :"$1", ip_address}], [{{:"$1", :"$2", :"$3"}}]}
              ])
            end

            defp count_entries_after(entries, cutoff) do
              # In counter mode, each entry has {ip, count, timestamp}
              # We return the count if the entry is within the time window
              Enum.reduce(entries, 0, fn {_ip, count, timestamp}, acc ->
                if DateTime.compare(timestamp, cutoff) == :gt do
                  acc + count
                else
                  acc
                end
              end)
            end

            defp cleanup_old_entries do
              cutoff = DateTime.utc_now() |> DateTime.add(-@cleanup_retention, :second)
              all_entries = :ets.tab2list(@table_name)

              old_entries =
                Enum.filter(all_entries, fn {_ip_address, _count, timestamp} ->
                  DateTime.compare(timestamp, cutoff) == :lt
                end)

              deleted_count = length(old_entries)

              Enum.each(old_entries, fn {ip_address, _count, _timestamp} ->
                :ets.delete(@table_name, ip_address)
              end)

              if deleted_count > 0 do
                do_log("#{@log_prefix}: cleaned up #{deleted_count} old entries")
              end
            end
          end
        end
      )

      defp build_error_message(window_name, limit) do
        case @error_message do
          nil ->
            period =
              case window_name do
                :per_second -> "second"
                :per_minute -> "minute"
                :hourly -> "hour"
                :daily -> "day"
                other -> to_string(other)
              end

            "Rate limit exceeded: maximum #{limit} per #{period}"

          message when is_binary(message) ->
            message
        end
      end
    end
  end
end
