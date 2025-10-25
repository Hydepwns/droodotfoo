defmodule Droodotfoo.GitHub.Client do
  @moduledoc """
  GitHub API client for fetching user profile data and repository information.
  Uses REST API v3 and GraphQL API for different operations.
  """

  require Logger

  @github_api_url "https://api.github.com/graphql"
  @github_rest_api_url "https://api.github.com"
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

  @type commit_info :: %{
          message: String.t(),
          date: String.t(),
          author: String.t()
        }

  @type release_info :: %{
          tag: String.t(),
          name: String.t(),
          date: String.t()
        }

  @doc """
  Fetches repository information from GitHub REST API.

  ## Examples

      iex> get_repo_info("owner", "repo")
      {:ok, %{stars: 42, forks: 7, ...}}

      iex> get_repo_info("invalid", "repo")
      {:error, :not_found}
  """
  @spec get_repo_info(String.t(), String.t()) :: {:ok, repo_info()} | {:error, term()}
  def get_repo_info(owner, repo) do
    "/repos/#{owner}/#{repo}"
    |> build_rest_url()
    |> rest_api_request()
    |> case do
      {:ok, %{status: 200, body: body}} ->
        {:ok, parse_repo_info(body)}

      {:ok, %{status: 401}} ->
        {:error, :unauthorized}

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:ok, %{status: 403}} ->
        {:error, :rate_limited}

      {:error, reason} ->
        Logger.error("Failed to fetch repo info: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetches language breakdown for a repository.

  Returns a map of language names to bytes of code.

  ## Examples

      iex> get_languages("owner", "repo")
      {:ok, %{"Elixir" => 12345, "JavaScript" => 6789}}
  """
  @spec get_languages(String.t(), String.t()) :: {:ok, language_breakdown()} | {:error, term()}
  def get_languages(owner, repo) do
    "/repos/#{owner}/#{repo}/languages"
    |> build_rest_url()
    |> rest_api_request()
    |> case do
      {:ok, %{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %{status: 401}} ->
        {:error, :unauthorized}

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to fetch languages: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetches the latest commit for a repository.

  ## Examples

      iex> get_latest_commit("owner", "repo")
      {:ok, %{message: "fix: update deps", date: "2025-10-24T...", author: "droo"}}
  """
  @spec get_latest_commit(String.t(), String.t()) :: {:ok, commit_info()} | {:error, term()}
  def get_latest_commit(owner, repo) do
    "/repos/#{owner}/#{repo}/commits?per_page=1"
    |> build_rest_url()
    |> rest_api_request()
    |> case do
      {:ok, %{status: 200, body: [commit | _]}} ->
        {:ok, parse_commit_info(commit)}

      {:ok, %{status: 200, body: []}} ->
        {:error, :no_commits}

      {:ok, %{status: 401}} ->
        {:error, :unauthorized}

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to fetch latest commit: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Fetches the latest release for a repository.

  ## Examples

      iex> get_latest_release("owner", "repo")
      {:ok, %{tag: "v1.0.0", name: "Release 1.0", date: "2025-10-20T..."}}
  """
  @spec get_latest_release(String.t(), String.t()) :: {:ok, release_info()} | {:error, term()}
  def get_latest_release(owner, repo) do
    "/repos/#{owner}/#{repo}/releases/latest"
    |> build_rest_url()
    |> rest_api_request()
    |> case do
      {:ok, %{status: 200, body: body}} ->
        {:ok, parse_release_info(body)}

      {:ok, %{status: 401}} ->
        {:error, :unauthorized}

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to fetch latest release: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Parses a GitHub URL to extract owner and repo name.

  ## Examples

      iex> parse_github_url("https://github.com/owner/repo")
      {:ok, {"owner", "repo"}}

      iex> parse_github_url("invalid")
      {:error, :invalid_url}
  """
  @spec parse_github_url(String.t()) :: {:ok, {String.t(), String.t()}} | {:error, :invalid_url}
  def parse_github_url(url) when is_binary(url) do
    case Regex.run(~r{github\.com/([^/]+)/([^/]+)(?:\.git)?/?$}, url) do
      [_, owner, repo] ->
        {:ok, {owner, repo}}

      _ ->
        {:error, :invalid_url}
    end
  end

  def parse_github_url(_), do: {:error, :invalid_url}

  @doc """
  Fetches pinned repositories for a GitHub user.
  Results are cached for 15 minutes to avoid rate limiting.
  """
  def fetch_pinned_repos(username) do
    case get_cached_repos(username) do
      {:ok, repos} ->
        {:ok, repos}

      :miss ->
        fetch_and_cache_repos(username)
    end
  end

  defp fetch_and_cache_repos(username) do
    case fetch_from_github(username) do
      {:ok, repos} ->
        cache_repos(username, repos)
        {:ok, repos}

      {:error, reason} = error ->
        Logger.error("Failed to fetch GitHub repos for #{username}: #{inspect(reason)}")
        error
    end
  end

  defp fetch_from_github(username) do
    case System.get_env("GITHUB_TOKEN") do
      token when token in [nil, ""] ->
        # Without a token, use REST API fallback
        Logger.info("No GITHUB_TOKEN found, using REST API fallback for user repos")
        fetch_from_rest_api(username)

      token ->
        # With a token, use GraphQL API for pinned repos
        fetch_from_graphql(username, token)
    end
  end

  defp fetch_from_graphql(username, token) do
    query = """
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

    headers = [
      {~c"Content-Type", ~c"application/json"},
      {~c"User-Agent", ~c"droo.foo-terminal"},
      {~c"Authorization", String.to_charlist("Bearer #{token}")}
    ]

    body = Jason.encode!(%{query: query})

    case :httpc.request(
           :post,
           {String.to_charlist(@github_api_url), headers, ~c"application/json",
            String.to_charlist(body)},
           [],
           []
         ) do
      {:ok, {{_, 200, _}, _headers, response_body}} ->
        parse_graphql_response(List.to_string(response_body))

      {:ok, {{_, status, _}, _headers, response_body}} ->
        body_str = List.to_string(response_body)
        Logger.error("GitHub GraphQL API returned #{status}: #{body_str}")
        {:error, "GitHub API error: #{status}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  defp fetch_from_rest_api(username) do
    # Fetch top 6 repos sorted by stars (best approximation of pinned repos without auth)
    url = "https://api.github.com/users/#{username}/repos?sort=stars&per_page=6"

    headers = [
      {~c"User-Agent", ~c"droo.foo-terminal"},
      {~c"Accept", ~c"application/vnd.github.v3+json"}
    ]

    case :httpc.request(:get, {String.to_charlist(url), headers}, [], []) do
      {:ok, {{_, 200, _}, _headers, response_body}} ->
        parse_rest_response(List.to_string(response_body))

      {:ok, {{_, status, _}, _headers, response_body}} ->
        body_str = List.to_string(response_body)
        Logger.error("GitHub REST API returned #{status}: #{body_str}")
        {:error, "GitHub API error: #{status}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{inspect(reason)}"}
    end
  end

  defp parse_graphql_response(response_body) do
    with {:ok, json} <- Jason.decode(response_body),
         %{"data" => %{"user" => %{"pinnedItems" => %{"nodes" => nodes}}}} <- json do
      repos =
        Enum.map(nodes, fn repo ->
          %{
            name: repo["name"],
            description: repo["description"] || "No description",
            url: repo["url"],
            stars: repo["stargazerCount"],
            forks: repo["forkCount"],
            language: get_in(repo, ["primaryLanguage", "name"]) || "Unknown",
            language_color: get_in(repo, ["primaryLanguage", "color"]),
            topics:
              get_in(repo, ["repositoryTopics", "nodes"])
              |> Kernel.||([])
              |> Enum.map(&get_in(&1, ["topic", "name"]))
          }
        end)

      {:ok, repos}
    else
      {:error, _} = error ->
        error

      _ ->
        {:error, "Failed to parse GitHub GraphQL response"}
    end
  end

  defp parse_rest_response(response_body) do
    case Jason.decode(response_body) do
      {:ok, repos} when is_list(repos) ->
        formatted_repos =
          Enum.map(repos, fn repo ->
            %{
              name: repo["name"],
              description: repo["description"] || "No description",
              url: repo["html_url"],
              stars: repo["stargazers_count"],
              forks: repo["forks_count"],
              language: repo["language"] || "Unknown",
              language_color: nil,
              topics: repo["topics"] || []
            }
          end)

        {:ok, formatted_repos}

      {:ok, _} ->
        {:error, "Unexpected response format"}

      {:error, _} = error ->
        error
    end
  end

  # Cache implementation using ETS
  defp get_cached_repos(username) do
    case :ets.whereis(:github_cache) do
      :undefined ->
        :ets.new(:github_cache, [:named_table, :public, read_concurrency: true])
        :miss

      _table ->
        lookup_cached_repos(username)
    end
  end

  defp cache_repos(username, repos) do
    ensure_cache_table()
    :ets.insert(:github_cache, {username, repos, System.system_time(:millisecond)})
  end

  defp ensure_cache_table do
    case :ets.whereis(:github_cache) do
      :undefined ->
        :ets.new(:github_cache, [:named_table, :public, read_concurrency: true])

      _table ->
        :ok
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

  # REST API helper functions

  defp build_rest_url(path) do
    @github_rest_api_url <> path
  end

  defp rest_api_request(url, retry_count \\ 0) do
    headers = [
      {"accept", "application/vnd.github.v3+json"},
      {"user-agent", "droodotfoo"}
    ]

    headers =
      case github_token() do
        nil -> headers
        token -> [{"authorization", "Bearer #{token}"} | headers]
      end

    case Req.get(url, headers: headers) do
      {:ok, %{status: status}} = _response when status in [500, 502, 503, 504] and retry_count < 3 ->
        # Exponential backoff: 1s, 2s, 4s
        backoff_ms = :math.pow(2, retry_count) * 1000 |> round()
        Logger.warning("GitHub API returned #{status}, retrying in #{backoff_ms}ms (attempt #{retry_count + 1}/3)")
        Process.sleep(backoff_ms)
        rest_api_request(url, retry_count + 1)

      response ->
        response
    end
  rescue
    error ->
      if retry_count < 3 do
        backoff_ms = :math.pow(2, retry_count) * 1000 |> round()
        Logger.warning("GitHub REST API request failed: #{inspect(error)}, retrying in #{backoff_ms}ms (attempt #{retry_count + 1}/3)")
        Process.sleep(backoff_ms)
        rest_api_request(url, retry_count + 1)
      else
        Logger.error("GitHub REST API request failed after #{retry_count} retries: #{inspect(error)}")
        {:error, :request_failed}
      end
  end

  defp github_token do
    case System.get_env("GITHUB_TOKEN") do
      token when token not in [nil, ""] -> token
      _ -> Application.get_env(:droodotfoo, :github_token)
    end
  end

  defp parse_repo_info(body) do
    %{
      stars: body["stargazers_count"] || 0,
      forks: body["forks_count"] || 0,
      watchers: body["watchers_count"] || 0,
      open_issues: body["open_issues_count"] || 0,
      updated_at: body["updated_at"],
      created_at: body["created_at"],
      license: get_in(body, ["license", "name"])
    }
  end

  defp parse_commit_info(commit) do
    message =
      commit
      |> get_in(["commit", "message"])
      |> String.split("\n")
      |> List.first()

    %{
      message: message,
      date: get_in(commit, ["commit", "author", "date"]),
      author: get_in(commit, ["commit", "author", "name"])
    }
  end

  defp parse_release_info(release) do
    %{
      tag: release["tag_name"],
      name: release["name"],
      date: release["published_at"]
    }
  end

  # Private helper functions

  defp lookup_cached_repos(username) do
    case :ets.lookup(:github_cache, username) do
      [{^username, repos, cached_at}] ->
        check_cache_validity(username, repos, cached_at)

      [] ->
        :miss
    end
  end

  defp check_cache_validity(username, repos, cached_at) do
    if System.system_time(:millisecond) - cached_at < @cache_ttl do
      {:ok, repos}
    else
      :ets.delete(:github_cache, username)
      :miss
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
