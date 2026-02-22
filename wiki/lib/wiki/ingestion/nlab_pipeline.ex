defmodule Wiki.Ingestion.NLabPipeline do
  @moduledoc """
  Pipeline for ingesting nLab wiki content.

  nLab is a wiki focused on mathematics, physics, and philosophy.
  Content is stored in a git repository as markdown with itex math.

  This pipeline:
  1. Syncs the git repository
  2. Parses markdown pages with math notation
  3. Renders markdown to HTML with KaTeX-ready math
  4. Stores content in MinIO
  5. Creates/updates article records
  """

  require Logger

  alias Wiki.Content.Article
  alias Wiki.Ingestion.{NLabClient, MathRenderer}
  alias Wiki.{Cache, Repo, Storage}

  import Ecto.Query

  @source :nlab
  @license "CC BY-SA 4.0"
  @upstream_base "https://ncatlab.org/nlab/show/"

  @type result :: {:created | :updated | :unchanged, Article.t()} | {:error, term()}

  @doc """
  Process a single page by slug.
  """
  @spec process_page(String.t()) :: result()
  def process_page(slug) do
    with {:ok, page} <- NLabClient.get_page(slug),
         {:ok, article} <- upsert_article(page) do
      article
    else
      {:error, :not_found} ->
        Logger.debug("nLab page not found: #{slug}")
        {:error, :not_found}

      {:error, reason} = error ->
        Logger.error("Failed to process nLab page #{slug}: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Process multiple pages by slug.
  """
  @spec process_pages([String.t()]) :: %{String.t() => result()}
  def process_pages(slugs) when is_list(slugs) do
    slugs
    |> Enum.map(fn slug -> {slug, process_page(slug)} end)
    |> Map.new()
  end

  @doc """
  Full sync - process all pages in the repository.
  """
  @spec sync_all(keyword()) ::
          {:ok,
           %{created: integer(), updated: integer(), unchanged: integer(), errors: integer()}}
          | {:error, term()}
  def sync_all(opts \\ []) do
    limit = Keyword.get(opts, :limit, 10_000)

    with {:ok, _path} <- NLabClient.sync_repo(),
         {:ok, slugs} <- NLabClient.list_pages() do
      slugs = Enum.take(slugs, limit)
      Logger.info("Processing #{length(slugs)} nLab pages")

      results = process_pages(slugs)
      {:ok, aggregate_stats(results)}
    end
  end

  @doc """
  Incremental sync - process pages modified since last successful sync.
  """
  @spec sync_recent_changes(DateTime.t() | nil) ::
          {:ok,
           %{created: integer(), updated: integer(), unchanged: integer(), errors: integer()}}
          | {:error, term()}
  def sync_recent_changes(since \\ nil) do
    since = since || default_since()

    with {:ok, _path} <- NLabClient.sync_repo(),
         {:ok, slugs} <- NLabClient.list_modified_pages(since) do
      if slugs == [] do
        Logger.info("No nLab pages modified since #{since}")
        {:ok, %{created: 0, updated: 0, unchanged: 0, errors: 0}}
      else
        Logger.info("Processing #{length(slugs)} modified nLab pages")
        results = process_pages(slugs)
        {:ok, aggregate_stats(results)}
      end
    end
  end

  # Private functions

  defp upsert_article(page) do
    html = render_page(page)
    content_hash = hash_content(html)

    existing =
      Repo.one(
        from a in Article,
          where: a.source == @source and a.slug == ^page.slug
      )

    cond do
      is_nil(existing) ->
        create_article(page, html, content_hash)

      existing.upstream_hash != content_hash ->
        update_article(existing, page, html, content_hash)

      true ->
        {:unchanged, existing}
    end
  end

  defp create_article(page, html, content_hash) do
    with {:ok, html_key} <- Storage.put_html(@source, page.slug, html),
         {:ok, raw_key} <- Storage.put_raw(@source, page.slug, page.content) do
      attrs = %{
        source: @source,
        slug: page.slug,
        title: page.title,
        extracted_text: extract_text(html),
        rendered_html_key: html_key,
        raw_content_key: raw_key,
        upstream_url: upstream_url(page.slug),
        upstream_hash: content_hash,
        status: :synced,
        license: @license,
        metadata: %{
          "categories" => page.categories,
          "has_math" => MathRenderer.has_math?(page.content)
        },
        synced_at: DateTime.utc_now()
      }

      case Repo.insert(Article.changeset(attrs)) do
        {:ok, article} ->
          Cache.invalidate(@source, page.slug)
          Logger.info("Created nLab article: #{page.title}")
          {:created, article}

        {:error, changeset} ->
          {:error, {:insert_failed, changeset}}
      end
    end
  end

  defp update_article(existing, page, html, content_hash) do
    with {:ok, html_key} <- Storage.put_html(@source, page.slug, html),
         {:ok, raw_key} <- Storage.put_raw(@source, page.slug, page.content) do
      attrs = %{
        title: page.title,
        extracted_text: extract_text(html),
        rendered_html_key: html_key,
        raw_content_key: raw_key,
        upstream_hash: content_hash,
        status: :synced,
        metadata: %{
          "categories" => page.categories,
          "has_math" => MathRenderer.has_math?(page.content)
        },
        synced_at: DateTime.utc_now()
      }

      case Repo.update(Article.changeset(existing, attrs)) do
        {:ok, article} ->
          Cache.invalidate(@source, page.slug)
          Logger.info("Updated nLab article: #{page.title}")
          {:updated, article}

        {:error, changeset} ->
          {:error, {:update_failed, changeset}}
      end
    end
  end

  defp render_page(page) do
    # Convert markdown to HTML with math preparation
    page.content
    |> MathRenderer.prepare_math()
    |> render_markdown()
    |> wrap_html(page.title)
  end

  defp render_markdown(content) do
    # Use MDEx if available, otherwise basic conversion
    if mdex_available?() do
      render_with_mdex(content)
    else
      basic_markdown_to_html(content)
    end
  end

  defp mdex_available? do
    Code.ensure_loaded?(MDEx)
  end

  defp render_with_mdex(content) do
    case apply(MDEx, :to_html, [content]) do
      {:ok, html} -> html
      _ -> basic_markdown_to_html(content)
    end
  end

  defp basic_markdown_to_html(content) do
    content
    |> String.replace(~r/^### (.+)$/m, "<h3>\\1</h3>")
    |> String.replace(~r/^## (.+)$/m, "<h2>\\1</h2>")
    |> String.replace(~r/^# (.+)$/m, "<h1>\\1</h1>")
    |> String.replace(~r/\*\*(.+?)\*\*/, "<strong>\\1</strong>")
    |> String.replace(~r/\*(.+?)\*/, "<em>\\1</em>")
    |> String.replace(~r/`(.+?)`/, "<code>\\1</code>")
    |> String.replace(~r/\[(.+?)\]\((.+?)\)/, "<a href=\"\\2\">\\1</a>")
    |> String.replace(~r/\n\n+/, "</p>\n<p>")
    |> then(&"<p>#{&1}</p>")
  end

  defp wrap_html(body, title) do
    """
    <article class="nlab-article">
      <header>
        <h1>#{html_escape(title)}</h1>
      </header>
      <div class="nlab-content">
        #{body}
      </div>
    </article>
    """
  end

  defp html_escape(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
  end

  defp extract_text(html) do
    html
    |> Floki.parse_document!()
    |> Floki.text(sep: " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> String.slice(0, 100_000)
  end

  defp hash_content(html) do
    :crypto.hash(:sha256, html) |> Base.encode16(case: :lower)
  end

  defp upstream_url(slug) do
    @upstream_base <> URI.encode(slug, &URI.char_unreserved?/1)
  end

  defp default_since do
    # Default to 7 days ago
    DateTime.utc_now() |> DateTime.add(-7 * 24 * 3600, :second)
  end

  defp aggregate_stats(results) do
    Enum.reduce(results, %{created: 0, updated: 0, unchanged: 0, errors: 0}, fn
      {_slug, {:created, _}}, acc -> Map.update!(acc, :created, &(&1 + 1))
      {_slug, {:updated, _}}, acc -> Map.update!(acc, :updated, &(&1 + 1))
      {_slug, {:unchanged, _}}, acc -> Map.update!(acc, :unchanged, &(&1 + 1))
      {_slug, {:error, _}}, acc -> Map.update!(acc, :errors, &(&1 + 1))
    end)
  end
end
