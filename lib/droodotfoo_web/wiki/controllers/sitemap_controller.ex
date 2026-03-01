defmodule DroodotfooWeb.Wiki.SitemapController do
  @moduledoc """
  Sitemap index and per-source sitemaps for wiki.droo.foo.

  Implements the sitemap index protocol for large article counts:
  - `/sitemap.xml` - sitemap index pointing to source sitemaps
  - `/sitemaps/static` - static pages
  - `/sitemaps/{source}` - articles for each source (first page)
  - `/sitemaps/{source}/{page}` - paginated sitemaps for large sources
  """

  use DroodotfooWeb, :controller

  import Ecto.Query
  alias Droodotfoo.Repo
  alias Droodotfoo.Wiki.Content.Article

  @base_url "https://wiki.droo.foo"
  @urls_per_sitemap 10_000

  @sources [:osrs, :nlab, :wikipedia, :vintage_machinery, :wikiart]

  @source_paths %{
    osrs: "/osrs",
    nlab: "/nlab",
    wikipedia: "/wikipedia",
    vintage_machinery: "/machines",
    wikiart: "/art"
  }

  @doc "Sitemap index listing all sub-sitemaps"
  def index(conn, _params) do
    sitemaps = build_sitemap_index()

    xml = """
    <?xml version="1.0" encoding="UTF-8"?>
    <sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{Enum.map_join(sitemaps, "\n", &sitemap_entry/1)}
    </sitemapindex>
    """

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, xml)
  end

  @doc "Static pages sitemap"
  def static(conn, _params) do
    urls = [
      %{loc: "#{@base_url}/", priority: "1.0", changefreq: "daily"},
      %{loc: "#{@base_url}/search", priority: "0.8", changefreq: "daily"},
      %{loc: "#{@base_url}/parts", priority: "0.7", changefreq: "weekly"}
      | Enum.map(@sources, fn source ->
          %{loc: "#{@base_url}#{@source_paths[source]}", priority: "0.8", changefreq: "daily"}
        end)
    ]

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, build_urlset(urls))
  end

  @doc "Source-specific sitemap (with optional pagination)"
  def source(conn, %{"source" => source_str} = params) do
    source = String.to_existing_atom(source_str)
    page = String.to_integer(Map.get(params, "page", "1"))

    if source in @sources do
      urls = fetch_article_urls(source, page)

      conn
      |> put_resp_content_type("application/xml")
      |> send_resp(200, build_urlset(urls))
    else
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(404, "Unknown source")
    end
  end

  # Build sitemap index entries
  defp build_sitemap_index do
    today = Date.utc_today() |> Date.to_iso8601()

    static_entry = %{loc: "#{@base_url}/sitemaps/static", lastmod: today}

    source_entries =
      @sources
      |> Enum.flat_map(fn source ->
        count = article_count(source)
        pages = max(1, ceil(count / @urls_per_sitemap))

        if pages == 1 do
          [%{loc: "#{@base_url}/sitemaps/#{source}", lastmod: today}]
        else
          for p <- 1..pages do
            %{loc: "#{@base_url}/sitemaps/#{source}/#{p}", lastmod: today}
          end
        end
      end)

    [static_entry | source_entries]
  end

  defp sitemap_entry(%{loc: loc, lastmod: lastmod}) do
    """
      <sitemap>
        <loc>#{loc}</loc>
        <lastmod>#{lastmod}</lastmod>
      </sitemap>
    """
  end

  defp fetch_article_urls(source, page) do
    offset = (page - 1) * @urls_per_sitemap
    path = @source_paths[source]
    source_str = Atom.to_string(source)

    from(a in Article,
      where: a.source == ^source_str,
      order_by: [desc: a.synced_at],
      offset: ^offset,
      limit: @urls_per_sitemap,
      select: %{slug: a.slug, synced_at: a.synced_at}
    )
    |> Repo.all()
    |> Enum.map(fn %{slug: slug, synced_at: synced_at} ->
      %{
        loc: "#{@base_url}#{path}/#{slug}",
        lastmod: format_date(synced_at),
        priority: "0.6",
        changefreq: "weekly"
      }
    end)
  end

  defp article_count(source) do
    source_str = Atom.to_string(source)

    from(a in Article, where: a.source == ^source_str, select: count(a.id))
    |> Repo.one()
  end

  defp build_urlset(urls) do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{Enum.map_join(urls, "\n", &url_entry/1)}
    </urlset>
    """
  end

  defp url_entry(url) do
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
  defp format_date(%DateTime{} = dt), do: Calendar.strftime(dt, "%Y-%m-%d")
end
