defmodule Wiki.Ingestion.VintageMachineryClient do
  @moduledoc """
  wget-based client for VintageMachinery.org content.

  VintageMachinery is a static HTML site with vintage machinery documentation.
  This client handles:
  - Mirroring the site with wget (initial/incremental sync)
  - Parsing HTML pages to extract content
  - Listing available pages

  ## Configuration

      config :wiki, Wiki.Ingestion.VintageMachineryClient,
        base_url: "https://vintagemachinery.org",
        local_path: "/var/lib/wiki/vintage-machinery",
        rate_limit_ms: 2_000,
        # Directories to mirror (relative to base_url)
        include_paths: ["pubs/", "mfgindex/"]

  """

  require Logger

  @type page :: %{
          slug: String.t(),
          title: String.t(),
          content: String.t(),
          raw_html: String.t(),
          last_modified: DateTime.t() | nil,
          images: [String.t()],
          category: String.t() | nil
        }

  @doc """
  Mirror the VintageMachinery site using wget.

  Returns the local path on success.
  """
  @spec sync_site(keyword()) :: {:ok, String.t()} | {:error, term()}
  def sync_site(opts \\ []) do
    local_path = config(:local_path)
    base_url = config(:base_url)
    include_paths = config(:include_paths) || ["pubs/", "mfgindex/"]

    File.mkdir_p!(local_path)

    args = build_wget_args(local_path, include_paths)
    urls = Enum.map(include_paths, &"#{base_url}/#{&1}")

    log_sync_start(opts, local_path)

    case System.cmd("wget", args ++ urls, stderr_to_stdout: true, into: IO.stream()) do
      {_output, code} when code in [0, 8] ->
        Logger.info("VintageMachinery sync completed")
        {:ok, local_path}

      {output, code} ->
        Logger.error("VintageMachinery sync failed (exit #{code})")
        {:error, {:wget_failed, code, output}}
    end
  end

  defp build_wget_args(local_path, include_paths) do
    rate_limit = config(:rate_limit_ms) || 2_000

    base_args = [
      "--mirror",
      "--convert-links",
      "--adjust-extension",
      "--page-requisites",
      "--no-parent",
      "--wait=#{div(rate_limit, 1000)}",
      "--random-wait",
      "--user-agent=DrooFoo-WikiMirror/1.0 (https://droo.foo)",
      "--directory-prefix=#{local_path}",
      "--timestamping",
      "--level=5"
    ]

    include_args = Enum.flat_map(include_paths, &["--include-directories=#{&1}"])
    incremental_args = if has_existing_content?(local_path), do: ["--no-clobber"], else: []

    base_args ++ include_args ++ incremental_args
  end

  defp log_sync_start(opts, local_path) do
    case Keyword.get(opts, :full, false) do
      true -> Logger.info("Starting full VintageMachinery mirror to #{local_path}")
      false -> Logger.info("Starting incremental VintageMachinery sync to #{local_path}")
    end
  end

  @doc """
  List all HTML pages in the mirrored site.

  Returns slugs derived from file paths.
  """
  @spec list_pages() :: {:ok, [String.t()]} | {:error, term()}
  def list_pages do
    with {:ok, site_dir} <- get_site_dir() do
      pages =
        site_dir
        |> find_html_files()
        |> Enum.map(&path_to_slug(site_dir, &1))
        |> Enum.sort()

      {:ok, pages}
    end
  end

  @doc """
  List pages modified since a given timestamp.

  Uses file mtime to determine recently changed files.
  """
  @spec list_modified_pages(DateTime.t()) :: {:ok, [String.t()]} | {:error, term()}
  def list_modified_pages(since) do
    since_unix = DateTime.to_unix(since)

    with {:ok, site_dir} <- get_site_dir() do
      pages =
        site_dir
        |> find_html_files()
        |> Enum.filter(&modified_after?(&1, since_unix))
        |> Enum.map(&path_to_slug(site_dir, &1))
        |> Enum.sort()

      {:ok, pages}
    end
  end

  defp modified_after?(path, since_unix) do
    case File.stat(path) do
      {:ok, %{mtime: mtime}} ->
        mtime
        |> NaiveDateTime.from_erl!()
        |> DateTime.from_naive!("Etc/UTC")
        |> DateTime.to_unix()
        |> Kernel.>(since_unix)

      _ ->
        false
    end
  end

  defp get_site_dir do
    local_path = config(:local_path)
    site_dir = find_site_dir(local_path)

    if site_dir && File.dir?(site_dir) do
      {:ok, site_dir}
    else
      {:error, :site_dir_not_found}
    end
  end

  @doc """
  Read and parse a single page by slug.
  """
  @spec get_page(String.t()) :: {:ok, page()} | {:error, term()}
  def get_page(slug) do
    with {:ok, site_dir} <- get_site_dir(),
         file_path = slug_to_path(site_dir, slug),
         {:ok, html, actual_path} <- read_page_file(file_path) do
      {:ok, parse_page(slug, html, actual_path)}
    end
  end

  defp read_page_file(path) do
    case File.read(path) do
      {:ok, html} ->
        {:ok, html, path}

      {:error, :enoent} ->
        read_page_file_with_extension(path)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp read_page_file_with_extension(path) do
    html_path = path <> ".html"

    case File.read(html_path) do
      {:ok, html} -> {:ok, html, html_path}
      {:error, :enoent} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  # Private functions

  defp has_existing_content?(path) do
    match?({:ok, [_ | _]}, File.ls(path))
  end

  defp find_site_dir(local_path) do
    # wget creates a directory named after the domain
    possible_dirs = [
      Path.join(local_path, "vintagemachinery.org"),
      Path.join(local_path, "www.vintagemachinery.org")
    ]

    Enum.find(possible_dirs, &File.dir?/1) || local_path
  end

  @excluded_dirs ~w(/images/ /css/ /js/)

  defp find_html_files(dir) do
    dir
    |> Path.join("**/*.{html,htm}")
    |> Path.wildcard()
    |> Enum.reject(&contains_excluded_dir?/1)
  end

  defp contains_excluded_dir?(path) do
    Enum.any?(@excluded_dirs, &String.contains?(path, &1))
  end

  defp path_to_slug(site_dir, path) do
    path
    |> String.replace_prefix(site_dir <> "/", "")
    |> String.replace_suffix(".html", "")
    |> String.replace_suffix(".htm", "")
    |> String.replace("/", "__")
  end

  defp slug_to_path(site_dir, slug) do
    relative = String.replace(slug, "__", "/")
    Path.join(site_dir, relative)
  end

  defp parse_page(slug, html, file_path) do
    {:ok, doc} = Floki.parse_document(html)

    title = extract_title(doc, slug)
    content = extract_content(doc)
    images = extract_images(doc)
    category = extract_category(slug)
    last_modified = get_file_mtime(file_path)

    %{
      slug: slug,
      title: title,
      content: content,
      raw_html: html,
      images: images,
      category: category,
      last_modified: last_modified
    }
  end

  defp extract_title(doc, fallback_slug) do
    case Floki.find(doc, "title") do
      [{_, _, [title]}] -> String.trim(title)
      _ -> humanize_slug(fallback_slug)
    end
  end

  defp extract_content(doc) do
    # Try common content containers
    content_selectors = [
      "#content",
      "#main-content",
      ".content",
      "main",
      "article",
      "body"
    ]

    Enum.find_value(content_selectors, fn selector ->
      case Floki.find(doc, selector) do
        [element | _] ->
          element
          |> Floki.text(sep: " ")
          |> String.replace(~r/\s+/, " ")
          |> String.trim()

        [] ->
          nil
      end
    end) || ""
  end

  defp extract_images(doc) do
    doc
    |> Floki.find("img")
    |> Enum.map(fn {_, attrs, _} ->
      Enum.find_value(attrs, fn
        {"src", src} -> src
        _ -> nil
      end)
    end)
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&String.starts_with?(&1, "data:"))
  end

  defp extract_category(slug) do
    cond do
      String.starts_with?(slug, "pubs__") -> "publications"
      String.starts_with?(slug, "mfgindex__") -> "manufacturers"
      true -> nil
    end
  end

  defp humanize_slug(slug) do
    slug
    |> String.replace("__", " - ")
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
    Application.get_env(:wiki, __MODULE__, [])
    |> Keyword.get(key)
  end
end
