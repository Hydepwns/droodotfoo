defmodule DroodotfooWeb.Plugs.RequestLoggerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  import Plug.Conn
  import Plug.Test

  alias DroodotfooWeb.Plugs.RequestLogger

  describe "call/2" do
    test "adds x-request-duration-ms header" do
      opts = RequestLogger.init(slow_threshold_ms: 10_000)
      conn = conn(:get, "/test")

      # Simulate the response being sent
      conn =
        conn
        |> RequestLogger.call(opts)
        |> send_resp(200, "ok")

      assert [duration] = get_resp_header(conn, "x-request-duration-ms")
      assert String.to_integer(duration) >= 0
    end

    test "logs slow requests" do
      opts = RequestLogger.init(slow_threshold_ms: 0)

      log =
        capture_log(fn ->
          conn(:get, "/slow-endpoint")
          |> RequestLogger.call(opts)
          |> send_resp(200, "ok")
        end)

      assert log =~ "Slow request"
      assert log =~ "/slow-endpoint"
    end

    test "excludes specified paths" do
      opts = RequestLogger.init(slow_threshold_ms: 0, exclude_paths: ["/health"])

      log =
        capture_log(fn ->
          conn(:get, "/health")
          |> RequestLogger.call(opts)
          |> send_resp(200, "ok")
        end)

      refute log =~ "Slow request"
    end
  end
end
