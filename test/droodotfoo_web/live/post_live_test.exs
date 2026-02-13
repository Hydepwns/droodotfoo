defmodule DroodotfooWeb.PostLiveTest do
  use DroodotfooWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  alias Droodotfoo.Content.Posts

  describe "GET /posts/:slug with valid post" do
    setup do
      # Get an existing post for testing
      posts = Posts.list_posts()
      post = List.first(posts)
      {:ok, post: post}
    end

    test "renders post content", %{conn: conn, post: post} do
      {:ok, _view, html} = live(conn, ~p"/posts/#{post.slug}")

      assert html =~ post.title
    end

    test "displays post metadata", %{conn: conn, post: post} do
      {:ok, _view, html} = live(conn, ~p"/posts/#{post.slug}")

      # Should show date
      assert html =~ Date.to_string(post.date)
      # Should show read time (format: "X min")
      assert html =~ ~r/\d+ min/
    end

    test "includes reading progress bar", %{conn: conn, post: post} do
      {:ok, _view, html} = live(conn, ~p"/posts/#{post.slug}")

      assert html =~ "reading-progress"
      assert html =~ "ReadingProgressHook"
    end

    test "includes back navigation", %{conn: conn, post: post} do
      {:ok, _view, html} = live(conn, ~p"/posts/#{post.slug}")

      assert html =~ "back-link"
    end

    test "renders post HTML content", %{conn: conn, post: post} do
      {:ok, _view, html} = live(conn, ~p"/posts/#{post.slug}")

      # Post content should be rendered (article element)
      assert html =~ "<article"
      assert html =~ "post-content"
    end
  end

  describe "GET /posts/:slug with invalid slug" do
    test "redirects to home with flash for non-existent post", %{conn: conn} do
      {:error, {:live_redirect, %{to: "/", flash: flash}}} =
        live(conn, ~p"/posts/non-existent-post-slug-12345")

      assert flash["error"] == "Post not found"
    end
  end

  describe "page metadata" do
    setup do
      posts = Posts.list_posts()
      post = List.first(posts)
      {:ok, post: post}
    end

    test "sets correct page title", %{conn: conn, post: post} do
      {:ok, _view, html} = live(conn, ~p"/posts/#{post.slug}")

      # Title element contains the post title
      assert html =~ ~r/<title[^>]*>/
      assert html =~ post.title
    end
  end
end
