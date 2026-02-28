defmodule Droodotfoo.Git do
  @moduledoc """
  Unified git browser interface supporting multiple sources.

  Aggregates repositories from GitHub and Forgejo, allowing
  comparison and mirroring across sources.
  """

  alias Droodotfoo.Git.{GitHub, Forgejo}

  @type source :: :github | :forgejo | :all

  @sources %{
    github: GitHub,
    forgejo: Forgejo
  }

  # ===========================================================================
  # Configuration
  # ===========================================================================

  @doc """
  Get configured sources and their settings.
  """
  def sources do
    %{
      github: %{
        name: "GitHub",
        owner: github_owner(),
        enabled: true
      },
      forgejo: %{
        name: "Forgejo",
        owner: forgejo_owner(),
        enabled: forgejo_enabled?()
      }
    }
  end

  defp github_owner do
    Application.get_env(:droodotfoo, :github)[:owner] || "hydepwns"
  end

  defp forgejo_owner do
    (Application.get_env(:droodotfoo, :forgejo) || [])[:default_owner] || "droo"
  end

  defp forgejo_enabled? do
    case Application.get_env(:droodotfoo, :forgejo) do
      nil -> false
      config -> config[:base_url] != nil
    end
  end

  # ===========================================================================
  # Repository Listing
  # ===========================================================================

  @doc """
  List repositories from one or all sources.

  Options:
  - `:source` - :github, :forgejo, or :all (default: :all)
  - `:limit` - max repos per source (default: 30)
  """
  def list_repos(opts \\ []) do
    source = Keyword.get(opts, :source, :all)
    limit = Keyword.get(opts, :limit, 30)

    case source do
      :all ->
        list_repos_all(limit)

      source when source in [:github, :forgejo] ->
        list_repos_single(source, limit)

      _ ->
        {:error, :invalid_source}
    end
  end

  defp list_repos_all(limit) do
    tasks = [
      Task.async(fn -> list_repos_single(:github, limit) end),
      Task.async(fn -> list_repos_single(:forgejo, limit) end)
    ]

    results =
      tasks
      |> Task.await_many(10_000)
      |> Enum.flat_map(fn
        {:ok, repos} -> repos
        {:error, _} -> []
      end)
      |> Enum.sort_by(& &1.updated_at, :desc)

    {:ok, results}
  end

  defp list_repos_single(source, limit) do
    config = sources()[source]
    module = @sources[source]

    if config.enabled do
      module.list_repos(config.owner, limit: limit)
    else
      {:ok, []}
    end
  end

  # ===========================================================================
  # Single Repo Operations
  # ===========================================================================

  @doc """
  Get a repository by source, owner, and name.
  """
  def get_repo(source, owner, name) when source in [:github, :forgejo] do
    @sources[source].get_repo(owner, name)
  end

  @doc """
  Get directory tree for a path.
  """
  def get_tree(source, owner, repo, branch, path \\ "") when source in [:github, :forgejo] do
    @sources[source].get_tree(owner, repo, branch, path)
  end

  @doc """
  Get file content.
  """
  def get_file(source, owner, repo, branch, path) when source in [:github, :forgejo] do
    @sources[source].get_file(owner, repo, branch, path)
  end

  @doc """
  Get commit history.
  """
  def get_commits(source, owner, repo, branch, opts \\ []) when source in [:github, :forgejo] do
    @sources[source].get_commits(owner, repo, branch, opts)
  end

  @doc """
  List branches.
  """
  def list_branches(source, owner, repo) when source in [:github, :forgejo] do
    @sources[source].list_branches(owner, repo)
  end

  # ===========================================================================
  # Comparison / Mirroring
  # ===========================================================================

  @doc """
  Compare repos across sources to find gaps.

  Returns repos that exist in one source but not the other.
  """
  def compare_repos do
    with {:ok, github_repos} <- list_repos_single(:github, 100),
         {:ok, forgejo_repos} <- list_repos_single(:forgejo, 100) do
      github_names = MapSet.new(github_repos, & &1.name)
      forgejo_names = MapSet.new(forgejo_repos, & &1.name)

      only_github = MapSet.difference(github_names, forgejo_names) |> MapSet.to_list()
      only_forgejo = MapSet.difference(forgejo_names, github_names) |> MapSet.to_list()
      both = MapSet.intersection(github_names, forgejo_names) |> MapSet.to_list()

      {:ok,
       %{
         only_github: only_github,
         only_forgejo: only_forgejo,
         mirrored: both,
         github_total: length(github_repos),
         forgejo_total: length(forgejo_repos)
       }}
    end
  end
end
