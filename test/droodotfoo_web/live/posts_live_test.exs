defmodule DroodotfooWeb.PostsLiveTest do
  use DroodotfooWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  describe "GET /posts" do
    test "renders posts listing page", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/posts")

      assert html =~ "Writing"
      assert html =~ "Notes on building things"
    end

    test "displays post titles as links", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/posts")

      # Should contain links to posts
      assert html =~ ~r/<a[^>]*href="\/posts\/[^"]+"/
    end

    test "shows post metadata (date, read time)", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/posts")

      # Posts should show date and read time (format: "X min read")
      assert html =~ ~r/\d+ min read/
    end

    test "displays post tags", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/posts")

      # Should have tag elements
      assert html =~ "tech-tag"
    end

    test "includes pattern images for posts", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/posts")

      # Posts should have pattern images
      assert html =~ ~r/<object[^>]*data="\/patterns\//
      assert html =~ "image/svg+xml"
    end
  end
end
