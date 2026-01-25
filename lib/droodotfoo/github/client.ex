defmodule Droodotfoo.GitHub.Client do
  @moduledoc """
  GitHub API client for fetching user profile data and repository information.
  Uses REST API v3 and GraphQL API for different operations.
  """

  require Logger

  alias Droodotfoo.ErrorSanitizer
  alias Droodotfoo.GitHub.{HttpClient, ResponseParser}

  @cache_ttl :timer.minutes(15)

  @type repo_info :: %{
          stars: integer(),
          forks: integer(),
          watchers: integer(),
          open_issues: integer(),
          updated_at: String.t(),
          created_at: String.t(),
          license: String.t() | nil
        }

  @type language_breakdown :: %{String.t() => integer()}
  @type commit_info :: %{message: String.t(), date: String.t(), author: String.t()}
  @type release_info :: %{tag: String.t(), name: String.t(), date: String.t()}

  @doc """
  Fetches repository information from GitHub REST API.
  """
  @spec get_repo_info(String.t(), String.t()) :: {:ok, repo_info()} | {:error, term()}
  def get_repo_info(owner, repo) do
    "/repos/#{owner}/#{repo}"
    |> HttpClient.rest_request()
    |> HttpClient.handle_response(&ResponseParser.parse_repo_info/1)
  end

  @doc """
  Fetches language breakdown for a repository.
  """
  @spec get_languages(String.t(), String.t()) :: {:ok, language_breakdown()} | {:error, term()}
  def get_languages(owner, repo) do
    "/repos/#{owner}/#{repo}/languages"
    |> HttpClient.rest_request()
    |> HttpClient.handle_response(:raw)
  end

  @doc """
  Fetches the latest commit for a repository.
  """
  @spec get_latest_commit(String.t(), String.t()) :: {:ok, commit_info()} | {:error, term()}
  def get_latest_commit(owner, repo) do
    "/repos/#{owner}/#{repo}/commits?per_page=1"
    |> HttpClient.rest_request()
    |> HttpClient.handle_list_response(&ResponseParser.parse_commit_info/1)
    |> normalize_empty_error(:no_commits)
  end

  @doc """
  Fetches the latest release for a repository.
  """
  @spec get_latest_release(String.t(), String.t()) :: {:ok, release_info()} | {:error, term()}
  def get_latest_release(owner, repo) do
    "/repos/#{owner}/#{repo}/releases/latest"
    |> HttpClient.rest_request()
    |> HttpClient.handle_response(&ResponseParser.parse_release_info/1)
  end

  @doc """
  Parses a GitHub URL to extract owner and repo name.
  """
  @spec parse_github_url(String.t()) :: {:ok, {String.t(), String.t()}} | {:error, :invalid_url}
  def parse_github_url(url) when is_binary(url) do
    case Regex.run(~r{github\.com/([^/]+)/([^/]+)(?:\.git)?/?$}, url) do
      [_, owner, repo] -> {:ok, {owner, repo}}
      _ -> {:error, :invalid_url}
    end
  end

  def parse_github_url(_), do: {:error, :invalid_url}

  @doc """
  Fetches pinned repositories for a GitHub user.
  Results are cached for 15 minutes.
  """
  def fetch_pinned_repos(username) do
    case get_cached_repos(username) do
      {:ok, repos} -> {:ok, repos}
      :miss -> fetch_and_cache_repos(username)
    end
  end

  @doc """
  Formats pinned repositories for terminal display.
  """
  def format_repos(repos) when is_list(repos) do
    if Enum.empty?(repos) do
      """
      No pinned repositories found.

      Visit https://github.com/hydepwns to see all projects.
      """
    else
      header = """
      My Pinned Projects (from GitHub)
      =================================

      """

      projects =
        repos
        |> Enum.with_index(1)
        |> Enum.map_join("\n", &format_repo_entry/1)

      footer = """

      Updated from: https://github.com/hydepwns
      Pinned repositories sync every 15 minutes.
      """

      header <> projects <> footer
    end
  end

  def format_repos({:error, reason}) do
    """
    Failed to fetch GitHub projects: #{reason}

    Fallback projects:
    =================

    droo.foo            - This terminal portfolio (Elixir/Phoenix)
    axol-framework      - High-performance web framework (Rust)
    terminal-ui         - Raxol terminal UI library (Elixir)

    Visit https://github.com/hydepwns for all projects.
    """
  end

  # Private

  defp normalize_empty_error({:error, :empty}, error_atom), do: {:error, error_atom}
  defp normalize_empty_error(result, _), do: result

  defp fetch_and_cache_repos(username) do
    case fetch_from_github(username) do
      {:ok, repos} ->
        cache_repos(username, repos)
        {:ok, repos}

      {:error, reason} = error ->
        Logger.error(
          "Failed to fetch GitHub repos for #{username}: #{ErrorSanitizer.sanitize(reason)}"
        )

        error
    end
  end

  defp fetch_from_github(username) do
    case System.get_env("GITHUB_TOKEN") do
      token when token in [nil, ""] ->
        Logger.info("No GITHUB_TOKEN found, using REST API fallback for user repos")
        fetch_from_rest_api(username)

      _token ->
        fetch_from_graphql(username)
    end
  end

  defp fetch_from_graphql(username) do
    query = pinned_repos_query(username)

    case HttpClient.graphql_request(query) do
      {:ok, response_body} -> ResponseParser.parse_graphql_repos(response_body)
      error -> error
    end
  end

  defp fetch_from_rest_api(username) do
    url = "https://api.github.com/users/#{username}/repos?sort=stars&per_page=6"

    headers = [
      {~c"User-Agent", ~c"droo.foo-terminal"},
      {~c"Accept", ~c"application/vnd.github.v3+json"}
    ]

    case :httpc.request(:get, {String.to_charlist(url), headers}, [], []) do
      {:ok, {{_, 200, _}, _headers, response_body}} ->
        ResponseParser.parse_rest_repos(List.to_string(response_body))

      {:ok, {{_, status, _}, _headers, _response_body}} ->
        Logger.error("GitHub REST API returned status #{status}")
        {:error, "GitHub API error: #{status}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{ErrorSanitizer.sanitize(reason)}"}
    end
  end

  defp pinned_repos_query(username) do
    """
    {
      user(login: "#{username}") {
        pinnedItems(first: 6, types: REPOSITORY) {
          nodes {
            ... on Repository {
              name
              description
              url
              stargazerCount
              forkCount
              primaryLanguage {
                name
                color
              }
              repositoryTopics(first: 5) {
                nodes {
                  topic {
                    name
                  }
                }
              }
            }
          }
        }
      }
    }
    """
  end

  # Cache implementation

  defp get_cached_repos(username) do
    case :ets.whereis(:github_cache) do
      :undefined ->
        :ets.new(:github_cache, [:named_table, :public, read_concurrency: true])
        :miss

      _table ->
        lookup_cached_repos(username)
    end
  end

  defp lookup_cached_repos(username) do
    case :ets.lookup(:github_cache, username) do
      [{^username, repos, cached_at}] ->
        if System.system_time(:millisecond) - cached_at < @cache_ttl do
          {:ok, repos}
        else
          :ets.delete(:github_cache, username)
          :miss
        end

      [] ->
        :miss
    end
  end

  defp cache_repos(username, repos) do
    ensure_cache_table()
    :ets.insert(:github_cache, {username, repos, System.system_time(:millisecond)})
  end

  defp ensure_cache_table do
    case :ets.whereis(:github_cache) do
      :undefined -> :ets.new(:github_cache, [:named_table, :public, read_concurrency: true])
      _table -> :ok
    end
  end

  defp format_repo_entry({repo, idx}) do
    stars = if repo.stars > 0, do: " [#{repo.stars} stars]", else: ""
    language = "[#{repo.language}]"

    """
    #{idx}. #{repo.name} #{language}#{stars}
       #{repo.description}
       #{repo.url}
    """
  end
end
