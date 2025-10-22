defmodule DroodotfooWeb.ViewHelpers do
  @moduledoc """
  Shared helper functions for LiveView templates.
  Provides formatting and display utilities used across multiple LiveViews.
  """

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
end
