defmodule Droodotfoo.Github.API do
  @moduledoc """
  GitHub API client using public API endpoints.
  No authentication required for basic operations.
  """

  require Logger
  alias Droodotfoo.HttpClient

  @base_url "https://api.github.com"
  @user_agent "droodotfoo-terminal/1.0"

  @doc """
  Get user profile information.
  """
  def get_user(username) do
    case make_request(:get, "/users/#{username}") do
      {:ok, %{body: user_data}} ->
        {:ok, parse_user(user_data)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get user's public repositories.
  """
  def get_user_repos(username, opts \\ []) do
    sort = Keyword.get(opts, :sort, "updated")
    per_page = Keyword.get(opts, :per_page, 30)

    case make_request(:get, "/users/#{username}/repos?sort=#{sort}&per_page=#{per_page}") do
      {:ok, %{body: repos_data}} ->
        repos = Enum.map(repos_data, &parse_repo/1)
        {:ok, repos}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get user's public events (activity feed).
  """
  def get_user_events(username, opts \\ []) do
    per_page = Keyword.get(opts, :per_page, 30)

    case make_request(:get, "/users/#{username}/events/public?per_page=#{per_page}") do
      {:ok, %{body: events_data}} ->
        events = Enum.map(events_data, &parse_event/1)
        {:ok, events}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Search repositories.
  """
  def search_repos(query, opts \\ []) do
    sort = Keyword.get(opts, :sort, "stars")
    order = Keyword.get(opts, :order, "desc")
    per_page = Keyword.get(opts, :per_page, 20)

    encoded_query = URI.encode(query)
    endpoint = "/search/repositories?q=#{encoded_query}&sort=#{sort}&order=#{order}&per_page=#{per_page}"

    case make_request(:get, endpoint) do
      {:ok, %{body: %{"items" => items}}} ->
        repos = Enum.map(items, &parse_repo/1)
        {:ok, repos}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get trending repositories (simulated via search with recent stars).
  """
  def get_trending(language \\ nil, opts \\ []) do
    per_page = Keyword.get(opts, :per_page, 20)

    # Get repos created in last week with most stars
    date = Date.utc_today() |> Date.add(-7) |> Date.to_string()
    query = "created:>#{date}" <> if(language, do: " language:#{language}", else: "")

    search_repos(query, sort: "stars", order: "desc", per_page: per_page)
  end

  @doc """
  Get repository details.
  """
  def get_repo(owner, repo_name) do
    case make_request(:get, "/repos/#{owner}/#{repo_name}") do
      {:ok, %{body: repo_data}} ->
        {:ok, parse_repo(repo_data)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get repository commits.
  """
  def get_repo_commits(owner, repo_name, opts \\ []) do
    per_page = Keyword.get(opts, :per_page, 30)

    case make_request(:get, "/repos/#{owner}/#{repo_name}/commits?per_page=#{per_page}") do
      {:ok, %{body: commits_data}} ->
        commits = Enum.map(commits_data, &parse_commit/1)
        {:ok, commits}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get repository issues.
  """
  def get_repo_issues(owner, repo_name, opts \\ []) do
    state = Keyword.get(opts, :state, "open")
    per_page = Keyword.get(opts, :per_page, 30)

    case make_request(:get, "/repos/#{owner}/#{repo_name}/issues?state=#{state}&per_page=#{per_page}") do
      {:ok, %{body: issues_data}} ->
        issues = Enum.map(issues_data, &parse_issue/1)
        {:ok, issues}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get repository pull requests.
  """
  def get_repo_pulls(owner, repo_name, opts \\ []) do
    state = Keyword.get(opts, :state, "open")
    per_page = Keyword.get(opts, :per_page, 30)

    case make_request(:get, "/repos/#{owner}/#{repo_name}/pulls?state=#{state}&per_page=#{per_page}") do
      {:ok, %{body: pulls_data}} ->
        pulls = Enum.map(pulls_data, &parse_pull/1)
        {:ok, pulls}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private Functions

  defp client do
    HttpClient.new(
      @base_url,
      [
        {"user-agent", @user_agent},
        {"accept", "application/vnd.github+json"},
        {"x-github-api-version", "2022-11-28"}
      ]
    )
  end

  defp make_request(method, endpoint) do
    http_client = client()
    HttpClient.request(http_client, method: method, url: endpoint)
  end

  # Parsing Functions

  defp parse_user(data) do
    %{
      login: data["login"],
      name: data["name"],
      bio: data["bio"],
      location: data["location"],
      company: data["company"],
      blog: data["blog"],
      email: data["email"],
      avatar_url: data["avatar_url"],
      public_repos: data["public_repos"],
      public_gists: data["public_gists"],
      followers: data["followers"],
      following: data["following"],
      created_at: data["created_at"],
      updated_at: data["updated_at"]
    }
  end

  defp parse_repo(data) do
    %{
      id: data["id"],
      name: data["name"],
      full_name: data["full_name"],
      description: data["description"],
      owner: %{
        login: data["owner"]["login"],
        avatar_url: data["owner"]["avatar_url"]
      },
      html_url: data["html_url"],
      language: data["language"],
      stargazers_count: data["stargazers_count"],
      watchers_count: data["watchers_count"],
      forks_count: data["forks_count"],
      open_issues_count: data["open_issues_count"],
      created_at: data["created_at"],
      updated_at: data["updated_at"],
      pushed_at: data["pushed_at"],
      size: data["size"],
      default_branch: data["default_branch"],
      topics: data["topics"] || []
    }
  end

  defp parse_event(data) do
    %{
      id: data["id"],
      type: data["type"],
      actor: %{
        login: data["actor"]["login"],
        avatar_url: data["actor"]["avatar_url"]
      },
      repo: %{
        name: data["repo"]["name"]
      },
      payload: data["payload"],
      created_at: data["created_at"]
    }
  end

  defp parse_commit(data) do
    %{
      sha: data["sha"],
      message: data["commit"]["message"],
      author: %{
        name: data["commit"]["author"]["name"],
        email: data["commit"]["author"]["email"],
        date: data["commit"]["author"]["date"]
      },
      committer: %{
        name: data["commit"]["committer"]["name"],
        email: data["commit"]["committer"]["email"],
        date: data["commit"]["committer"]["date"]
      },
      html_url: data["html_url"]
    }
  end

  defp parse_issue(data) do
    %{
      number: data["number"],
      title: data["title"],
      state: data["state"],
      user: %{
        login: data["user"]["login"]
      },
      labels: Enum.map(data["labels"] || [], fn label -> label["name"] end),
      created_at: data["created_at"],
      updated_at: data["updated_at"],
      html_url: data["html_url"],
      comments: data["comments"]
    }
  end

  defp parse_pull(data) do
    %{
      number: data["number"],
      title: data["title"],
      state: data["state"],
      user: %{
        login: data["user"]["login"]
      },
      created_at: data["created_at"],
      updated_at: data["updated_at"],
      html_url: data["html_url"],
      merged: data["merged"],
      draft: data["draft"]
    }
  end
end
