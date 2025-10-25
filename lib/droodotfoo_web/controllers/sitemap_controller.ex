defmodule DroodotfooWeb.SitemapController do
  @moduledoc """
  Generates XML sitemap for search engines.
  """

  use DroodotfooWeb, :controller
  alias Droodotfoo.Content.Posts

  @base_url "https://droo.foo"

  @doc """
  Generates sitemap.xml with all public pages.
  """
  def index(conn, _params) do
    xml = build_sitemap()

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, xml)
  end

  defp build_sitemap do
    static_pages = static_urls()
    post_pages = post_urls()
    project_pages = project_urls()

    all_urls = static_pages ++ post_pages ++ project_pages

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{Enum.map_join(all_urls, "\n", &build_url_entry/1)}
    </urlset>
    """
  end

  defp build_url_entry({loc, lastmod, changefreq, priority}) do
    """
      <url>
        <loc>#{@base_url}#{loc}</loc>
        <lastmod>#{lastmod}</lastmod>
        <changefreq>#{changefreq}</changefreq>
        <priority>#{priority}</priority>
      </url>
    """
  end

  defp static_urls do
    today = Date.utc_today() |> Date.to_iso8601()

    [
      {"/", today, "daily", "1.0"},
      {"/about", today, "monthly", "0.9"},
      {"/now", today, "weekly", "0.8"},
      {"/projects", today, "weekly", "0.9"},
      {"/posts", today, "weekly", "0.9"},
      {"/pattern-gallery", today, "monthly", "0.7"},
      {"/sitemap", today, "monthly", "0.6"}
    ]
  end

  defp post_urls do
    Posts.list_posts()
    |> Enum.map(fn post ->
      {
        "/posts/#{post.slug}",
        Date.to_iso8601(post.date),
        "monthly",
        "0.8"
      }
    end)
  end

  defp project_urls do
    # Projects don't have individual pages, but included in projects list
    []
  end
end
