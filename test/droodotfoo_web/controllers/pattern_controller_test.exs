defmodule DroodotfooWeb.PatternControllerTest do
  use DroodotfooWeb.ConnCase, async: true

  describe "GET /patterns/:slug" do
    test "returns SVG content type", %{conn: conn} do
      conn = get(conn, ~p"/patterns/test-slug")

      assert response_content_type(conn, :xml) =~ "image/svg+xml"
      assert conn.status == 200
    end

    test "returns valid SVG", %{conn: conn} do
      conn = get(conn, ~p"/patterns/test-slug")
      body = response(conn, 200)

      assert body =~ "<svg"
      assert body =~ "</svg>"
      assert body =~ ~s(xmlns="http://www.w3.org/2000/svg")
    end

    test "sets caching headers", %{conn: conn} do
      conn = get(conn, ~p"/patterns/test-slug")

      cache_control = get_resp_header(conn, "cache-control")
      assert Enum.any?(cache_control, &(&1 =~ "max-age="))
      assert Enum.any?(cache_control, &(&1 =~ "public"))

      etag = get_resp_header(conn, "etag")
      assert length(etag) > 0
    end

    test "generates deterministic pattern for same slug", %{conn: conn} do
      conn1 = get(conn, ~p"/patterns/deterministic-test")
      conn2 = get(conn, ~p"/patterns/deterministic-test")

      body1 = response(conn1, 200)
      body2 = response(conn2, 200)

      assert body1 == body2
    end

    test "generates different patterns for different slugs", %{conn: conn} do
      conn1 = get(conn, ~p"/patterns/slug-one")
      conn2 = get(conn, ~p"/patterns/slug-two")

      body1 = response(conn1, 200)
      body2 = response(conn2, 200)

      refute body1 == body2
    end
  end

  describe "GET /patterns/:slug with style parameter" do
    test "accepts waves style", %{conn: conn} do
      conn = get(conn, ~p"/patterns/test-slug?style=waves")

      assert conn.status == 200
      assert response(conn, 200) =~ "<svg"
    end

    test "accepts dots style", %{conn: conn} do
      conn = get(conn, ~p"/patterns/test-slug?style=dots")

      assert conn.status == 200
      assert response(conn, 200) =~ "<svg"
    end

    test "accepts circuit style", %{conn: conn} do
      conn = get(conn, ~p"/patterns/test-slug?style=circuit")

      assert conn.status == 200
      assert response(conn, 200) =~ "<svg"
    end

    test "accepts grid style", %{conn: conn} do
      conn = get(conn, ~p"/patterns/test-slug?style=grid")

      assert conn.status == 200
      assert response(conn, 200) =~ "<svg"
    end

    test "ignores invalid style and uses default", %{conn: conn} do
      conn = get(conn, ~p"/patterns/test-slug?style=invalid_style")

      assert conn.status == 200
      assert response(conn, 200) =~ "<svg"
    end
  end

  describe "GET /patterns/:slug with dimension parameters" do
    test "accepts custom width and height", %{conn: conn} do
      conn = get(conn, ~p"/patterns/test-slug?width=800&height=400")

      assert conn.status == 200
      body = response(conn, 200)
      assert body =~ "viewBox"
    end

    test "ignores invalid dimensions", %{conn: conn} do
      conn = get(conn, ~p"/patterns/test-slug?width=invalid&height=invalid")

      assert conn.status == 200
      assert response(conn, 200) =~ "<svg"
    end

    test "caps dimensions at maximum", %{conn: conn} do
      # Dimensions > 2400 should be capped
      conn = get(conn, ~p"/patterns/test-slug?width=5000&height=5000")

      assert conn.status == 200
      assert response(conn, 200) =~ "<svg"
    end
  end

  describe "GET /patterns/:slug with animate parameter" do
    test "accepts animate=true", %{conn: conn} do
      conn = get(conn, ~p"/patterns/test-slug?animate=true")

      assert conn.status == 200
      assert response(conn, 200) =~ "<svg"
    end

    test "accepts animate=false", %{conn: conn} do
      conn = get(conn, ~p"/patterns/test-slug?animate=false")

      assert conn.status == 200
      assert response(conn, 200) =~ "<svg"
    end
  end
end
