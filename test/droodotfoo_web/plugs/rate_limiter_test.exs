defmodule DroodotfooWeb.Plugs.RateLimiterTest do
  use ExUnit.Case, async: false

  import Plug.Conn
  import Plug.Test

  alias DroodotfooWeb.Plugs.RateLimiter

  setup do
    # Use unique table name per test to avoid conflicts
    table_name = :"test_rate_limiter_#{System.unique_integer([:positive])}"
    {:ok, table_name: table_name}
  end

  describe "call/2" do
    test "allows requests under the limit", %{table_name: table_name} do
      opts = RateLimiter.init(limit: 5, window_ms: 60_000, table_name: table_name)
      conn = conn(:get, "/")

      result = RateLimiter.call(conn, opts)

      refute result.halted
      assert get_resp_header(result, "x-ratelimit-limit") == ["5"]
    end

    test "returns 429 when limit exceeded", %{table_name: table_name} do
      opts = RateLimiter.init(limit: 5, window_ms: 60_000, table_name: table_name)

      # Make requests up to the limit
      for _ <- 1..5 do
        conn = conn(:get, "/")
        RateLimiter.call(conn, opts)
      end

      # This request should be rate limited
      conn = conn(:get, "/")
      result = RateLimiter.call(conn, opts)

      assert result.halted
      assert result.status == 429
      assert get_resp_header(result, "x-ratelimit-remaining") == ["0"]
      assert get_resp_header(result, "retry-after") == ["60"]
    end

    test "excludes specified paths", %{table_name: table_name} do
      opts =
        RateLimiter.init(
          limit: 1,
          window_ms: 60_000,
          exclude_paths: ["/health"],
          table_name: table_name
        )

      # Exhaust limit on regular path
      conn = conn(:get, "/api")
      RateLimiter.call(conn, opts)

      # Health endpoint should still work
      conn = conn(:get, "/health")
      result = RateLimiter.call(conn, opts)

      refute result.halted
    end

    test "respects x-forwarded-for header", %{table_name: table_name} do
      opts = RateLimiter.init(limit: 2, window_ms: 60_000, table_name: table_name)

      # Requests from different IPs should have separate limits
      conn1 =
        conn(:get, "/")
        |> put_req_header("x-forwarded-for", "1.2.3.4")

      conn2 =
        conn(:get, "/")
        |> put_req_header("x-forwarded-for", "5.6.7.8")

      # Both should be allowed
      result1 = RateLimiter.call(conn1, opts)
      result2 = RateLimiter.call(conn2, opts)

      refute result1.halted
      refute result2.halted
    end
  end
end
