defmodule DroodotfooWeb.LinkWhitespaceTest do
  @moduledoc """
  Guards against the HEEx pattern:

      <a href="...">
        Text
      </a>

  which renders the anchor's text with leading/trailing whitespace, causing the
  underline to extend past the visible word.
  """

  use DroodotfooWeb.ConnCase, async: true
  import Phoenix.LiveViewTest

  @routes [
    "/",
    "/about",
    "/now",
    "/projects",
    "/resume",
    "/contact",
    "/sitemap"
  ]

  for route <- @routes do
    test "anchor text on #{route} has no leading/trailing whitespace", %{conn: conn} do
      {:ok, _view, html} = live(conn, unquote(route))
      assert_anchors_trimmed(html, unquote(route))
    end
  end

  defp assert_anchors_trimmed(html, route) do
    offenders =
      html
      |> Floki.parse_document!()
      |> Floki.find("a")
      |> Enum.map(&Floki.text/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.filter(&(&1 != String.trim(&1)))

    assert offenders == [],
           """
           Anchor text with leading or trailing whitespace on #{route}.
           Wrap link text inline as `>Text</a>` (no newlines between `>`/`</a>` and the text).

           Offenders (inspected):
           #{Enum.map_join(offenders, "\n", &inspect/1)}
           """
  end
end
