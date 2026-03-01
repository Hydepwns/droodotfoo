defmodule DroodotfooWeb.Wiki.Helpers.TOC do
  @moduledoc """
  Table of contents generation for wiki articles.
  Parses HTML to extract headings and generates anchor links.
  """

  @heading_regex ~r/<h([2-3])(?:\s+[^>]*)?>([^<]+)<\/h\1>/i

  @doc """
  Extracts headings from HTML and returns a list of TOC entries.
  Each entry is a map with :level, :text, and :id keys.
  """
  @spec extract_headings(String.t()) :: [map()]
  def extract_headings(html) when is_binary(html) do
    @heading_regex
    |> Regex.scan(html)
    |> Enum.map(fn [_full, level, text] ->
      text = String.trim(text)

      %{
        level: String.to_integer(level),
        text: text,
        id: slugify(text)
      }
    end)
  end

  def extract_headings(_), do: []

  @doc """
  Adds anchor IDs to headings in HTML.
  Returns modified HTML with id attributes on h2/h3 tags.
  """
  @spec add_heading_anchors(String.t()) :: String.t()
  def add_heading_anchors(html) when is_binary(html) do
    Regex.replace(
      ~r/<h([2-3])(\s+[^>]*)?>([^<]+)<\/h\1>/i,
      html,
      fn _full, level, attrs, text ->
        id = slugify(String.trim(text))
        attrs = String.trim(attrs || "")

        if attrs == "" do
          ~s(<h#{level} id="#{id}">#{text}</h#{level}>)
        else
          ~s(<h#{level} id="#{id}"#{attrs}>#{text}</h#{level}>)
        end
      end
    )
  end

  def add_heading_anchors(html), do: html

  @doc """
  Converts text to a URL-safe slug for use as anchor ID.
  """
  @spec slugify(String.t()) :: String.t()
  def slugify(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^\w\s-]/u, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
    |> then(fn s -> if s == "", do: "heading", else: s end)
  end
end
