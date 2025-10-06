defmodule Droodotfoo.Github.Client do
  @moduledoc """
  GitHub API client for fetching user profile data.
  Uses GraphQL API to fetch pinned repositories.
  """

  require Logger

  @github_api_url "https://api.github.com/graphql"
  @cache_ttl :timer.minutes(15)

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

    case :httpc.request(:post, {String.to_charlist(@github_api_url), headers, ~c"application/json", String.to_charlist(body)}, [], []) do
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
        |> Enum.map(fn {repo, idx} ->
          stars = if repo.stars > 0, do: " [#{repo.stars} stars]", else: ""
          language = "[#{repo.language}]"

          """
          #{idx}. #{repo.name} #{language}#{stars}
             #{repo.description}
             #{repo.url}
          """
        end)
        |> Enum.join("\n")

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
end
