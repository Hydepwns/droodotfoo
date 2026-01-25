defmodule DroodotfooWeb.Plugs.RateLimiter do
  @moduledoc """
  Global IP-based rate limiter plug using ETS for fast lookups.

  Implements a sliding window counter to limit requests per IP address.
  Designed to be placed early in the endpoint pipeline for broad protection.

  ## Configuration

  Configure in your endpoint or router:

      plug DroodotfooWeb.Plugs.RateLimiter,
        limit: 200,
        window_ms: 60_000,
        exclude_paths: ["/health", "/metrics"]

  ## Options

    * `:limit` - Maximum requests per window (default: 200)
    * `:window_ms` - Time window in milliseconds (default: 60_000 / 1 minute)
    * `:exclude_paths` - List of paths to skip rate limiting (default: [])
    * `:table_name` - ETS table name (default: :global_rate_limiter)

  """

  @behaviour Plug

  import Plug.Conn
  require Logger

  @default_limit 200
  @default_window_ms 60_000
  @default_table :global_rate_limiter
  @cleanup_interval :timer.minutes(5)

  @impl true
  def init(opts) do
    table_name = Keyword.get(opts, :table_name, @default_table)
    ensure_table_exists(table_name)
    schedule_cleanup(table_name)

    %{
      limit: Keyword.get(opts, :limit, @default_limit),
      window_ms: Keyword.get(opts, :window_ms, @default_window_ms),
      exclude_paths: Keyword.get(opts, :exclude_paths, []),
      table_name: table_name
    }
  end

  @impl true
  def call(conn, opts) do
    if excluded?(conn.request_path, opts.exclude_paths) do
      conn
    else
      check_rate_limit(conn, opts)
    end
  end

  defp check_rate_limit(conn, opts) do
    ip = get_client_ip(conn)
    now = System.monotonic_time(:millisecond)
    window_start = now - opts.window_ms

    case increment_and_check(opts.table_name, ip, now, window_start, opts.limit) do
      {:ok, count} ->
        conn
        |> put_resp_header("x-ratelimit-limit", Integer.to_string(opts.limit))
        |> put_resp_header("x-ratelimit-remaining", Integer.to_string(max(0, opts.limit - count)))

      {:error, :rate_limited} ->
        Logger.warning("Rate limit exceeded for IP: #{ip}")

        conn
        |> put_resp_header("x-ratelimit-limit", Integer.to_string(opts.limit))
        |> put_resp_header("x-ratelimit-remaining", "0")
        |> put_resp_header("retry-after", Integer.to_string(div(opts.window_ms, 1000)))
        |> put_resp_content_type("text/plain")
        |> send_resp(429, "Too Many Requests")
        |> halt()
    end
  end

  defp increment_and_check(table, ip, now, window_start, limit) do
    # Store each request with a unique key
    request_id = System.unique_integer([:positive, :monotonic])
    key = {ip, request_id}

    try do
      :ets.insert(table, {key, now})

      # Count requests in current window for this IP
      # Pattern: {{ip, _request_id}, timestamp} where timestamp >= window_start
      total =
        :ets.select_count(table, [
          {{{ip, :_}, :"$1"}, [{:>=, :"$1", window_start}], [true]}
        ])

      if total > limit do
        {:error, :rate_limited}
      else
        {:ok, total}
      end
    rescue
      ArgumentError ->
        # Table might not exist yet in race condition
        ensure_table_exists(table)
        {:ok, 1}
    end
  end

  defp get_client_ip(conn) do
    # Check for forwarded headers (Fly.io, Cloudflare, etc.)
    forwarded_for =
      conn
      |> get_req_header("x-forwarded-for")
      |> List.first()

    case forwarded_for do
      nil ->
        conn.remote_ip |> :inet.ntoa() |> to_string()

      header ->
        header
        |> String.split(",")
        |> List.first()
        |> String.trim()
    end
  end

  defp excluded?(path, exclude_paths) do
    Enum.any?(exclude_paths, fn excluded ->
      String.starts_with?(path, excluded)
    end)
  end

  defp ensure_table_exists(table_name) do
    case :ets.whereis(table_name) do
      :undefined ->
        try do
          :ets.new(table_name, [:named_table, :public, :set, {:write_concurrency, true}])
        rescue
          ArgumentError -> :ok
        end

      _ ->
        :ok
    end
  end

  defp schedule_cleanup(table_name) do
    # Spawn a process to handle cleanup
    spawn(fn -> cleanup_loop(table_name) end)
  end

  defp cleanup_loop(table_name) do
    Process.sleep(@cleanup_interval)
    cleanup_old_entries(table_name)
    cleanup_loop(table_name)
  end

  defp cleanup_old_entries(table_name) do
    # Remove entries older than 5 minutes
    cutoff = System.monotonic_time(:millisecond) - :timer.minutes(5)

    case :ets.whereis(table_name) do
      :undefined ->
        :ok

      _ ->
        # Pattern: {{ip, request_id}, timestamp} where timestamp < cutoff
        old_keys =
          :ets.select(table_name, [
            {{:"$1", :"$2"}, [{:<, :"$2", cutoff}], [:"$1"]}
          ])

        Enum.each(old_keys, fn key -> :ets.delete(table_name, key) end)

        if length(old_keys) > 0 do
          Logger.debug("Global rate limiter: cleaned up #{length(old_keys)} old entries")
        end
    end
  end
end
