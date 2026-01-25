defmodule Droodotfoo.Plugins.GitHub.RenderHelpers do
  @moduledoc """
  Rendering helpers for the GitHub plugin.
  Handles mode-specific content rendering.
  """

  alias Droodotfoo.Github.AsciiArt

  import Droodotfoo.Plugins.UIHelpers

  @doc """
  Render content for the current mode.
  """
  def render_mode_content(%{mode: :input}), do: render_input()

  def render_mode_content(%{mode: :user, user_data: user}) when not is_nil(user),
    do: render_user(user)

  def render_mode_content(%{mode: :repos, repos: repos}), do: render_repos(repos)
  def render_mode_content(%{mode: :activity, activity: activity}), do: render_activity(activity)

  def render_mode_content(%{mode: :repo_details, current_repo: repo}) when not is_nil(repo),
    do: render_repo_details(repo)

  def render_mode_content(%{mode: :commits, commits: commits}), do: render_commits(commits)
  def render_mode_content(%{mode: :issues, issues: issues}), do: render_issues(issues)
  def render_mode_content(%{mode: :pulls, pulls: pulls}), do: render_pulls(pulls)
  def render_mode_content(%{mode: :search} = state), do: render_search(state)
  def render_mode_content(%{mode: :trending, trending: trending}), do: render_trending(trending)
  def render_mode_content(_state), do: ["Loading..."]

  defp render_input do
    AsciiArt.github_logo() ++
      [
        "",
        "GitHub Browser",
        "",
        "Enter a GitHub username to view their profile and activity",
        "Or type:",
        "  [t] - View trending repositories",
        "  [s] - Search repositories",
        ""
      ]
  end

  defp render_user(user) do
    AsciiArt.render_user_profile(user) ++
      [
        "",
        "Navigation:",
        "[r] View Repositories    [a] View Activity",
        "[s] Search               [t] Trending",
        "[m] Back to input"
      ]
  end

  defp render_repos(repos) do
    AsciiArt.render_repo_list(repos) ++
      [
        "",
        "Enter repo number to view details",
        "[a] Activity  [m] Back to user  [s] Search  [t] Trending"
      ]
  end

  defp render_activity(activity) do
    AsciiArt.render_activity(activity) ++
      [
        "",
        "[r] Repositories  [m] Back to user  [s] Search  [t] Trending"
      ]
  end

  defp render_repo_details(repo) do
    AsciiArt.render_repo_details(repo) ++
      [
        "",
        "Navigation:",
        "[c] View Commits    [i] View Issues    [p] View Pull Requests",
        "[m] Back to repos   [s] Search"
      ]
  end

  defp render_commits(commits) do
    AsciiArt.render_commits(commits) ++
      [
        "",
        "[m] Back to repository details"
      ]
  end

  defp render_issues(issues) do
    AsciiArt.render_issues(issues, :issue) ++
      [
        "",
        "[m] Back to repository details"
      ]
  end

  defp render_pulls(pulls) do
    AsciiArt.render_issues(pulls, :pull) ++
      [
        "",
        "[m] Back to repository details"
      ]
  end

  defp render_search(%{search_results: results, search_query: query}) when query != "" do
    AsciiArt.render_repo_list(results) ++
      [
        "",
        "Search: \"#{query}\"",
        "[m] Back  [s] New search"
      ]
  end

  defp render_search(_) do
    [
      "+-- Search Repositories " <> String.duplicate("-", 78 - 25) <> "+",
      "|                                                                            |",
      "| Enter search query (e.g., 'language:elixir stars:>100')                   |",
      "|                                                                            |",
      "+----------------------------------------------------------------------------+",
      "",
      "[m] Back to main"
    ]
  end

  defp render_trending(trending) do
    AsciiArt.render_repo_list(trending) ++
      [
        "",
        "Trending repositories from the last 7 days",
        "Enter repo number to view details",
        "[m] Back to input  [s] Search"
      ]
  end

  @doc """
  Render the help screen.
  """
  def render_help do
    header_left("GITHUB PLUGIN HELP", 78) ++
      [
        "",
        "MODES:",
        "  Input       - Enter username or choose trending/search",
        "  User        - View user profile and stats",
        "  Repos       - Browse user repositories",
        "  Activity    - View user's recent activity",
        "  Repo        - Repository details with commits/issues/PRs",
        "  Search      - Search GitHub repositories",
        "  Trending    - View trending repositories",
        "",
        "COMMANDS:",
        "  Input Mode:",
        "    <username>  - Load user profile",
        "    [t]         - View trending",
        "    [s]         - Search repos",
        "",
        "  User Mode:",
        "    [r] - View repositories",
        "    [a] - View activity",
        "    [s] - Search",
        "    [t] - Trending",
        "",
        "  Repo Details:",
        "    [c] - View commits",
        "    [i] - View issues",
        "    [p] - View pull requests",
        "",
        "GENERAL:",
        "  [m] - Back/Main menu",
        "  [h] - Show this help",
        "  [q] - Quit plugin",
        "",
        divider(78)
      ]
  end
end
