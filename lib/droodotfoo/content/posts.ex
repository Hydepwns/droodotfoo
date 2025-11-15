defmodule Droodotfoo.Content.Posts do
  @moduledoc """
  File-based blog post system.

  Posts are stored as markdown files in `priv/posts/` with YAML frontmatter.
  Metadata is cached in ETS for performance.

  ## Features

  - **Syntax Highlighting**: Code blocks are automatically highlighted using Autumn (OneDark theme)
  - **Extended Markdown**: Supports tables, footnotes, strikethrough, task lists, and autolinks
  - **Images**: Store images in `/priv/static/images/posts/` and reference with `![alt text](/images/posts/filename.png)`
  - **Series Support**: Group related posts together with series navigation
  - **Social Sharing**: Automatic Open Graph images via pattern generation or custom images

  ## Example Post Structure

      ---
      title: "My Blog Post"
      date: "2025-01-18"
      description: "A brief description"
      tags: ["elixir", "phoenix"]
      slug: "my-blog-post"
      featured_image: "/images/custom-og-image.png"
      featured_image_alt: "Custom social sharing image"
      series: "Phoenix LiveView Tutorial"
      series_order: 1
      pattern_style: "geometric"
      ---

      # Heading

      Content with **bold** and *italic* text.

      ```elixir
      defmodule Example do
        def hello, do: "world"
      end
      ```

      ![Diagram showing architecture](/images/posts/architecture-diagram.png)

  ## Blog Series

  To create a series of related posts, add `series` and `series_order` to the frontmatter:

      ---
      title: "Phoenix LiveView Basics"
      series: "Phoenix LiveView Tutorial"
      series_order: 1
      ---

  The series navigation component will automatically appear on posts that belong to a series,
  showing all posts in the series with the current post highlighted.
  """

  use GenServer
  require Logger
  alias Droodotfoo.Content.PostValidator

  @posts_dir Application.compile_env(:droodotfoo, :posts_dir, "priv/posts")
  @table_name :posts_cache

  defmodule Post do
    @moduledoc "Struct representing a blog post"
    defstruct [
      :slug,
      :title,
      :date,
      :modified_time,
      :description,
      :tags,
      :series,
      :series_order,
      :content,
      :html,
      :read_time,
      :author,
      :featured_image,
      :featured_image_alt,
      :pattern_style
    ]

    @type t :: %__MODULE__{
            slug: String.t(),
            title: String.t(),
            date: Date.t(),
            modified_time: Date.t() | nil,
            description: String.t(),
            tags: list(String.t()),
            series: String.t() | nil,
            series_order: integer() | nil,
            content: String.t(),
            html: String.t(),
            read_time: integer(),
            author: String.t() | nil,
            featured_image: String.t() | nil,
            featured_image_alt: String.t() | nil,
            pattern_style: String.t() | nil
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

  @doc "Get all posts in a series, sorted by series_order"
  @spec get_series_posts(String.t()) :: list(Post.t())
  def get_series_posts(series_name) do
    list_posts()
    |> Enum.filter(fn post -> post.series == series_name end)
    |> Enum.sort_by(fn post -> post.series_order || 999 end)
  end

  @doc """
  Get the social sharing image URL for a post.
  Returns the featured_image if present, otherwise generates a pattern URL.
  If pattern_style is specified in frontmatter, includes it as a query parameter.
  """
  @spec social_image_url(Post.t()) :: String.t()
  def social_image_url(%Post{featured_image: image}) when is_binary(image) and image != "" do
    image
  end

  def social_image_url(%Post{slug: slug, pattern_style: pattern_style})
      when is_binary(pattern_style) and pattern_style != "" do
    "/patterns/#{slug}?style=#{pattern_style}"
  end

  def social_image_url(%Post{slug: slug}) do
    "/patterns/#{slug}"
  end

  @doc """
  Get the social sharing image alt text for a post.
  Returns the featured_image_alt if present, otherwise generates from title.
  """
  @spec social_image_alt(Post.t()) :: String.t()
  def social_image_alt(%Post{featured_image_alt: alt}) when is_binary(alt) and alt != "" do
    alt
  end

  def social_image_alt(%Post{title: title}) do
    "Visual pattern for: #{title}"
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
    with {:ok, validated_content, validated_metadata} <-
           PostValidator.validate(content, metadata),
         {:ok, post} <- create_post(validated_content, validated_metadata),
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
    path = posts_path()

    case File.ls(path) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".md"))
        |> Enum.map(&load_post_file/1)
        |> Enum.reject(&is_nil/1)
        |> tap(fn posts ->
          Enum.each(posts, fn post ->
            :ets.insert(@table_name, {post.slug, post})
          end)

          Logger.info("Loaded #{length(posts)} blog posts from #{path}")
        end)

      {:error, :enoent} ->
        Logger.warning("Posts directory not found: #{path}. No posts loaded.")
        []

      {:error, reason} ->
        Logger.error("Failed to read posts directory #{path}: #{inspect(reason)}")
        []
    end
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

        # Convert markdown to HTML with syntax highlighting and extended features
        # Note: unsafe_ set to true to allow raw HTML (images, embeds, etc.)
        # Safe since content is controlled (authenticated API + personal blog)
        html =
          MDEx.to_html!(markdown,
            extension: [
              strikethrough: true,
              table: true,
              autolink: true,
              tasklist: true,
              footnotes: true
            ],
            render: [
              unsafe_: true
            ],
            syntax_highlight: [formatter: :html_linked]
          )

        %Post{
          slug: slug,
          title: Map.get(frontmatter, "title", "Untitled"),
          date: parse_date(Map.get(frontmatter, "date")),
          modified_time: parse_date(Map.get(frontmatter, "modified_time")),
          description: Map.get(frontmatter, "description", ""),
          tags: Map.get(frontmatter, "tags", []),
          series: Map.get(frontmatter, "series"),
          series_order: Map.get(frontmatter, "series_order"),
          author: Map.get(frontmatter, "author"),
          featured_image: Map.get(frontmatter, "featured_image"),
          featured_image_alt: Map.get(frontmatter, "featured_image_alt"),
          pattern_style: Map.get(frontmatter, "pattern_style"),
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
    # Strip HTML tags, code blocks, and frontmatter to count only readable text
    text =
      markdown
      # Remove code blocks (both ``` and indented)
      |> String.replace(~r/```[\s\S]*?```/m, "")
      |> String.replace(~r/^    .+$/m, "")
      # Remove HTML tags and their attributes
      |> String.replace(~r/<[^>]+>/m, "")
      # Remove image alt text brackets and URLs
      |> String.replace(~r/!\[[^\]]*\]\([^\)]*\)/m, "")
      # Remove inline links but keep text
      |> String.replace(~r/\[([^\]]+)\]\([^\)]*\)/m, "\\1")
      # Remove YAML frontmatter if present
      |> String.replace(~r/^---\n[\s\S]*?\n---\n/m, "")

    words =
      text
      |> String.split(~r/\s+/)
      |> Enum.reject(&(&1 == ""))
      |> length()

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
      "slug" => post.slug,
      "featured_image" => post.featured_image,
      "featured_image_alt" => post.featured_image_alt,
      "series" => post.series,
      "series_order" => post.series_order
    }

    content = build_frontmatter(frontmatter) <> "\n" <> post.content
    File.write(path, content)
  end

  defp build_frontmatter(map) do
    # Use Ymlr for proper YAML encoding (handles escaping, special chars, etc.)
    # Filter out nil values to keep frontmatter clean
    frontmatter_map =
      map
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Enum.into(%{})

    {:ok, yaml} = Ymlr.document(frontmatter_map)
    # Ymlr already adds the opening ---, just need closing
    "#{yaml}---"
  end

  defp generate_slug(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
  end

  defp posts_path do
    # Use Application.app_dir for releases (works in dev and prod)
    :droodotfoo
    |> Application.app_dir(@posts_dir)
  end
end
