defmodule DroodotfooWeb.PatternController do
  use DroodotfooWeb, :controller

  alias Droodotfoo.Content.PatternCache

  @doc """
  Serves a generated SVG pattern for a post slug.

  ## URL Parameters

    * `slug` - The post slug to generate a pattern for

  ## Query Parameters

    * `style` - Pattern style: waves, noise, lines, dots, circuit, glitch, geometric, grid (default: auto-selected)
    * `width` - Image width in pixels (default: 1200)
    * `height` - Image height in pixels (default: 630)
    * `animate` - Enable CSS animations (default: false)

  ## Examples

      GET /patterns/my-post-slug
      GET /patterns/my-post-slug?style=waves&animate=true
      GET /patterns/my-post-slug?style=grid&width=800&height=400
  """
  def show(conn, %{"slug" => slug} = params) do
    # Parse options from query params
    opts = [
      style: parse_style(params["style"]),
      width: parse_integer(params["width"], 1200),
      height: parse_integer(params["height"], 630),
      animate: parse_boolean(params["animate"], false)
    ]

    # Get from cache or generate (server-side caching)
    svg = PatternCache.get_or_generate(slug, opts)

    # Set aggressive caching headers (pattern is deterministic)
    conn
    |> put_resp_content_type("image/svg+xml")
    |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
    |> put_resp_header("etag", generate_etag(slug, opts))
    |> send_resp(200, svg)
  end

  # Parse style parameter
  defp parse_style(nil), do: nil
  defp parse_style("waves"), do: :waves
  defp parse_style("noise"), do: :noise
  defp parse_style("lines"), do: :lines
  defp parse_style("dots"), do: :dots
  defp parse_style("circuit"), do: :circuit
  defp parse_style("glitch"), do: :glitch
  defp parse_style("geometric"), do: :geometric
  defp parse_style("grid"), do: :grid
  defp parse_style(_), do: nil

  # Parse integer with fallback
  defp parse_integer(nil, default), do: default

  defp parse_integer(str, default) when is_binary(str) do
    case Integer.parse(str) do
      {int, _} when int > 0 and int <= 2400 -> int
      _ -> default
    end
  end

  defp parse_integer(_, default), do: default

  # Parse boolean parameter
  defp parse_boolean(nil, default), do: default
  defp parse_boolean("true", _default), do: true
  defp parse_boolean("1", _default), do: true
  defp parse_boolean(_, _default), do: false

  # Generate ETag for caching
  defp generate_etag(slug, opts) do
    opts_string = Enum.map_join(opts, "-", fn {k, v} -> "#{k}:#{v}" end)
    hash = :crypto.hash(:md5, "#{slug}-#{opts_string}") |> Base.encode16(case: :lower)
    ~s("#{hash}")
  end
end
