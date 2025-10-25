defmodule Droodotfoo.GitHub do
  @moduledoc """
  Public API facade for GitHub integration.
  Provides hybrid cached/real-time access to GitHub repository data.
  """

  require Logger

  alias Droodotfoo.GitHub.Cache
  alias Droodotfoo.GitHub.Client
  alias Droodotfoo.Projects

  @type github_data :: %{
          repo_info: Client.repo_info() | nil,
          languages: Client.language_breakdown() | nil,
          latest_commit: Client.commit_info() | nil,
          latest_release: Client.release_info() | nil,
          cached_at: integer() | nil,
          status: :ok | :loading | :error | :rate_limited | :unauthorized | :not_found,
          error_message: String.t() | nil
        }

  @doc """
  Enriches a project with GitHub data.

  Checks cache first, falls back to real-time fetch if cache miss.
  Returns the project unchanged if GitHub data cannot be fetched.
  """
  @spec enrich_project(Projects.t()) :: Projects.t()
  def enrich_project(%Projects{github_url: url} = project) when is_binary(url) do
    case Client.parse_github_url(url) do
      {:ok, {owner, repo}} ->
        github_data = get_or_fetch_data(owner, repo)
        Map.put(project, :github_data, github_data)

      {:error, _} ->
        project
    end
  end

  def enrich_project(project), do: project

  @doc """
  Enriches multiple projects with GitHub data in parallel.
  """
  @spec enrich_projects([Projects.t()]) :: [Projects.t()]
  def enrich_projects(projects) when is_list(projects) do
    projects
    |> Task.async_stream(&enrich_project/1,
      max_concurrency: 5,
      timeout: 5_000,
      on_timeout: :kill_task
    )
    |> Enum.map(fn
      {:ok, enriched_project} -> enriched_project
      {:exit, :timeout} -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Gets GitHub data with cache-first strategy.
  """
  @spec get_or_fetch_data(String.t(), String.t()) :: github_data() | nil
  def get_or_fetch_data(owner, repo) do
    cache_key = {owner, repo}

    case Cache.get(cache_key) do
      {:ok, data, cached_at} ->
        Logger.debug("Cache hit for #{owner}/#{repo}")

        data
        |> Map.put(:cached_at, cached_at)
        |> Map.put_new(:status, :ok)
        |> Map.put_new(:error_message, nil)

      :miss ->
        Logger.debug("Cache miss for #{owner}/#{repo}, fetching from GitHub...")
        fetch_and_cache(owner, repo)
    end
  end

  @doc """
  Clears all cached GitHub data.
  """
  @spec clear_cache() :: :ok
  def clear_cache do
    Cache.clear()
  end

  @doc """
  Forces a refresh of GitHub data for a specific repository.
  Clears the cache and fetches fresh data.
  """
  @spec force_refresh(String.t(), String.t()) :: github_data() | nil
  def force_refresh(owner, repo) do
    cache_key = {owner, repo}
    Cache.delete(cache_key)
    fetch_and_cache(owner, repo)
  end

  ## Private Functions

  defp fetch_and_cache(owner, repo) do
    case fetch_combined_data(owner, repo) do
      {:ok, data} ->
        cache_key = {owner, repo}
        Cache.put(cache_key, data)
        data

      {:error, reason} ->
        Logger.warning("Failed to fetch GitHub data for #{owner}/#{repo}: #{inspect(reason)}")
        build_error_data(reason)
    end
  end

  defp fetch_combined_data(owner, repo) do
    # Fetch all data in parallel with timeouts
    tasks = [
      Task.async(fn -> {:repo_info, Client.get_repo_info(owner, repo)} end),
      Task.async(fn -> {:languages, Client.get_languages(owner, repo)} end),
      Task.async(fn -> {:latest_commit, Client.get_latest_commit(owner, repo)} end),
      Task.async(fn -> {:latest_release, Client.get_latest_release(owner, repo)} end)
    ]

    results =
      tasks
      |> Task.await_many(5_000)
      |> Map.new()

    # Require at least repo_info to succeed
    case results[:repo_info] do
      {:ok, repo_info} ->
        data = %{
          repo_info: repo_info,
          languages: extract_ok(results[:languages]),
          latest_commit: extract_ok(results[:latest_commit]),
          latest_release: extract_ok(results[:latest_release]),
          cached_at: System.system_time(:millisecond),
          status: :ok,
          error_message: nil
        }

        {:ok, data}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_ok({:ok, data}), do: data
  defp extract_ok(_), do: nil

  defp build_error_data(reason) do
    {status, message} =
      case reason do
        :unauthorized ->
          {:unauthorized, "Repository is private or requires authentication"}

        :not_found ->
          {:not_found, "Repository not found"}

        :rate_limited ->
          {:rate_limited, "GitHub API rate limit exceeded - data refreshes hourly"}

        _ ->
          {:error, "Unable to fetch GitHub data"}
      end

    %{
      repo_info: nil,
      languages: nil,
      latest_commit: nil,
      latest_release: nil,
      cached_at: System.system_time(:millisecond),
      status: status,
      error_message: message
    }
  end
end
