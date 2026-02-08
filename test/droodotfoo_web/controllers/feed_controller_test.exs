defmodule DroodotfooWeb.FeedControllerTest do
  use DroodotfooWeb.ConnCase

  describe "GET /feed.xml" do
    test "returns RSS feed with correct content type", %{conn: conn} do
      conn = get(conn, "/feed.xml")

      assert response_content_type(conn, :xml) =~ "application/rss+xml"
      assert response(conn, 200) =~ "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      assert response(conn, 200) =~ "<rss version=\"2.0\""
    end

    test "includes channel metadata", %{conn: conn} do
      conn = get(conn, "/feed.xml")
      body = response(conn, 200)

      assert body =~ "<title>DROO.FOO</title>"
      assert body =~ "<link>https://droo.foo</link>"
      assert body =~ "<description>"
      assert body =~ "</channel>"
    end

    test "includes posts as items", %{conn: conn} do
      conn = get(conn, "/feed.xml")
      body = response(conn, 200)

      # Should have item elements for posts
      assert body =~ "<item>"
      assert body =~ "</item>"
    end
  end
end
