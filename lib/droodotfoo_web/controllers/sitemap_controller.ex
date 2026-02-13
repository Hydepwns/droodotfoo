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
    # Use latest post date for content-driven pages, fixed dates for static pages
    # This provides accurate signals to search engines about actual content updates
    latest_post_date = get_latest_post_date()

    [
      # Dynamic: changes when new posts are published
      {"/", latest_post_date, "daily", "1.0"},
      {"/posts", latest_post_date, "weekly", "0.9"},
      {"/feed.xml", latest_post_date, "daily", "0.8"},
      # Semi-dynamic: projects may update periodically
      {"/projects", latest_post_date, "weekly", "0.9"},
      # Dynamic: "now" page updates weekly by design
      {"/now", latest_post_date, "weekly", "0.8"},
      # Static: rarely change, use fixed dates
      {"/about", "2025-01-01", "monthly", "0.9"},
      {"/resume", "2025-01-01", "monthly", "0.9"},
      {"/contact", "2025-01-01", "monthly", "0.7"},
      {"/pattern-gallery", "2025-01-01", "monthly", "0.7"},
      {"/sitemap", "2025-01-01", "monthly", "0.6"}
    ]
  end

  defp get_latest_post_date do
    case Posts.list_posts() do
      [latest | _] -> Date.to_iso8601(latest.date)
      [] -> Date.utc_today() |> Date.to_iso8601()
    end
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
