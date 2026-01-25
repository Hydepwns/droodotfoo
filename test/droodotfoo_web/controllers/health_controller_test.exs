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
      assert response["status"] in ["ok", "degraded"]
      assert is_map(response["checks"])
    end

    test "includes critical service checks", %{conn: conn} do
      conn = get(conn, ~p"/health/ready")

      response = json_response(conn, 200)
      checks = response["checks"]

      assert Map.has_key?(checks, "posts_cache")
      assert Map.has_key?(checks, "pubsub")
    end
  end
end
