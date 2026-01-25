defmodule DroodotfooWeb.HealthControllerTest do
  use DroodotfooWeb.ConnCase

  describe "GET /health" do
    test "returns 200 with status ok", %{conn: conn} do
      conn = get(conn, ~p"/health")

      assert json_response(conn, 200)["status"] == "ok"
      assert json_response(conn, 200)["timestamp"]
    end
  end

  describe "GET /health/ready" do
    test "returns health check results", %{conn: conn} do
      conn = get(conn, ~p"/health/ready")

      response = json_response(conn, 200)
      assert response["status"] in ["ok", "degraded", "unhealthy"]
      assert is_map(response["services"])
    end

    test "includes critical service checks", %{conn: conn} do
      conn = get(conn, ~p"/health/ready")

      response = json_response(conn, 200)
      services = response["services"]

      assert Map.has_key?(services, "posts_cache")
      assert Map.has_key?(services, "pubsub")
    end

    test "includes circuit breaker status", %{conn: conn} do
      conn = get(conn, ~p"/health/ready")

      response = json_response(conn, 200)
      assert Map.has_key?(response, "circuits")
    end

    test "includes cache stats", %{conn: conn} do
      conn = get(conn, ~p"/health/ready")

      response = json_response(conn, 200)
      assert Map.has_key?(response, "caches")
    end
  end
end
