defmodule Droodotfoo.Wiki.Ingestion.NLabClient do
  @moduledoc """
  Git-based client for nLab wiki content.

  nLab stores its pages in a git repository. This client handles:
  - Cloning the repository (initial sync)
  - Pulling updates (incremental sync)
  - Parsing page files (markdown with itex math)

  ## Configuration

      config :droodotfoo, Droodotfoo.Wiki.Ingestion.NLabClient,
        repo_url: "https://github.com/ncatlab/nlab-content.git",
        local_path: "/var/lib/wiki/nlab-content",
        branch: "master"

  """

  require Logger

  @type page :: %{
          slug: String.t(),
          title: String.t(),
          content: String.t(),
          categories: [String.t()],
          last_modified: DateTime.t() | nil
        }

  @doc """
  Ensure the nLab repository is cloned and up to date.
  """
  @spec sync_repo() :: {:ok, String.t()} | {:error, term()}
  def sync_repo do
    local_path = config(:local_path)
    repo_url = config(:repo_url)
    branch = config(:branch) || "master"

    result =
      if File.dir?(Path.join(local_path, ".git")) do
        pull_repo(local_path, branch)
      else
        clone_repo(repo_url, local_path, branch)
      end

    case result do
      {:ok, path} ->
        {:ok, count} = build_index()
        Logger.info("Built nLab index with #{count} pages")
        {:ok, path}

      error ->
        error
    end
  end

  @doc """
  List all pages in the repository.
  """
  @spec list_pages() :: {:ok, [String.t()]} | {:error, term()}
  def list_pages do
    local_path = config(:local_path)
    pages_dir = Path.join(local_path, "pages")

    if File.dir?(pages_dir) do
      {output, 0} =
        System.cmd("find", [pages_dir, "-type", "f", "-name", "name"], stderr_to_stdout: true)

      pages =
        output
        |> String.split("\n", trim: true)
        |> Enum.map(fn name_path ->
          name_path
          |> File.read!()
          |> String.trim()
        end)
        |> Enum.sort()

      {:ok, pages}
    else
      {:error, :pages_dir_not_found}
    end
  end

  @doc """
  Get pages modified since a given timestamp.
  """
  @spec list_modified_pages(DateTime.t()) :: {:ok, [String.t()]} | {:error, term()}
  def list_modified_pages(since) do
    local_path = config(:local_path)
    since_str = DateTime.to_iso8601(since)

    case System.cmd(
           "git",
           ["log", "--since=#{since_str}", "--name-only", "--pretty=format:", "--", "pages/"],
           cd: local_path,
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        modified_dirs =
          output
          |> String.split("\n", trim: true)
          |> Enum.filter(&String.ends_with?(&1, "/content.md"))
          |> Enum.map(&Path.dirname/1)
          |> Enum.uniq()

        pages =
          modified_dirs
          |> Enum.map(fn dir ->
            name_path = Path.join([local_path, dir, "name"])
            if File.exists?(name_path), do: File.read!(name_path) |> String.trim()
          end)
          |> Enum.reject(&is_nil/1)
          |> Enum.sort()

        {:ok, pages}

      {error, _code} ->
        {:error, {:git_log_failed, error}}
    end
  end

  @doc """
  Read and parse a single page by slug.
  """
  @spec get_page(String.t()) :: {:ok, page()} | {:error, term()}
  def get_page(slug) do
    case find_page_dir(slug) do
      {:ok, page_dir} ->
        content_path = Path.join(page_dir, "content.md")

        case File.read(content_path) do
          {:ok, content} ->
            page = parse_page(slug, content, content_path)
            {:ok, page}

          {:error, reason} ->
            {:error, reason}
        end

      :not_found ->
        {:error, :not_found}
    end
  end

  @doc """
  Build and cache an index of page slugs to their directory paths.
  """
  def build_index do
    local_path = config(:local_path)
    pages_dir = Path.join(local_path, "pages")

    {output, 0} =
      System.cmd("find", [pages_dir, "-type", "f", "-name", "name"], stderr_to_stdout: true)

    index =
      output
      |> String.split("\n", trim: true)
      |> Enum.map(fn name_path ->
        slug = name_path |> File.read!() |> String.trim()
        page_dir = Path.dirname(name_path)
        {slug, page_dir}
      end)
      |> Map.new()

    :persistent_term.put({__MODULE__, :index}, index)
    {:ok, map_size(index)}
  end

  defp find_page_dir(slug) do
    case :persistent_term.get({__MODULE__, :index}, nil) do
      nil ->
        {:ok, _count} = build_index()
        find_page_dir(slug)

      index ->
        case Map.fetch(index, slug) do
          {:ok, dir} -> {:ok, dir}
          :error -> :not_found
        end
    end
  end

  @doc """
  Get multiple pages by slug.
  """
  @spec get_pages([String.t()]) :: %{String.t() => page()}
  def get_pages(slugs) do
    slugs
    |> Enum.map(fn slug ->
      case get_page(slug) do
        {:ok, page} -> {slug, page}
        {:error, _} -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
  end

  # Private functions

  defp clone_repo(url, path, branch) do
    File.mkdir_p!(Path.dirname(path))

    case System.cmd(
           "git",
           ["clone", "--branch", branch, "--single-branch", "--depth", "1", url, path],
           stderr_to_stdout: true
         ) do
      {_output, 0} ->
        Logger.info("Cloned nLab repository to #{path}")
        {:ok, path}

      {error, code} ->
        Logger.error("Failed to clone nLab repo (exit #{code}): #{error}")
        {:error, {:clone_failed, code, error}}
    end
  end

  defp pull_repo(path, branch) do
    case System.cmd("git", ["pull", "origin", branch], cd: path, stderr_to_stdout: true) do
      {_output, 0} ->
        Logger.debug("Pulled latest nLab changes")
        {:ok, path}

      {error, code} ->
        Logger.error("Failed to pull nLab repo (exit #{code}): #{error}")
        {:error, {:pull_failed, code, error}}
    end
  end

  defp parse_page(slug, content, file_path) do
    {frontmatter, body} = extract_frontmatter(content)

    title = frontmatter["title"] || humanize_slug(slug)
    categories = parse_categories(frontmatter["categories"])
    last_modified = get_file_mtime(file_path)

    %{
      slug: slug,
      title: title,
      content: body,
      categories: categories,
      last_modified: last_modified
    }
  end

  defp extract_frontmatter(content) do
    case Regex.run(~r/\A---\n(.+?)\n---\n(.*)\z/s, content) do
      [_, frontmatter_str, body] ->
        frontmatter = parse_yaml_frontmatter(frontmatter_str)
        {frontmatter, body}

      nil ->
        {%{}, content}
    end
  end

  defp parse_yaml_frontmatter(str) do
    str
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn line ->
      case String.split(line, ":", parts: 2) do
        [key, value] -> {String.trim(key), String.trim(value)}
        _ -> nil
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
  end

  defp parse_categories(nil), do: []
  defp parse_categories(""), do: []

  defp parse_categories(str) when is_binary(str) do
    str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp humanize_slug(slug) do
    slug
    |> String.replace(~r/[-_]/, " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp get_file_mtime(path) do
    case File.stat(path) do
      {:ok, %{mtime: mtime}} ->
        mtime
        |> NaiveDateTime.from_erl!()
        |> DateTime.from_naive!("Etc/UTC")

      _ ->
        nil
    end
  end

  defp config(key) do
    Application.get_env(:droodotfoo, __MODULE__, [])
    |> Keyword.get(key)
  end
end
