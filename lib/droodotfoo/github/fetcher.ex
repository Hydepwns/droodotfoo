defmodule Droodotfoo.GitHub.Fetcher do
  @moduledoc """
  Background GenServer that periodically fetches and caches GitHub data.
  Runs on startup and then hourly to keep project data fresh.
  """

  use GenServer
  require Logger

  alias Droodotfoo.GitHub.Cache
  alias Droodotfoo.GitHub.Client
  alias Droodotfoo.Projects

  @refresh_interval :timer.hours(1)

  ## Client API

  @doc """
  Starts the fetcher GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Manually triggers a refresh of all GitHub data.
  """
  @spec refresh() :: :ok
  def refresh do
    GenServer.cast(__MODULE__, :refresh)
  end

  ## GenServer Callbacks

  @impl true
  def init(_opts) do
    send(self(), :initial_fetch)
    Logger.info("GitHub fetcher initialized")
    {:ok, %{}}
  end

  @impl true
  def handle_info(:initial_fetch, state) do
    Logger.info("Starting initial GitHub data fetch...")
    fetch_all_projects()
    schedule_refresh()
    {:noreply, state}
  end

  @impl true
  def handle_info(:refresh, state) do
    Logger.info("Refreshing GitHub data...")
    fetch_all_projects()
    schedule_refresh()
    {:noreply, state}
  end

  @impl true
  def handle_cast(:refresh, state) do
    Logger.info("Manual refresh triggered...")
    fetch_all_projects()
    {:noreply, state}
  end

  ## Private Functions

  defp fetch_all_projects do
    Projects.all()
    |> Enum.filter(&has_github_url?/1)
    |> Task.async_stream(&fetch_project_data/1,
      max_concurrency: 3,
      timeout: 10_000,
      on_timeout: :kill_task
    )
    |> Enum.to_list()
    |> then(fn results ->
      success_count = Enum.count(results, &match?({:ok, :ok}, &1))
      error_count = Enum.count(results, &match?({:ok, {:error, _}}, &1))
      timeout_count = Enum.count(results, &match?({:exit, :timeout}, &1))

      Logger.info(
        "GitHub data fetch complete: #{success_count} success, #{error_count} errors, #{timeout_count} timeouts"
      )
    end)
  end

  defp has_github_url?(%{github_url: url}) when is_binary(url) do
    String.contains?(url, "github.com")
  end

  defp has_github_url?(_), do: false

  defp fetch_project_data(project) do
    with {:ok, {owner, repo}} <- Client.parse_github_url(project.github_url),
         {:ok, data} <- fetch_combined_data(owner, repo) do
      cache_key = {owner, repo}
      Cache.put(cache_key, data)
      Logger.debug("Cached GitHub data for #{owner}/#{repo}")
      :ok
    else
      {:error, reason} ->
        Logger.warning("Failed to fetch GitHub data for #{project.name}: #{inspect(reason)}")

        {:error, reason}
    end
  end

  defp fetch_combined_data(owner, repo) do
    # Fetch all data in parallel
    tasks = [
      Task.async(fn -> {:repo_info, Client.get_repo_info(owner, repo)} end),
      Task.async(fn -> {:languages, Client.get_languages(owner, repo)} end),
      Task.async(fn -> {:latest_commit, Client.get_latest_commit(owner, repo)} end),
      Task.async(fn -> {:latest_release, Client.get_latest_release(owner, repo)} end)
    ]

    results =
      tasks
      |> Task.await_many(10_000)
      |> Map.new()

    # Combine results, treating 404s as optional data
    case results[:repo_info] do
      {:ok, repo_info} ->
        data = %{
          repo_info: repo_info,
          languages: extract_ok(results[:languages]),
          latest_commit: extract_ok(results[:latest_commit]),
          latest_release: extract_ok(results[:latest_release])
        }

        {:ok, data}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp extract_ok({:ok, data}), do: data
  defp extract_ok(_), do: nil

  defp schedule_refresh do
    Process.send_after(self(), :refresh, @refresh_interval)
  end
end
