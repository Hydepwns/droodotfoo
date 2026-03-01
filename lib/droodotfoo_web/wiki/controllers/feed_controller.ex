defmodule DroodotfooWeb.Wiki.FeedController do
  @moduledoc """
  RSS feeds for wiki sources.
  """

  use DroodotfooWeb, :controller

  alias Droodotfoo.Wiki.Content

  @sources [:osrs, :nlab, :wikipedia, :vintage_machinery, :wikiart]

  @source_labels %{
    osrs: "OSRS Wiki",
    nlab: "nLab",
    wikipedia: "Wikipedia",
    vintage_machinery: "Vintage Machinery",
    wikiart: "WikiArt"
  }

  @doc """
  Combined RSS feed for all wiki sources.
  """
  def index(conn, _params) do
    articles = fetch_all_recent_articles(50)
    last_build_date = get_last_build_date(articles)

    xml = build_rss_xml("WIKI.DROO.FOO", "Federated wiki mirror", articles, last_build_date)

    conn
    |> put_resp_content_type("application/rss+xml")
    |> send_resp(200, xml)
  end

  @doc """
  RSS feed for a specific wiki source.
  """
  def source(conn, %{"source" => source_str}) do
    source = parse_source(source_str)

    if source && source in @sources do
      articles = Content.list_articles(source, limit: 50, order_by: :updated_at)
      last_build_date = get_last_build_date(articles)
      title = "#{@source_labels[source]} | WIKI.DROO.FOO"
      description = "Recent articles from #{@source_labels[source]}"

      xml = build_rss_xml(title, description, articles, last_build_date)

      conn
      |> put_resp_content_type("application/rss+xml")
      |> send_resp(200, xml)
    else
      conn
      |> put_status(:not_found)
      |> text("Source not found")
    end
  end

  defp fetch_all_recent_articles(limit) do
    @sources
    |> Enum.flat_map(fn source ->
      Content.list_articles(source, limit: 10, order_by: :updated_at)
    end)
    |> Enum.sort_by(& &1.synced_at, {:desc, DateTime})
    |> Enum.take(limit)
  end

  defp get_last_build_date([]), do: DateTime.utc_now()
  defp get_last_build_date([first | _]), do: first.synced_at || DateTime.utc_now()

  defp build_rss_xml(title, description, articles, last_build_date) do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
      <channel>
        <title>#{escape_xml(title)}</title>
        <link>https://wiki.droo.foo</link>
        <description>#{escape_xml(description)}</description>
        <language>en-us</language>
        <lastBuildDate>#{format_rfc822(last_build_date)}</lastBuildDate>
        <atom:link href="https://wiki.droo.foo/feed.xml" rel="self" type="application/rss+xml"/>
    #{Enum.map_join(articles, "\n", &build_item/1)}
      </channel>
    </rss>
    """
  end

  defp build_item(article) do
    url = article_url(article)
    description = truncate_text(article.extracted_text || article.title, 300)

    """
        <item>
          <title>#{escape_xml(article.title)}</title>
          <link>#{url}</link>
          <guid>#{url}</guid>
          <pubDate>#{format_rfc822(article.synced_at)}</pubDate>
          <description>#{escape_xml(description)}</description>
          <category>#{escape_xml(@source_labels[article.source] || to_string(article.source))}</category>
        </item>
    """
  end

  defp article_url(article) do
    path = source_path(article.source)
    "https://wiki.droo.foo#{path}/#{article.slug}"
  end

  defp source_path(:osrs), do: "/osrs"
  defp source_path(:nlab), do: "/nlab"
  defp source_path(:wikipedia), do: "/wikipedia"
  defp source_path(:vintage_machinery), do: "/machines"
  defp source_path(:wikiart), do: "/art"
  defp source_path(_), do: ""

  defp parse_source("osrs"), do: :osrs
  defp parse_source("nlab"), do: :nlab
  defp parse_source("wikipedia"), do: :wikipedia
  defp parse_source("machines"), do: :vintage_machinery
  defp parse_source("art"), do: :wikiart
  defp parse_source(_), do: nil

  defp format_rfc822(nil), do: format_rfc822(DateTime.utc_now())

  defp format_rfc822(%DateTime{} = dt) do
    Calendar.strftime(dt, "%a, %d %b %Y %H:%M:%S +0000")
  end

  defp truncate_text(nil, _max), do: ""

  defp truncate_text(text, max) when is_binary(text) do
    if String.length(text) <= max do
      text
    else
      String.slice(text, 0, max) <> "..."
    end
  end

  defp escape_xml(nil), do: ""

  defp escape_xml(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end
end
