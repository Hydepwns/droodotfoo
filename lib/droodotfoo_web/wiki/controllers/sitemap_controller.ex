defmodule DroodotfooWeb.Wiki.SitemapController do
  @moduledoc """
  Sitemap.xml generation for wiki.droo.foo.
  Includes source indexes and recent articles from each source.
  """

  use DroodotfooWeb, :controller

  alias Droodotfoo.Wiki.Content

  @sources [:osrs, :nlab, :wikipedia, :vintage_machinery, :wikiart]

  @source_paths %{
    osrs: "/osrs",
    nlab: "/nlab",
    wikipedia: "/wikipedia",
    vintage_machinery: "/machines",
    wikiart: "/art"
  }

  @doc """
  Generates sitemap.xml for the wiki subdomain.
  """
  def index(conn, _params) do
    urls = build_sitemap_urls()

    xml = build_sitemap_xml(urls)

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, xml)
  end

  defp build_sitemap_urls do
    static_urls() ++ source_index_urls() ++ article_urls()
  end

  defp static_urls do
    [
      %{loc: "https://wiki.droo.foo/", priority: "1.0", changefreq: "daily"},
      %{loc: "https://wiki.droo.foo/search", priority: "0.8", changefreq: "daily"},
      %{loc: "https://wiki.droo.foo/parts", priority: "0.7", changefreq: "weekly"}
    ]
  end

  defp source_index_urls do
    Enum.map(@sources, fn source ->
      path = @source_paths[source]

      %{
        loc: "https://wiki.droo.foo#{path}",
        priority: "0.8",
        changefreq: "daily"
      }
    end)
  end

  defp article_urls do
    @sources
    |> Enum.flat_map(fn source ->
      articles = Content.list_articles(source, limit: 100, order_by: :updated_at)
      path = @source_paths[source]

      Enum.map(articles, fn article ->
        %{
          loc: "https://wiki.droo.foo#{path}/#{article.slug}",
          lastmod: format_date(article.synced_at),
          priority: "0.6",
          changefreq: "weekly"
        }
      end)
    end)
  end

  defp build_sitemap_xml(urls) do
    url_entries = Enum.map_join(urls, "\n", &build_url_entry/1)

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{url_entries}
    </urlset>
    """
  end

  defp build_url_entry(url) do
    lastmod = if url[:lastmod], do: "\n    <lastmod>#{url[:lastmod]}</lastmod>", else: ""

    """
      <url>
        <loc>#{url.loc}</loc>#{lastmod}
        <changefreq>#{url.changefreq}</changefreq>
        <priority>#{url.priority}</priority>
      </url>
    """
  end

  defp format_date(nil), do: nil

  defp format_date(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d")
  end
end
