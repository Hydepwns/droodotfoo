defmodule Droodotfoo.GitHub.ResponseParser do
  @moduledoc """
  Parsers for GitHub API responses.
  """

  @doc """
  Parse repository info from REST API response.
  """
  def parse_repo_info(body) do
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

  @doc """
  Parse commit info from REST API response.
  """
  def parse_commit_info(commit) do
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

  @doc """
  Parse release info from REST API response.
  """
  def parse_release_info(release) do
    %{
      tag: release["tag_name"],
      name: release["name"],
      date: release["published_at"]
    }
  end

  @doc """
  Parse GraphQL pinned repos response.
  """
  def parse_graphql_repos(response_body) do
    with {:ok, json} <- Jason.decode(response_body),
         %{"data" => %{"user" => %{"pinnedItems" => %{"nodes" => nodes}}}} <- json do
      repos = Enum.map(nodes, &format_graphql_repo/1)
      {:ok, repos}
    else
      {:error, _} = error -> error
      _ -> {:error, "Failed to parse GitHub GraphQL response"}
    end
  end

  @doc """
  Parse REST API repos response.
  """
  def parse_rest_repos(response_body) do
    case Jason.decode(response_body) do
      {:ok, repos} when is_list(repos) ->
        {:ok, Enum.map(repos, &format_rest_repo/1)}

      {:ok, _} ->
        {:error, "Unexpected response format"}

      {:error, _} = error ->
        error
    end
  end

  # Private

  defp format_graphql_repo(repo) do
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
  end

  defp format_rest_repo(repo) do
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
  end
end
