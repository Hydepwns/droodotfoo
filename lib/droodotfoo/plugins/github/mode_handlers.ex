defmodule Droodotfoo.Plugins.GitHub.ModeHandlers do
  @moduledoc """
  Mode-specific input handling for the GitHub plugin.
  Uses pattern matching to dispatch input based on current mode.
  """

  alias Droodotfoo.Plugins.GitHub.ApiLoader

  @doc """
  Handle input based on current mode.
  Returns {:continue, state, render} tuple.
  """
  def handle(:input, input, state, render_fn) do
    case input do
      "t" -> ApiLoader.load_trending(state, render_fn)
      "s" -> switch_mode(state, :search, "Enter search query", render_fn)
      _ -> ApiLoader.load_user(state, input, render_fn)
    end
  end

  def handle(:user, input, state, render_fn) do
    case input do
      "r" -> ApiLoader.load_repos(state, render_fn)
      "a" -> ApiLoader.load_activity(state, render_fn)
      "m" -> switch_mode(state, :input, nil, render_fn)
      "s" -> switch_mode(state, :search, nil, render_fn)
      "t" -> ApiLoader.load_trending(state, render_fn)
      _ -> no_change(state, render_fn)
    end
  end

  def handle(:repos, input, state, render_fn) do
    case input do
      "m" -> switch_mode(state, :user, nil, render_fn)
      "a" -> ApiLoader.load_activity(state, render_fn)
      "s" -> switch_mode(state, :search, nil, render_fn)
      "t" -> ApiLoader.load_trending(state, render_fn)
      _ -> maybe_select_repo(input, state, render_fn)
    end
  end

  def handle(:activity, input, state, render_fn) do
    case input do
      "m" -> switch_mode(state, :user, nil, render_fn)
      "r" -> ApiLoader.load_repos(state, render_fn)
      "s" -> switch_mode(state, :search, nil, render_fn)
      "t" -> ApiLoader.load_trending(state, render_fn)
      _ -> no_change(state, render_fn)
    end
  end

  def handle(:repo_details, input, state, render_fn) do
    case input do
      "c" -> ApiLoader.load_commits(state, render_fn)
      "i" -> ApiLoader.load_issues(state, render_fn)
      "p" -> ApiLoader.load_pulls(state, render_fn)
      "m" -> switch_mode(state, :repos, nil, render_fn)
      "s" -> switch_mode(state, :search, nil, render_fn)
      _ -> no_change(state, render_fn)
    end
  end

  def handle(:commits, input, state, render_fn) do
    case input do
      "m" -> switch_mode(state, :repo_details, nil, render_fn)
      _ -> no_change(state, render_fn)
    end
  end

  def handle(:issues, input, state, render_fn) do
    case input do
      "m" -> switch_mode(state, :repo_details, nil, render_fn)
      _ -> no_change(state, render_fn)
    end
  end

  def handle(:pulls, input, state, render_fn) do
    case input do
      "m" -> switch_mode(state, :repo_details, nil, render_fn)
      _ -> no_change(state, render_fn)
    end
  end

  def handle(:search, input, state, render_fn) do
    case input do
      "m" ->
        previous_mode = if state.username, do: :user, else: :input
        switch_mode(state, previous_mode, nil, render_fn)

      "" ->
        no_change(state, render_fn)

      _ ->
        ApiLoader.search_repos(state, input, render_fn)
    end
  end

  def handle(:trending, input, state, render_fn) do
    case input do
      "m" -> switch_mode(state, :input, nil, render_fn)
      "s" -> switch_mode(state, :search, nil, render_fn)
      _ -> maybe_select_trending(input, state, render_fn)
    end
  end

  # Helpers

  defp switch_mode(state, mode, message, render_fn) do
    new_state = %{state | mode: mode, message: message}
    {:continue, new_state, render_fn.(new_state, %{})}
  end

  defp no_change(state, render_fn) do
    {:continue, state, render_fn.(state, %{})}
  end

  defp maybe_select_repo(input, state, render_fn) do
    case Integer.parse(input) do
      {index, ""} when index > 0 and index <= length(state.repos) ->
        repo = Enum.at(state.repos, index - 1)
        [owner, repo_name] = String.split(repo.full_name, "/")
        ApiLoader.load_repo(state, owner, repo_name, render_fn)

      _ ->
        no_change(state, render_fn)
    end
  end

  defp maybe_select_trending(input, state, render_fn) do
    case Integer.parse(input) do
      {index, ""} when index > 0 and index <= length(state.trending) ->
        repo = Enum.at(state.trending, index - 1)
        [owner, repo_name] = String.split(repo.full_name, "/")
        ApiLoader.load_repo(state, owner, repo_name, render_fn)

      _ ->
        no_change(state, render_fn)
    end
  end
end
