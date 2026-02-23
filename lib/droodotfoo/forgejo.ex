defmodule Droodotfoo.Forgejo do
  @moduledoc """
  Forgejo API client for git.droo.foo integration.

  Fetches mirrored repo list to show "mirrored" badges on projects page.
  Tailnet-only - will fail gracefully when not accessible.
  """

  require Logger

  @forgejo_url "http://mini-axol.tail9b2ce8.ts.net:3033"
  @cache_ttl :timer.hours(1)

  @doc """
  Returns list of repo names mirrored on Forgejo.
  Cached for 1 hour. Returns empty list on error.
  """
  @spec list_mirrors() :: [String.t()]
  def list_mirrors do
    case get_cached_mirrors() do
      {:ok, mirrors} -> mirrors
      :miss -> fetch_and_cache_mirrors()
    end
  end

  @doc """
  Checks if a repo name has a Forgejo mirror.
  """
  @spec has_mirror?(String.t()) :: boolean()
  def has_mirror?(repo_name) do
    repo_name in list_mirrors()
  end

  @doc """
  Returns Forgejo URL for a repo if it exists.
  """
  @spec mirror_url(String.t()) :: String.t() | nil
  def mirror_url(repo_name) do
    if has_mirror?(repo_name) do
      "#{@forgejo_url}/droo/#{repo_name}"
    end
  end

  @doc """
  Clears the mirror cache.
  """
  @spec clear_cache() :: :ok
  def clear_cache do
    :persistent_term.erase({__MODULE__, :mirrors})
    :persistent_term.erase({__MODULE__, :cached_at})
    :ok
  rescue
    ArgumentError -> :ok
  end

  # Private

  defp get_cached_mirrors do
    cached_at = :persistent_term.get({__MODULE__, :cached_at}, 0)
    now = System.system_time(:millisecond)

    if now - cached_at < @cache_ttl do
      {:ok, :persistent_term.get({__MODULE__, :mirrors}, [])}
    else
      :miss
    end
  rescue
    ArgumentError -> :miss
  end

  defp fetch_and_cache_mirrors do
    case fetch_repos() do
      {:ok, repos} ->
        mirrors = Enum.map(repos, & &1["name"])
        :persistent_term.put({__MODULE__, :mirrors}, mirrors)
        :persistent_term.put({__MODULE__, :cached_at}, System.system_time(:millisecond))
        mirrors

      {:error, reason} ->
        Logger.debug("Forgejo unavailable: #{inspect(reason)}")
        []
    end
  end

  defp fetch_repos do
    url = "#{@forgejo_url}/api/v1/repos/search?limit=100"

    case Req.get(url, receive_timeout: 2_000, connect_options: [timeout: 1_000]) do
      {:ok, %{status: 200, body: %{"data" => repos}}} ->
        {:ok, repos}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
