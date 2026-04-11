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

  @doc """
  Assign common page metadata to socket in one call.
  Reduces repeated assign(:page_title, ...), assign(:current_path, ...), assign(:json_ld, ...).
  """
  def assign_page_meta(socket, page_title, current_path, json_ld) do
    socket
    |> Phoenix.Component.assign(:page_title, page_title)
    |> Phoenix.Component.assign(:current_path, current_path)
    |> Phoenix.Component.assign(:json_ld, json_ld)
  end

  @doc """
  Generate standard breadcrumb JSON-LD with Home as root.

  ## Examples

      iex> ViewHelpers.breadcrumb_json_ld("About", "/about")
      # Returns JSON-LD breadcrumb schema: Home > About

      iex> ViewHelpers.breadcrumb_json_ld("About", "/about", [JsonLD.person_schema()])
      # Returns breadcrumb + person schemas
  """
  def breadcrumb_json_ld(page_title, page_path, additional_schemas \\ []) do
    alias DroodotfooWeb.SEO.JsonLD
    [JsonLD.breadcrumb_schema([{"Home", "/"}, {page_title, page_path}]) | additional_schemas]
  end

  @doc """
  Format a DateTime or ISO8601 string as relative time ago.

  ## Examples

      iex> ViewHelpers.format_time_ago("2026-04-10T12:00:00Z")
      "1d"
  """
  def format_time_ago(datetime) when is_binary(datetime) do
    case DateTime.from_iso8601(datetime) do
      {:ok, dt, _} -> DateTime.utc_now() |> DateTime.diff(dt) |> format_relative_duration()
      _ -> "-"
    end
  end

  def format_time_ago(_), do: "-"

  defp format_relative_duration(s) when s < 60, do: "now"
  defp format_relative_duration(s) when s < 3600, do: "#{div(s, 60)}m"
  defp format_relative_duration(s) when s < 86_400, do: "#{div(s, 3600)}h"
  defp format_relative_duration(s) when s < 2_592_000, do: "#{div(s, 86_400)}d"
  defp format_relative_duration(s) when s < 31_536_000, do: "#{div(s, 2_592_000)}mo"
  defp format_relative_duration(s), do: "#{div(s, 31_536_000)}y"
end
