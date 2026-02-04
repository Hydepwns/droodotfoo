defmodule DroodotfooWeb.Plugs.RequestLogger do
  @moduledoc """
  Logs slow requests and adds request timing to response headers.

  Requests exceeding the configured threshold are logged as warnings,
  making it easy to identify performance bottlenecks.

  ## Configuration

      plug DroodotfooWeb.Plugs.RequestLogger,
        slow_threshold_ms: 500,
        exclude_paths: ["/health"]

  ## Options

    * `:slow_threshold_ms` - Log requests slower than this (default: 500ms)
    * `:exclude_paths` - Paths to skip logging (default: ["/health"])
    * `:log_level` - Level for slow requests (default: :warning)

  """

  @behaviour Plug

  require Logger

  @default_threshold_ms 500
  @default_exclude_paths ["/health"]

  @impl true
  def init(opts) do
    %{
      slow_threshold_ms: Keyword.get(opts, :slow_threshold_ms, @default_threshold_ms),
      exclude_paths: Keyword.get(opts, :exclude_paths, @default_exclude_paths),
      log_level: Keyword.get(opts, :log_level, :warning)
    }
  end

  @impl true
  def call(conn, opts) do
    if excluded?(conn.request_path, opts.exclude_paths) do
      conn
    else
      start_time = System.monotonic_time(:microsecond)

      Plug.Conn.register_before_send(conn, fn conn ->
        duration_us = System.monotonic_time(:microsecond) - start_time
        duration_ms = div(duration_us, 1000)

        conn =
          Plug.Conn.put_resp_header(conn, "x-request-duration-ms", Integer.to_string(duration_ms))

        if duration_ms >= opts.slow_threshold_ms do
          log_slow_request(conn, duration_ms, opts.log_level)
        end

        conn
      end)
    end
  end

  defp excluded?(path, exclude_paths) do
    Enum.any?(exclude_paths, fn excluded ->
      String.starts_with?(path, excluded)
    end)
  end

  defp log_slow_request(conn, duration_ms, level) do
    message =
      "Slow request: #{conn.method} #{conn.request_path} " <>
        "took #{duration_ms}ms (status: #{conn.status})"

    metadata = [
      method: conn.method,
      path: conn.request_path,
      status: conn.status,
      duration_ms: duration_ms,
      request_id: get_request_id(conn)
    ]

    Logger.log(level, message, metadata)
  end

  defp get_request_id(conn) do
    case Plug.Conn.get_resp_header(conn, "x-request-id") do
      [id | _] -> id
      [] -> nil
    end
  end
end
