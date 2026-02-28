defmodule Droodotfoo.Git.GitHub do
  @moduledoc """
  GitHub source adapter for the git browser.

  Uses GitHub REST API to browse repos, files, and commits.
  """

  @behaviour Droodotfoo.Git.Source

  require Logger

  @base_url "https://api.github.com"
  @timeout 15_000

  # ===========================================================================
  # Source Callbacks
  # ===========================================================================

  @impl true
  def list_repos(owner, opts \\ []) do
    limit = Keyword.get(opts, :limit, 30)
    page = Keyword.get(opts, :page, 1)

    case get("/users/#{owner}/repos", %{per_page: limit, page: page, sort: "updated"}) do
      {:ok, data} when is_list(data) ->
        repos = Enum.map(data, &parse_repo/1)
        {:ok, repos}

      error ->
        error
    end
  end

  @impl true
  def get_repo(owner, name) do
    case get("/repos/#{owner}/#{name}") do
      {:ok, data} when is_map(data) ->
        {:ok, parse_repo(data)}

      error ->
        error
    end
  end

  @impl true
  def get_tree(owner, repo, branch, path \\ "") do
    api_path =
      if path == "" do
        "/repos/#{owner}/#{repo}/contents"
      else
        "/repos/#{owner}/#{repo}/contents/#{path}"
      end

    case get(api_path, %{ref: branch}) do
      {:ok, data} when is_list(data) ->
        entries = Enum.map(data, &parse_tree_entry/1)
        {:ok, entries}

      {:ok, data} when is_map(data) ->
        # Single file returned
        {:ok, [parse_tree_entry(data)]}

      error ->
        error
    end
  end

  @impl true
  def get_file(owner, repo, branch, path) do
    case get("/repos/#{owner}/#{repo}/contents/#{path}", %{ref: branch}) do
      {:ok, data} when is_map(data) ->
        if data["type"] == "file" do
          {:ok, parse_file_content(data)}
        else
          {:error, :is_directory}
        end

      {:ok, _} ->
        {:error, :is_directory}

      error ->
        error
    end
  end

  @impl true
  def get_commits(owner, repo, branch, opts \\ []) do
    limit = Keyword.get(opts, :limit, 30)
    page = Keyword.get(opts, :page, 1)
    path = Keyword.get(opts, :path)

    params = %{sha: branch, per_page: limit, page: page}
    params = if path, do: Map.put(params, :path, path), else: params

    case get("/repos/#{owner}/#{repo}/commits", params) do
      {:ok, data} when is_list(data) ->
        commits = Enum.map(data, &parse_commit/1)
        {:ok, commits}

      error ->
        error
    end
  end

  @impl true
  def list_branches(owner, repo) do
    case get("/repos/#{owner}/#{repo}/branches") do
      {:ok, data} when is_list(data) ->
        branches = Enum.map(data, & &1["name"])
        {:ok, branches}

      error ->
        error
    end
  end

  # ===========================================================================
  # HTTP Client
  # ===========================================================================

  defp get(path, params \\ %{}) do
    url = build_url(path, params)

    request_opts = [
      url: url,
      receive_timeout: @timeout,
      headers: headers()
    ]

    case Req.get(request_opts) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: 404}} ->
        {:error, :not_found}

      {:ok, %Req.Response{status: 403, body: body}} ->
        if body["message"] =~ "rate limit" do
          {:error, :rate_limited}
        else
          {:error, {:http_error, 403, body}}
        end

      {:ok, %Req.Response{status: status, body: body}} ->
        Logger.warning("GitHub API error: status=#{status} path=#{path}")
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        Logger.warning("GitHub API request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp build_url(path, params) when map_size(params) == 0 do
    "#{@base_url}#{path}"
  end

  defp build_url(path, params) do
    query = URI.encode_query(params)
    "#{@base_url}#{path}?#{query}"
  end

  defp headers do
    base = [
      {"accept", "application/vnd.github.v3+json"},
      {"user-agent", "droo.foo-git-browser"}
    ]

    case Application.get_env(:droodotfoo, :github_token) do
      nil -> base
      "" -> base
      token -> [{"authorization", "Bearer #{token}"} | base]
    end
  end

  # ===========================================================================
  # Parsers
  # ===========================================================================

  defp parse_repo(data) do
    %{
      name: data["name"],
      full_name: data["full_name"],
      description: data["description"],
      default_branch: data["default_branch"] || "main",
      stars: data["stargazers_count"] || 0,
      forks: data["forks_count"] || 0,
      updated_at: data["updated_at"],
      html_url: data["html_url"],
      clone_url: data["clone_url"],
      language: data["language"],
      private: data["private"] || false,
      archived: data["archived"] || false,
      source: :github
    }
  end

  defp parse_tree_entry(data) do
    %{
      name: data["name"],
      path: data["path"],
      type: if(data["type"] == "dir", do: :dir, else: :file),
      size: data["size"],
      sha: data["sha"]
    }
  end

  defp parse_file_content(data) do
    content =
      case data["encoding"] do
        "base64" ->
          data["content"]
          |> String.replace(~r/\s/, "")
          |> Base.decode64!()

        _ ->
          data["content"] || ""
      end

    %{
      content: content,
      size: data["size"] || byte_size(content),
      encoding: data["encoding"],
      sha: data["sha"]
    }
  end

  defp parse_commit(data) do
    commit_data = data["commit"] || %{}
    author = commit_data["author"] || data["author"] || %{}

    %{
      sha: data["sha"],
      short_sha: String.slice(data["sha"] || "", 0..6),
      message: commit_data["message"] || "",
      author: author["name"] || author["login"] || "unknown",
      email: author["email"],
      date: author["date"] || commit_data["committer"]["date"],
      html_url: data["html_url"]
    }
  end
end
