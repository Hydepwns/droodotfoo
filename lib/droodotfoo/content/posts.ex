defmodule Droodotfoo.Content.PostManager do
  @moduledoc """
  File-based blog post management system.

  Posts are stored as markdown files in `priv/posts/` with YAML frontmatter.
  Metadata is cached in ETS for performance.
  """

  use GenServer
  require Logger

  @posts_dir Application.compile_env(:droodotfoo, :posts_dir, "priv/posts")
  @table_name :posts_cache

  defmodule Post do
    @moduledoc "Struct representing a blog post"
    defstruct [
      :slug,
      :title,
      :date,
      :description,
      :tags,
      :content,
      :html,
      :read_time
    ]

    @type t :: %__MODULE__{
            slug: String.t(),
            title: String.t(),
            date: Date.t(),
            description: String.t(),
            tags: list(String.t()),
            content: String.t(),
            html: String.t(),
            read_time: integer()
          }
  end

  ## Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "List all posts, sorted by date (newest first)"
  @spec list_posts() :: list(Post.t())
  def list_posts do
    GenServer.call(__MODULE__, :list_posts)
  end

  @doc "Get a single post by slug"
  @spec get_post(String.t()) :: {:ok, Post.t()} | {:error, :not_found}
  def get_post(slug) do
    GenServer.call(__MODULE__, {:get_post, slug})
  end

  @doc "Save a new post from markdown content"
  @spec save_post(String.t(), map()) :: {:ok, Post.t()} | {:error, term()}
  def save_post(content, metadata) do
    GenServer.call(__MODULE__, {:save_post, content, metadata})
  end

  @doc "Reload posts from filesystem"
  def reload do
    GenServer.cast(__MODULE__, :reload)
  end

  ## Server Callbacks

  @impl true
  def init(_opts) do
    # Create ETS table for caching
    :ets.new(@table_name, [:named_table, :set, :protected, read_concurrency: true])

    # Load posts on startup
    send(self(), :load_posts)

    {:ok, %{}}
  end

  @impl true
  def handle_info(:load_posts, state) do
    posts = load_posts_from_disk()
    Logger.info("Loaded #{length(posts)} blog posts")
    {:noreply, state}
  end

  @impl true
  def handle_call(:list_posts, _from, state) do
    posts =
      :ets.tab2list(@table_name)
      |> Enum.map(fn {_slug, post} -> post end)
      |> Enum.sort_by(& &1.date, {:desc, Date})

    {:reply, posts, state}
  end

  def handle_call({:get_post, slug}, _from, state) do
    case :ets.lookup(@table_name, slug) do
      [{^slug, post}] -> {:reply, {:ok, post}, state}
      [] -> {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:save_post, content, metadata}, _from, state) do
    with {:ok, post} <- create_post(content, metadata),
         :ok <- write_post_to_disk(post) do
      :ets.insert(@table_name, {post.slug, post})
      {:reply, {:ok, post}, state}
    else
      error -> {:reply, error, state}
    end
  end

  @impl true
  def handle_cast(:reload, state) do
    load_posts_from_disk()
    {:noreply, state}
  end

  ## Private Functions

  defp load_posts_from_disk do
    posts_path()
    |> File.ls!()
    |> Enum.filter(&String.ends_with?(&1, ".md"))
    |> Enum.map(&load_post_file/1)
    |> Enum.reject(&is_nil/1)
    |> tap(fn posts ->
      Enum.each(posts, fn post ->
        :ets.insert(@table_name, {post.slug, post})
      end)
    end)
  end

  defp load_post_file(filename) do
    path = Path.join(posts_path(), filename)

    case File.read(path) do
      {:ok, content} ->
        parse_post(content, Path.rootname(filename))

      {:error, reason} ->
        Logger.warning("Failed to read post #{filename}: #{inspect(reason)}")
        nil
    end
  end

  defp parse_post(content, default_slug) do
    case extract_frontmatter(content) do
      {:ok, frontmatter, markdown} ->
        slug = Map.get(frontmatter, "slug", default_slug)
        html = MDEx.to_html!(markdown)

        %Post{
          slug: slug,
          title: Map.get(frontmatter, "title", "Untitled"),
          date: parse_date(Map.get(frontmatter, "date")),
          description: Map.get(frontmatter, "description", ""),
          tags: Map.get(frontmatter, "tags", []),
          content: markdown,
          html: html,
          read_time: calculate_read_time(markdown)
        }

      :error ->
        nil
    end
  end

  defp extract_frontmatter(content) do
    case String.split(content, "---\n", parts: 3) do
      ["", yaml, markdown] ->
        case YamlElixir.read_from_string(yaml) do
          {:ok, frontmatter} -> {:ok, frontmatter, String.trim(markdown)}
          _ -> :error
        end

      _ ->
        :error
    end
  end

  defp parse_date(nil), do: Date.utc_today()
  defp parse_date(date) when is_binary(date), do: Date.from_iso8601!(date)
  defp parse_date(%Date{} = date), do: date

  defp calculate_read_time(markdown) do
    words = markdown |> String.split(~r/\s+/) |> length()
    max(1, div(words, 200))
  end

  defp create_post(content, metadata) do
    slug = Map.get(metadata, "slug") || generate_slug(Map.get(metadata, "title", "untitled"))

    frontmatter =
      metadata
      |> Map.put("slug", slug)
      |> Map.put_new("date", Date.to_string(Date.utc_today()))

    markdown =
      case extract_frontmatter(content) do
        {:ok, _existing_fm, body} -> body
        :error -> content
      end

    full_content = build_frontmatter(frontmatter) <> "\n" <> markdown
    parse_post(full_content, slug) |> then(&{:ok, &1})
  end

  defp write_post_to_disk(post) do
    path = Path.join(posts_path(), "#{post.slug}.md")

    frontmatter = %{
      "title" => post.title,
      "date" => Date.to_string(post.date),
      "description" => post.description,
      "tags" => post.tags,
      "slug" => post.slug
    }

    content = build_frontmatter(frontmatter) <> "\n" <> post.content
    File.write(path, content)
  end

  defp build_frontmatter(map) do
    # Manually build YAML frontmatter (YamlElixir is read-only)
    yaml_lines = [
      "title: #{inspect(map["title"])}",
      "date: #{inspect(map["date"])}",
      "description: #{inspect(map["description"])}",
      "tags: #{inspect(map["tags"])}",
      "slug: #{inspect(map["slug"])}"
    ]

    yaml = Enum.join(yaml_lines, "\n")
    "---\n#{yaml}\n---"
  end

  defp generate_slug(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
  end

  defp posts_path do
    Path.join(File.cwd!(), @posts_dir)
  end
end
