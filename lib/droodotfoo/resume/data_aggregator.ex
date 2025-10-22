defmodule Droodotfoo.Resume.DataAggregator do
  @moduledoc """
  Aggregates and processes resume data for rendering and analysis.

  Provides common data transformation functions used across multiple
  renderer modules to avoid duplication.
  """

  @doc """
  Aggregates all technologies from experience entries and groups them by category.

  Returns a map where keys are category atoms (:languages, :frameworks, :tools)
  and values are lists of {technology, frequency} tuples sorted by frequency.

  ## Examples

      iex> experience = [
      ...>   %{technologies: %{languages: ["Elixir", "Python"], frameworks: ["Phoenix"]}},
      ...>   %{technologies: %{languages: ["Elixir"], tools: ["Git"]}}
      ...> ]
      iex> aggregate_technologies_by_category(experience)
      %{
        languages: [{"Elixir", 2}, {"Python", 1}],
        frameworks: [{"Phoenix", 1}],
        tools: [{"Git", 1}]
      }
  """
  def aggregate_technologies_by_category(experience) when is_list(experience) do
    experience
    |> Enum.flat_map(fn exp ->
      (exp[:technologies] || %{})
      |> Enum.reject(fn {_k, v} -> is_nil(v) || v == [] end)
      |> Enum.to_list()
    end)
    |> Enum.group_by(
      fn {category, _items} -> category end,
      fn {_category, items} -> items end
    )
    |> Enum.map(fn {category, items_lists} ->
      all_items =
        items_lists
        |> List.flatten()
        |> Enum.frequencies()
        |> Enum.sort_by(fn {_tech, count} -> -count end)

      {category, all_items}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Aggregates all technologies from experience entries as a flat list.

  Returns a list of {technology, frequency} tuples sorted by frequency (descending).
  Optionally limits the results to top N technologies.

  ## Examples

      iex> experience = [
      ...>   %{technologies: %{languages: ["Elixir", "Python"]}},
      ...>   %{technologies: %{languages: ["Elixir"], frameworks: ["Phoenix"]}}
      ...> ]
      iex> aggregate_all_technologies(experience, limit: 2)
      [{"Elixir", 2}, {"Python", 1}]
  """
  def aggregate_all_technologies(experience, opts \\ []) when is_list(experience) do
    limit = Keyword.get(opts, :limit, nil)

    all_technologies =
      experience
      |> Enum.flat_map(fn exp ->
        (exp[:technologies] || %{})
        |> Enum.reject(fn {_k, v} -> is_nil(v) || v == [] end)
        |> Enum.flat_map(fn {_category, items} -> items end)
      end)
      |> Enum.frequencies()
      |> Enum.sort_by(fn {_tech, count} -> -count end)

    if limit do
      Enum.take(all_technologies, limit)
    else
      all_technologies
    end
  end

  @doc """
  Calculates a percentage for a technology based on its frequency.

  Uses the maximum frequency as 100% and calculates relative percentage.
  Clamps the result to a maximum of 100.

  ## Examples

      iex> technologies = [{"Elixir", 10}, {"Python", 5}, {"Ruby", 3}]
      iex> calculate_technology_percentage(technologies, "Elixir")
      100

      iex> calculate_technology_percentage(technologies, "Python")
      50
  """
  def calculate_technology_percentage(technologies, tech_name) when is_list(technologies) do
    max_count =
      technologies
      |> Enum.map(fn {_tech, count} -> count end)
      |> Enum.max(fn -> 1 end)

    case Enum.find(technologies, fn {name, _count} -> name == tech_name end) do
      {_name, count} -> min(round(count / max_count * 100), 100)
      nil -> 0
    end
  end

  @doc """
  Gets the top N most frequent technologies from a categorized map.

  ## Examples

      iex> tech_by_category = %{languages: [{"Elixir", 5}, {"Python", 3}], tools: [{"Git", 2}]}
      iex> get_top_technologies(tech_by_category, 3)
      [{"Elixir", 5}, {"Python", 3}, {"Git", 2}]
  """
  def get_top_technologies(tech_by_category, limit) when is_map(tech_by_category) do
    tech_by_category
    |> Enum.flat_map(fn {_category, items} -> items end)
    |> Enum.sort_by(fn {_tech, count} -> -count end)
    |> Enum.take(limit)
  end
end
