defmodule Droodotfoo.Content.PostsTest do
  use ExUnit.Case, async: false

  alias Droodotfoo.Content.Posts
  alias Droodotfoo.Content.Posts.Post

  setup do
    # Start the Posts GenServer if not already started
    case GenServer.whereis(Posts) do
      nil -> {:ok, _} = start_supervised(Posts)
      _pid -> :ok
    end

    :ok
  end

  describe "get_series_posts/1" do
    test "returns posts in a series sorted by series_order" do
      # Create test posts using save_post
      {:ok, _post1} =
        Posts.save_post("Test content 1", %{
          "slug" => "test-series-part-1",
          "title" => "Part 1",
          "date" => "2025-01-01",
          "description" => "First part",
          "tags" => [],
          "series" => "test-series",
          "series_order" => 1
        })

      {:ok, _post2} =
        Posts.save_post("Test content 2", %{
          "slug" => "test-series-part-2",
          "title" => "Part 2",
          "date" => "2025-01-02",
          "description" => "Second part",
          "tags" => [],
          "series" => "test-series",
          "series_order" => 2
        })

      {:ok, _post3} =
        Posts.save_post("Test content 3", %{
          "slug" => "test-series-part-3",
          "title" => "Part 3",
          "date" => "2025-01-03",
          "description" => "Third part",
          "tags" => [],
          "series" => "test-series",
          "series_order" => 3
        })

      # Get series posts
      series_posts = Posts.get_series_posts("test-series")

      # Verify order
      assert length(series_posts) == 3
      assert Enum.at(series_posts, 0).slug == "test-series-part-1"
      assert Enum.at(series_posts, 1).slug == "test-series-part-2"
      assert Enum.at(series_posts, 2).slug == "test-series-part-3"

      # Cleanup files created by save_post
      File.rm("priv/posts/test-series-part-1.md")
      File.rm("priv/posts/test-series-part-2.md")
      File.rm("priv/posts/test-series-part-3.md")
    end

    test "returns empty list for non-existent series" do
      series_posts = Posts.get_series_posts("non-existent-series")
      assert series_posts == []
    end

    test "handles posts with missing series_order" do
      {:ok, _post_with_order} =
        Posts.save_post("Content with order", %{
          "slug" => "test-mixed-ordered",
          "title" => "Ordered Post",
          "date" => "2025-01-01",
          "description" => "Has order",
          "tags" => [],
          "series" => "mixed-series",
          "series_order" => 1
        })

      {:ok, _post_without_order} =
        Posts.save_post("Content without order", %{
          "slug" => "test-mixed-unordered",
          "title" => "Unordered Post",
          "date" => "2025-01-02",
          "description" => "No order",
          "tags" => [],
          "series" => "mixed-series"
          # No series_order field
        })

      series_posts = Posts.get_series_posts("mixed-series")

      # Post with order comes first, unordered comes last (defaults to 999)
      assert length(series_posts) == 2
      assert Enum.at(series_posts, 0).slug == "test-mixed-ordered"
      assert Enum.at(series_posts, 1).slug == "test-mixed-unordered"

      # Cleanup
      File.rm("priv/posts/test-mixed-ordered.md")
      File.rm("priv/posts/test-mixed-unordered.md")
    end

    test "filters out posts from different series" do
      {:ok, _series_a} =
        Posts.save_post("Content for series A", %{
          "slug" => "test-filter-series-a",
          "title" => "Series A",
          "date" => "2025-01-01",
          "description" => "Part of series A",
          "tags" => [],
          "series" => "series-a",
          "series_order" => 1
        })

      {:ok, _series_b} =
        Posts.save_post("Content for series B", %{
          "slug" => "test-filter-series-b",
          "title" => "Series B",
          "date" => "2025-01-02",
          "description" => "Part of series B",
          "tags" => [],
          "series" => "series-b",
          "series_order" => 1
        })

      series_a_posts = Posts.get_series_posts("series-a")
      series_b_posts = Posts.get_series_posts("series-b")

      assert length(series_a_posts) == 1
      assert Enum.at(series_a_posts, 0).slug == "test-filter-series-a"

      assert length(series_b_posts) == 1
      assert Enum.at(series_b_posts, 0).slug == "test-filter-series-b"

      # Cleanup
      File.rm("priv/posts/test-filter-series-a.md")
      File.rm("priv/posts/test-filter-series-b.md")
    end
  end

  describe "social_image_url/1" do
    test "returns featured_image when present" do
      post = %Post{
        slug: "test-post",
        title: "Test",
        date: ~D[2025-01-01],
        description: "",
        tags: [],
        featured_image: "/images/custom-image.png",
        content: "",
        html: "",
        read_time: 1
      }

      assert Posts.social_image_url(post) == "/images/custom-image.png"
    end

    test "returns pattern URL with style when pattern_style is present" do
      post = %Post{
        slug: "test-post",
        title: "Test",
        date: ~D[2025-01-01],
        description: "",
        tags: [],
        pattern_style: "geometric",
        content: "",
        html: "",
        read_time: 1
      }

      assert Posts.social_image_url(post) == "/patterns/test-post?style=geometric"
    end

    test "returns basic pattern URL when no featured_image or pattern_style" do
      post = %Post{
        slug: "test-post",
        title: "Test",
        date: ~D[2025-01-01],
        description: "",
        tags: [],
        content: "",
        html: "",
        read_time: 1
      }

      assert Posts.social_image_url(post) == "/patterns/test-post"
    end

    test "prioritizes featured_image over pattern_style" do
      post = %Post{
        slug: "test-post",
        title: "Test",
        date: ~D[2025-01-01],
        description: "",
        tags: [],
        featured_image: "/images/custom.png",
        pattern_style: "geometric",
        content: "",
        html: "",
        read_time: 1
      }

      assert Posts.social_image_url(post) == "/images/custom.png"
    end
  end

  describe "social_image_alt/1" do
    test "returns featured_image_alt when present" do
      post = %Post{
        slug: "test-post",
        title: "Test Post",
        date: ~D[2025-01-01],
        description: "",
        tags: [],
        featured_image_alt: "Custom alt text",
        content: "",
        html: "",
        read_time: 1
      }

      assert Posts.social_image_alt(post) == "Custom alt text"
    end

    test "generates alt text from title when featured_image_alt is nil" do
      post = %Post{
        slug: "test-post",
        title: "My Blog Post",
        date: ~D[2025-01-01],
        description: "",
        tags: [],
        content: "",
        html: "",
        read_time: 1
      }

      assert Posts.social_image_alt(post) == "Visual pattern for: My Blog Post"
    end

    test "generates alt text from title when featured_image_alt is empty" do
      post = %Post{
        slug: "test-post",
        title: "Another Post",
        date: ~D[2025-01-01],
        description: "",
        tags: [],
        featured_image_alt: "",
        content: "",
        html: "",
        read_time: 1
      }

      assert Posts.social_image_alt(post) == "Visual pattern for: Another Post"
    end
  end
end
