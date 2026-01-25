defmodule Droodotfoo.Content.SVG.Gradients do
  @moduledoc """
  SVG gradient definitions (linear and radial).
  """

  @doc """
  Creates a linear gradient definition.

  ## Options

    * `:x1`, `:y1` - Start point (default: 0%, 0%)
    * `:x2`, `:y2` - End point (default: 100%, 0%)
  """
  @spec linear(String.t(), [{number, String.t(), number}], keyword) :: String.t()
  def linear(id, stops, opts \\ []) do
    x1 = Keyword.get(opts, :x1, "0%")
    y1 = Keyword.get(opts, :y1, "0%")
    x2 = Keyword.get(opts, :x2, "100%")
    y2 = Keyword.get(opts, :y2, "0%")

    stops_str = render_stops(stops)

    """
    <linearGradient id="#{id}" x1="#{x1}" y1="#{y1}" x2="#{x2}" y2="#{y2}">
      #{stops_str}
    </linearGradient>
    """
  end

  @doc """
  Creates a radial gradient definition.

  ## Options

    * `:cx`, `:cy` - Center point (default: 50%, 50%)
    * `:r` - Radius (default: 50%)
    * `:fx`, `:fy` - Focal point (default: cx, cy)
  """
  @spec radial(String.t(), [{number, String.t(), number}], keyword) :: String.t()
  def radial(id, stops, opts \\ []) do
    cx = Keyword.get(opts, :cx, "50%")
    cy = Keyword.get(opts, :cy, "50%")
    r = Keyword.get(opts, :r, "50%")
    fx = Keyword.get(opts, :fx, cx)
    fy = Keyword.get(opts, :fy, cy)

    stops_str = render_stops(stops)

    """
    <radialGradient id="#{id}" cx="#{cx}" cy="#{cy}" r="#{r}" fx="#{fx}" fy="#{fy}">
      #{stops_str}
    </radialGradient>
    """
  end

  defp render_stops(stops) do
    Enum.map_join(stops, "\n", fn {offset, color, opacity} ->
      "<stop offset=\"#{offset}%\" stop-color=\"#{color}\" stop-opacity=\"#{opacity}\"/>"
    end)
  end
end
