defmodule DroodotfooWeb.FeedController do
  @moduledoc """
  RSS feed for blog posts.
  """

  use DroodotfooWeb, :controller
  alias Droodotfoo.Content.Posts

  @doc """
  Generates RSS 2.0 feed for blog posts.
  """
  def rss(conn, _params) do
    posts = Posts.list_posts()
    last_build_date = posts |> List.first() |> then(&(&1 && &1.date)) || Date.utc_today()

    xml = build_rss_xml(posts, last_build_date)

    conn
    |> put_resp_content_type("application/rss+xml")
    |> send_resp(200, xml)
  end

  defp build_rss_xml(posts, last_build_date) do
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
      <channel>
        <title>DROO.FOO</title>
        <link>https://droo.foo</link>
        <description>Engineering, crypto, and building with Elixir</description>
        <language>en-us</language>
        <lastBuildDate>#{format_rfc822(last_build_date)}</lastBuildDate>
        <atom:link href="https://droo.foo/feed.xml" rel="self" type="application/rss+xml"/>
    #{Enum.map_join(posts, "\n", &build_item/1)}
      </channel>
    </rss>
    """
  end

  defp build_item(post) do
    """
        <item>
          <title>#{escape_xml(post.title)}</title>
          <link>https://droo.foo/posts/#{post.slug}</link>
          <guid>https://droo.foo/posts/#{post.slug}</guid>
          <pubDate>#{format_rfc822(post.date)}</pubDate>
          <description>#{escape_xml(post.description)}</description>
    #{if post.author, do: "      <author>#{escape_xml(post.author)}</author>\n", else: ""}#{Enum.map_join(post.tags, "\n", fn tag -> "      <category>#{escape_xml(tag)}</category>" end)}
        </item>
    """
  end

  defp format_rfc822(date) do
    # Convert Date to RFC822 format: "Mon, 01 Jan 2024 00:00:00 +0000"
    datetime = DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
    Calendar.strftime(datetime, "%a, %d %b %Y %H:%M:%S +0000")
  end

  defp escape_xml(text) when is_binary(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&apos;")
  end

  defp escape_xml(_), do: ""
end
