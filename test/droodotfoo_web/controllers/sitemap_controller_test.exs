defmodule DroodotfooWeb.SitemapControllerTest do
  use DroodotfooWeb.ConnCase

  describe "GET /sitemap.xml" do
    test "returns sitemap with correct content type", %{conn: conn} do
      conn = get(conn, "/sitemap.xml")

      assert response_content_type(conn, :xml)
      assert response(conn, 200) =~ "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
    end

    test "includes urlset namespace", %{conn: conn} do
      conn = get(conn, "/sitemap.xml")
      body = response(conn, 200)

      assert body =~ "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">"
    end

    test "includes static pages", %{conn: conn} do
      conn = get(conn, "/sitemap.xml")
      body = response(conn, 200)

      assert body =~ "<loc>https://droo.foo/</loc>"
      assert body =~ "<loc>https://droo.foo/about</loc>"
      assert body =~ "<loc>https://droo.foo/posts</loc>"
      assert body =~ "<loc>https://droo.foo/projects</loc>"
      assert body =~ "<loc>https://droo.foo/resume</loc>"
    end

    test "includes proper sitemap elements", %{conn: conn} do
      conn = get(conn, "/sitemap.xml")
      body = response(conn, 200)

      assert body =~ "<changefreq>"
      assert body =~ "<priority>"
      assert body =~ "<lastmod>"
    end
  end
end
