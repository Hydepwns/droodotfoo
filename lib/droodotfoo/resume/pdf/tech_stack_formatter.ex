defmodule Droodotfoo.Resume.PDF.TechStackFormatter do
  @moduledoc """
  Formats technology stack information for resume PDF generation.
  Consolidates repeated tech category formatting logic.
  """

  @doc """
  Format technologies map into a display string.
  Returns empty string if no technologies present.

  ## Examples

      iex> format_categories(%{languages: ["Elixir", "Go"], databases: ["PostgreSQL"]})
      "Languages: Elixir, Go | Databases: PostgreSQL"
  """
  def format_categories(nil), do: ""
  def format_categories(technologies) when technologies == %{}, do: ""

  def format_categories(technologies) do
    technologies
    |> Enum.reject(fn {_k, v} -> is_nil(v) or v == [] end)
    |> Enum.map_join(" | ", fn {category, items} ->
      "#{category |> to_string() |> String.capitalize()}: #{Enum.join(items, ", ")}"
    end)
  end

  @doc """
  Wrap tech categories in HTML div if not empty.
  """
  def render_tech_stack(technologies, css_class \\ "tech-stack") do
    case format_categories(technologies) do
      "" -> ""
      formatted -> ~s|<div class="#{css_class}">#{formatted}</div>|
    end
  end
end
