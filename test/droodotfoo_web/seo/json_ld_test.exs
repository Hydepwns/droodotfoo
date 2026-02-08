defmodule DroodotfooWeb.SEO.JsonLDTest do
  use ExUnit.Case, async: true

  alias DroodotfooWeb.SEO.JsonLD
  alias Droodotfoo.Content.Posts.Post
  alias Droodotfoo.Projects

  describe "person_schema/0" do
    test "returns valid JSON with Person type" do
      json = JsonLD.person_schema()
      decoded = Jason.decode!(json)

      assert decoded["@context"] == "https://schema.org"
      assert decoded["@type"] == "Person"
      assert decoded["name"] == "DROO"
      assert decoded["url"] == "https://droo.foo"
    end

    test "includes social links" do
      json = JsonLD.person_schema()
      decoded = Jason.decode!(json)

      assert is_list(decoded["sameAs"])
      assert length(decoded["sameAs"]) > 0
    end
  end

  describe "website_schema/0" do
    test "returns valid JSON with WebSite type" do
      json = JsonLD.website_schema()
      decoded = Jason.decode!(json)

      assert decoded["@context"] == "https://schema.org"
      assert decoded["@type"] == "WebSite"
      assert decoded["name"] == "DROO.FOO"
      assert decoded["url"] == "https://droo.foo"
    end

    test "includes author information" do
      json = JsonLD.website_schema()
      decoded = Jason.decode!(json)

      assert decoded["author"]["@type"] == "Person"
      assert decoded["author"]["name"] == "DROO"
    end
  end

  describe "article_schema/1" do
    test "returns valid JSON with Article type" do
      post = %Post{
        title: "Test Post",
        description: "A test post description",
        slug: "test-post",
        date: ~D[2024-01-15],
        modified_time: nil,
        tags: ["elixir", "phoenix"],
        series: nil,
        series_order: nil,
        content: "",
        html: "",
        read_time: 5,
        author: nil,
        featured_image: nil,
        featured_image_alt: nil,
        pattern_style: nil
      }

      json = JsonLD.article_schema(post)
      decoded = Jason.decode!(json)

      assert decoded["@context"] == "https://schema.org"
      assert decoded["@type"] == "Article"
      assert decoded["headline"] == "Test Post"
      assert decoded["description"] == "A test post description"
    end

    test "includes proper date formatting" do
      post = %Post{
        title: "Test",
        description: "Test",
        slug: "test",
        date: ~D[2024-06-15],
        modified_time: nil,
        tags: [],
        series: nil,
        series_order: nil,
        content: "",
        html: "",
        read_time: 1,
        author: nil,
        featured_image: nil,
        featured_image_alt: nil,
        pattern_style: nil
      }

      json = JsonLD.article_schema(post)
      decoded = Jason.decode!(json)

      assert decoded["datePublished"] == "2024-06-15T00:00:00Z"
    end

    test "includes series information when present" do
      post = %Post{
        title: "Part 1",
        description: "First in series",
        slug: "part-1",
        date: ~D[2024-01-01],
        modified_time: nil,
        tags: ["series"],
        series: "My Series",
        series_order: 1,
        content: "",
        html: "",
        read_time: 3,
        author: nil,
        featured_image: nil,
        featured_image_alt: nil,
        pattern_style: nil
      }

      json = JsonLD.article_schema(post)
      decoded = Jason.decode!(json)

      assert decoded["isPartOf"]["@type"] == "CreativeWorkSeries"
      assert decoded["isPartOf"]["name"] == "My Series"
      assert decoded["isPartOf"]["position"] == 1
    end
  end

  describe "software_schema/1" do
    test "returns valid JSON with SoftwareSourceCode type" do
      project = %Projects{
        id: "test",
        name: "Test Project",
        tagline: "A test project",
        description: "Description of test project",
        tech_stack: ["Elixir", "Phoenix"],
        topics: ["web", "api"],
        github_url: "https://github.com/test/project",
        demo_url: nil,
        live_demo: false,
        status: :active,
        highlights: [],
        year: 2024,
        github_data: nil
      }

      json = JsonLD.software_schema(project)
      decoded = Jason.decode!(json)

      assert decoded["@context"] == "https://schema.org"
      assert decoded["@type"] == "SoftwareSourceCode"
      assert decoded["name"] == "Test Project"
      assert decoded["programmingLanguage"] == "Elixir"
    end
  end

  describe "breadcrumb_schema/1" do
    test "returns valid JSON with BreadcrumbList type" do
      items = [{"Home", "/"}, {"Posts", "/posts"}, {"Article", "/posts/article"}]

      json = JsonLD.breadcrumb_schema(items)
      decoded = Jason.decode!(json)

      assert decoded["@context"] == "https://schema.org"
      assert decoded["@type"] == "BreadcrumbList"
      assert length(decoded["itemListElement"]) == 3
    end

    test "includes correct positions" do
      items = [{"Home", "/"}, {"About", "/about"}]

      json = JsonLD.breadcrumb_schema(items)
      decoded = Jason.decode!(json)

      positions = Enum.map(decoded["itemListElement"], & &1["position"])
      assert positions == [1, 2]
    end
  end

  describe "organization_schema/0" do
    test "returns valid JSON with Organization type" do
      json = JsonLD.organization_schema()
      decoded = Jason.decode!(json)

      assert decoded["@context"] == "https://schema.org"
      assert decoded["@type"] == "Organization"
      assert decoded["name"] == "axol.io"
    end
  end
end
