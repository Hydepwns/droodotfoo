defmodule Droodotfoo.Plugins.GitHub do
  @moduledoc """
  GitHub plugin for the terminal interface.
  Provides GitHub activity feed, repository browsing, and search.
  """

  @behaviour Droodotfoo.PluginSystem.Plugin

  alias Droodotfoo.Github.{API, AsciiArt}
  alias Droodotfoo.Plugins.GameBase

  import Droodotfoo.Plugins.UIHelpers

  defstruct [
    :mode,
    :username,
    :user_data,
    :repos,
    :activity,
    :current_repo,
    :commits,
    :issues,
    :pulls,
    :search_results,
    :search_query,
    :trending,
    :message,
    :error
  ]

  # Plugin Behaviour Callbacks

  @impl true
  def metadata do
    GameBase.game_metadata(
      "github",
      "1.0.0",
      "GitHub activity feed and repository browser",
      "droo.foo",
      ["github", "gh"],
      :utility
    )
  end

  @impl true
  def init(_terminal_state) do
    initial_state = %__MODULE__{
      mode: :input,
      username: nil,
      user_data: nil,
      repos: [],
      activity: [],
      current_repo: nil,
      commits: [],
      issues: [],
      pulls: [],
      search_results: [],
      search_query: "",
      trending: [],
      message: nil,
      error: nil
    }

    {:ok, initial_state}
  end

  @impl true
  def handle_input(input, state, _terminal_state) do
    input = String.trim(input)

    case input do
      input when input in ["q", "Q", "quit", "exit"] ->
        {:exit, ["GitHub plugin closed."]}

      "help" ->
        {:continue, state, render_help()}

      _ ->
        handle_mode_input(input, state)
    end
  end

  @impl true
  def render(state, _terminal_state) do
    header = header("GITHUB BROWSER", 78)

    mode_indicator = [
      "",
      "Mode: #{state.mode |> to_string() |> String.upcase()}" |> String.pad_trailing(78),
      ""
    ]

    content = render_mode_content(state)

    message_section =
      cond do
        state.error ->
          ["", "ERROR: #{state.error}", ""]

        state.message ->
          ["", ">> #{state.message}", ""]

        true ->
          []
      end

    footer = [
      "-" |> String.duplicate(78),
      "Commands: [h]elp [q]uit  |  Navigate: [m]ain [r]efresh [s]earch [t]rending",
      "-" |> String.duplicate(78)
    ]

    header ++ mode_indicator ++ content ++ message_section ++ footer
  end

  @impl true
  def cleanup(_state) do
    :ok
  end

  # Input Handling

  defp handle_mode_input(input, %{mode: :input} = state) do
    case input do
      "t" ->
        # Show trending
        load_trending(state)

      "s" ->
        # Switch to search mode
        {:continue, %{state | mode: :search, message: "Enter search query"}, render(state, %{})}

      _ ->
        # Assume it's a username
        load_user(state, input)
    end
  end

  defp handle_mode_input(input, %{mode: :user} = state) do
    case input do
      "r" -> load_repos(state)
      "a" -> load_activity(state)
      "m" -> {:continue, %{state | mode: :input, message: nil}, render(state, %{})}
      "s" -> {:continue, %{state | mode: :search}, render(state, %{})}
      "t" -> load_trending(state)
      _ -> {:continue, state, render(state, %{})}
    end
  end

  defp handle_mode_input(input, %{mode: :repos} = state) do
    case input do
      "m" ->
        {:continue, %{state | mode: :user}, render(state, %{})}

      "a" ->
        load_activity(state)

      "s" ->
        {:continue, %{state | mode: :search}, render(state, %{})}

      "t" ->
        load_trending(state)

      _ ->
        # Try to parse as repo selection (1-based index)
        case Integer.parse(input) do
          {index, ""} when index > 0 and index <= length(state.repos) ->
            repo = Enum.at(state.repos, index - 1)
            load_repo_details(state, repo)

          _ ->
            {:continue, state, render(state, %{})}
        end
    end
  end

  defp handle_mode_input(input, %{mode: :activity} = state) do
    case input do
      "m" -> {:continue, %{state | mode: :user}, render(state, %{})}
      "r" -> load_repos(state)
      "s" -> {:continue, %{state | mode: :search}, render(state, %{})}
      "t" -> load_trending(state)
      _ -> {:continue, state, render(state, %{})}
    end
  end

  defp handle_mode_input(input, %{mode: :repo_details} = state) do
    case input do
      "c" -> load_commits(state)
      "i" -> load_issues(state)
      "p" -> load_pulls(state)
      "m" -> {:continue, %{state | mode: :repos}, render(state, %{})}
      "s" -> {:continue, %{state | mode: :search}, render(state, %{})}
      _ -> {:continue, state, render(state, %{})}
    end
  end

  defp handle_mode_input(input, %{mode: :commits} = state) do
    case input do
      "m" -> {:continue, %{state | mode: :repo_details}, render(state, %{})}
      _ -> {:continue, state, render(state, %{})}
    end
  end

  defp handle_mode_input(input, %{mode: :issues} = state) do
    case input do
      "m" -> {:continue, %{state | mode: :repo_details}, render(state, %{})}
      _ -> {:continue, state, render(state, %{})}
    end
  end

  defp handle_mode_input(input, %{mode: :pulls} = state) do
    case input do
      "m" -> {:continue, %{state | mode: :repo_details}, render(state, %{})}
      _ -> {:continue, state, render(state, %{})}
    end
  end

  defp handle_mode_input(input, %{mode: :search} = state) do
    case input do
      "m" ->
        # Go back to previous mode (user or input)
        previous_mode = if state.username, do: :user, else: :input
        {:continue, %{state | mode: previous_mode}, render(state, %{})}

      "" ->
        {:continue, state, render(state, %{})}

      _ ->
        perform_search(state, input)
    end
  end

  defp handle_mode_input(input, %{mode: :trending} = state) do
    case input do
      "m" ->
        {:continue, %{state | mode: :input}, render(state, %{})}

      "s" ->
        {:continue, %{state | mode: :search}, render(state, %{})}

      _ ->
        # Try to parse as repo selection
        case Integer.parse(input) do
          {index, ""} when index > 0 and index <= length(state.trending) ->
            repo = Enum.at(state.trending, index - 1)
            [owner, repo_name] = String.split(repo.full_name, "/")
            load_repo_by_name(state, owner, repo_name)

          _ ->
            {:continue, state, render(state, %{})}
        end
    end
  end

  # Mode Content Rendering

  defp render_mode_content(%{mode: :input}) do
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

  defp render_mode_content(%{mode: :user, user_data: user}) when not is_nil(user) do
    AsciiArt.render_user_profile(user) ++
      [
        "",
        "Navigation:",
        "[r] View Repositories    [a] View Activity",
        "[s] Search               [t] Trending",
        "[m] Back to input"
      ]
  end

  defp render_mode_content(%{mode: :repos, repos: repos}) do
    AsciiArt.render_repo_list(repos) ++
      [
        "",
        "Enter repo number to view details",
        "[a] Activity  [m] Back to user  [s] Search  [t] Trending"
      ]
  end

  defp render_mode_content(%{mode: :activity, activity: activity}) do
    AsciiArt.render_activity(activity) ++
      [
        "",
        "[r] Repositories  [m] Back to user  [s] Search  [t] Trending"
      ]
  end

  defp render_mode_content(%{mode: :repo_details, current_repo: repo}) when not is_nil(repo) do
    AsciiArt.render_repo_details(repo) ++
      [
        "",
        "Navigation:",
        "[c] View Commits    [i] View Issues    [p] View Pull Requests",
        "[m] Back to repos   [s] Search"
      ]
  end

  defp render_mode_content(%{mode: :commits, commits: commits}) do
    AsciiArt.render_commits(commits) ++
      [
        "",
        "[m] Back to repository details"
      ]
  end

  defp render_mode_content(%{mode: :issues, issues: issues}) do
    AsciiArt.render_issues(issues, :issue) ++
      [
        "",
        "[m] Back to repository details"
      ]
  end

  defp render_mode_content(%{mode: :pulls, pulls: pulls}) do
    AsciiArt.render_issues(pulls, :pull) ++
      [
        "",
        "[m] Back to repository details"
      ]
  end

  defp render_mode_content(%{mode: :search, search_results: results, search_query: query}) do
    if query != "" do
      AsciiArt.render_repo_list(results) ++
        [
          "",
          "Search: \"#{query}\"",
          "[m] Back  [s] New search"
        ]
    else
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
  end

  defp render_mode_content(%{mode: :trending, trending: trending}) do
    AsciiArt.render_repo_list(trending) ++
      [
        "",
        "Trending repositories from the last 7 days",
        "Enter repo number to view details",
        "[m] Back to input  [s] Search"
      ]
  end

  defp render_mode_content(_state) do
    ["Loading..."]
  end

  # Action Functions

  defp load_user(state, username) do
    case API.get_user(username) do
      {:ok, user} ->
        new_state = %{state | username: username, user_data: user, mode: :user, error: nil}
        {:continue, new_state, render(new_state, %{})}

      {:error, :not_found} ->
        new_state = %{state | error: "User '#{username}' not found"}
        {:continue, new_state, render(new_state, %{})}

      {:error, reason} ->
        new_state = %{state | error: "Failed to load user: #{inspect(reason)}"}
        {:continue, new_state, render(new_state, %{})}
    end
  end

  defp load_repos(state) do
    case API.get_user_repos(state.username) do
      {:ok, repos} ->
        new_state = %{state | repos: repos, mode: :repos, error: nil}
        {:continue, new_state, render(new_state, %{})}

      {:error, reason} ->
        new_state = %{state | error: "Failed to load repos: #{inspect(reason)}"}
        {:continue, new_state, render(new_state, %{})}
    end
  end

  defp load_activity(state) do
    case API.get_user_events(state.username) do
      {:ok, activity} ->
        new_state = %{state | activity: activity, mode: :activity, error: nil}
        {:continue, new_state, render(new_state, %{})}

      {:error, reason} ->
        new_state = %{state | error: "Failed to load activity: #{inspect(reason)}"}
        {:continue, new_state, render(new_state, %{})}
    end
  end

  defp load_repo_details(state, repo) do
    [owner, repo_name] = String.split(repo.full_name, "/")

    case API.get_repo(owner, repo_name) do
      {:ok, repo_details} ->
        new_state = %{state | current_repo: repo_details, mode: :repo_details, error: nil}
        {:continue, new_state, render(new_state, %{})}

      {:error, reason} ->
        new_state = %{state | error: "Failed to load repo: #{inspect(reason)}"}
        {:continue, new_state, render(new_state, %{})}
    end
  end

  defp load_repo_by_name(state, owner, repo_name) do
    case API.get_repo(owner, repo_name) do
      {:ok, repo_details} ->
        new_state = %{state | current_repo: repo_details, mode: :repo_details, error: nil}
        {:continue, new_state, render(new_state, %{})}

      {:error, reason} ->
        new_state = %{state | error: "Failed to load repo: #{inspect(reason)}"}
        {:continue, new_state, render(new_state, %{})}
    end
  end

  defp load_commits(state) do
    [owner, repo_name] = String.split(state.current_repo.full_name, "/")

    case API.get_repo_commits(owner, repo_name) do
      {:ok, commits} ->
        new_state = %{state | commits: commits, mode: :commits, error: nil}
        {:continue, new_state, render(new_state, %{})}

      {:error, reason} ->
        new_state = %{state | error: "Failed to load commits: #{inspect(reason)}"}
        {:continue, new_state, render(new_state, %{})}
    end
  end

  defp load_issues(state) do
    [owner, repo_name] = String.split(state.current_repo.full_name, "/")

    case API.get_repo_issues(owner, repo_name) do
      {:ok, issues} ->
        new_state = %{state | issues: issues, mode: :issues, error: nil}
        {:continue, new_state, render(new_state, %{})}

      {:error, reason} ->
        new_state = %{state | error: "Failed to load issues: #{inspect(reason)}"}
        {:continue, new_state, render(new_state, %{})}
    end
  end

  defp load_pulls(state) do
    [owner, repo_name] = String.split(state.current_repo.full_name, "/")

    case API.get_repo_pulls(owner, repo_name) do
      {:ok, pulls} ->
        new_state = %{state | pulls: pulls, mode: :pulls, error: nil}
        {:continue, new_state, render(new_state, %{})}

      {:error, reason} ->
        new_state = %{state | error: "Failed to load PRs: #{inspect(reason)}"}
        {:continue, new_state, render(new_state, %{})}
    end
  end

  defp perform_search(state, query) do
    case API.search_repos(query) do
      {:ok, results} ->
        new_state = %{state | search_results: results, search_query: query, error: nil}
        {:continue, new_state, render(new_state, %{})}

      {:error, reason} ->
        new_state = %{state | error: "Search failed: #{inspect(reason)}"}
        {:continue, new_state, render(new_state, %{})}
    end
  end

  defp load_trending(state) do
    case API.get_trending() do
      {:ok, trending} ->
        new_state = %{state | trending: trending, mode: :trending, error: nil}
        {:continue, new_state, render(new_state, %{})}

      {:error, reason} ->
        new_state = %{state | error: "Failed to load trending: #{inspect(reason)}"}
        {:continue, new_state, render(new_state, %{})}
    end
  end

  defp render_help do
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
