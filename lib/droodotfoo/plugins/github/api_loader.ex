defmodule Droodotfoo.Plugins.GitHub.ApiLoader do
  @moduledoc """
  Generic API loading functions for the GitHub plugin.
  Consolidates repeated API call patterns into reusable functions.
  """

  alias Droodotfoo.Github.API

  @doc """
  Load data from API and update state with result.
  Returns {:continue, state, render} tuple for plugin system.
  """
  def load(api_fn, state, opts) do
    state_key = Keyword.fetch!(opts, :state_key)
    mode = Keyword.fetch!(opts, :mode)
    error_msg = Keyword.get(opts, :error_msg, "Failed to load data")
    render_fn = Keyword.fetch!(opts, :render_fn)

    case api_fn.() do
      {:ok, data} ->
        new_state =
          state |> Map.put(state_key, data) |> Map.put(:mode, mode) |> Map.put(:error, nil)

        {:continue, new_state, render_fn.(new_state, %{})}

      {:error, :not_found} ->
        new_state = %{state | error: "#{error_msg}: not found"}
        {:continue, new_state, render_fn.(new_state, %{})}

      {:error, reason} ->
        new_state = %{state | error: "#{error_msg}: #{inspect(reason)}"}
        {:continue, new_state, render_fn.(new_state, %{})}
    end
  end

  @doc """
  Load user profile by username.
  """
  def load_user(state, username, render_fn) do
    load(
      fn -> API.get_user(username) end,
      %{state | username: username},
      state_key: :user_data,
      mode: :user,
      error_msg: "User '#{username}' not found",
      render_fn: render_fn
    )
  end

  @doc """
  Load repositories for current user.
  """
  def load_repos(state, render_fn) do
    load(
      fn -> API.get_user_repos(state.username) end,
      state,
      state_key: :repos,
      mode: :repos,
      error_msg: "Failed to load repos",
      render_fn: render_fn
    )
  end

  @doc """
  Load activity for current user.
  """
  def load_activity(state, render_fn) do
    load(
      fn -> API.get_user_events(state.username) end,
      state,
      state_key: :activity,
      mode: :activity,
      error_msg: "Failed to load activity",
      render_fn: render_fn
    )
  end

  @doc """
  Load repository details.
  """
  def load_repo(state, owner, repo_name, render_fn) do
    load(
      fn -> API.get_repo(owner, repo_name) end,
      state,
      state_key: :current_repo,
      mode: :repo_details,
      error_msg: "Failed to load repo",
      render_fn: render_fn
    )
  end

  @doc """
  Load commits for current repository.
  """
  def load_commits(state, render_fn) do
    [owner, repo_name] = String.split(state.current_repo.full_name, "/")

    load(
      fn -> API.get_repo_commits(owner, repo_name) end,
      state,
      state_key: :commits,
      mode: :commits,
      error_msg: "Failed to load commits",
      render_fn: render_fn
    )
  end

  @doc """
  Load issues for current repository.
  """
  def load_issues(state, render_fn) do
    [owner, repo_name] = String.split(state.current_repo.full_name, "/")

    load(
      fn -> API.get_repo_issues(owner, repo_name) end,
      state,
      state_key: :issues,
      mode: :issues,
      error_msg: "Failed to load issues",
      render_fn: render_fn
    )
  end

  @doc """
  Load pull requests for current repository.
  """
  def load_pulls(state, render_fn) do
    [owner, repo_name] = String.split(state.current_repo.full_name, "/")

    load(
      fn -> API.get_repo_pulls(owner, repo_name) end,
      state,
      state_key: :pulls,
      mode: :pulls,
      error_msg: "Failed to load PRs",
      render_fn: render_fn
    )
  end

  @doc """
  Search repositories.
  """
  def search_repos(state, query, render_fn) do
    load(
      fn -> API.search_repos(query) end,
      %{state | search_query: query},
      state_key: :search_results,
      mode: :search,
      error_msg: "Search failed",
      render_fn: render_fn
    )
  end

  @doc """
  Load trending repositories.
  """
  def load_trending(state, render_fn) do
    load(
      fn -> API.get_trending() end,
      state,
      state_key: :trending,
      mode: :trending,
      error_msg: "Failed to load trending",
      render_fn: render_fn
    )
  end
end
