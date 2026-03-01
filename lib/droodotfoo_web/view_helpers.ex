defmodule DroodotfooWeb.ViewHelpers do
  @moduledoc """
  Shared helper functions for LiveView templates.
  Provides formatting and display utilities used across multiple LiveViews.
  """

  alias Droodotfoo.Resume.DataAggregator

  @doc """
  Format a date range for display.

  ## Examples

      iex> ViewHelpers.format_date_range("2020-01", "Present")
      "2020-01 - Present"

      iex> ViewHelpers.format_date_range("2020-01", "2022-12")
      "2020-01 - 2022-12"
  """
  def format_date_range(start_date, end_date) when end_date == "Present" do
    "#{start_date} - Present"
  end

  def format_date_range(start_date, end_date) do
    "#{start_date} - #{end_date}"
  end

  @doc """
  Format project status for display.

  ## Examples

      iex> ViewHelpers.format_status(:active)
      "Active Development"

      iex> ViewHelpers.format_status(:completed)
      "Completed"

      iex> ViewHelpers.format_status(:archived)
      "Archived"

      iex> ViewHelpers.format_status(:unknown)
      "Unknown Status"
  """
  def format_status(:active), do: "Active Development"
  def format_status(:completed), do: "Completed"
  def format_status(:archived), do: "Archived"
  def format_status(_), do: "Unknown Status"

  @doc """
  Extracts languages from experience entries, ordered by frequency (most common first).

  Each experience entry may have a `technologies` map with a `languages` key.
  Languages appearing in more experience entries rank higher.

  Delegates to `DataAggregator.aggregate_technologies_by_category/1` for the
  heavy lifting, extracting just the language names.

  ## Examples

      iex> ViewHelpers.extract_languages([
      ...>   %{technologies: %{languages: ["Elixir", "TypeScript"]}},
      ...>   %{technologies: %{languages: ["Elixir", "Rust"]}}
      ...> ])
      ["Elixir", "TypeScript", "Rust"]
  """
  @spec extract_languages([map()]) :: [String.t()]
  def extract_languages(experience) when is_list(experience) do
    experience
    |> DataAggregator.aggregate_technologies_by_category()
    |> Map.get(:languages, [])
    |> Enum.map(fn {lang, _count} -> lang end)
  end

  def extract_languages(_), do: []
end
