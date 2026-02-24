defmodule Droodotfoo.Wiki.Ingestion.NLabPipeline do
  @moduledoc """
  Pipeline for ingesting nLab wiki content.

  nLab is a wiki focused on mathematics, physics, and philosophy.
  Content is stored in a git repository as markdown with itex math.
  """

  require Logger

  alias Droodotfoo.Wiki.Content.Article
  alias Droodotfoo.Wiki.Ingestion.{Common, NLabClient, MathRenderer}
  alias Droodotfoo.Wiki.{Cache, Storage}

  @source :nlab
  @license "CC BY-SA 4.0"
  @upstream_base "https://ncatlab.org/nlab/show/"

  @type result :: {:created | :updated | :unchanged, Article.t()} | {:error, term()}

  @doc """
  Process a single page by slug.
  """
  @spec process_page(String.t()) :: result()
  def process_page(slug) do
    with {:ok, page} <- NLabClient.get_page(slug) do
      upsert_article(page)
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
    Common.process_pages_sequential(slugs, &process_page/1)
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
      {:ok, Common.aggregate_stats(results)}
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
        {:ok, Common.aggregate_stats(results)}
      end
    end
  end

  # Private functions

  defp upsert_article(page) do
    html = render_page(page)
    content_hash = Common.hash_content(html)

    @source
    |> Common.find_article(page.slug)
    |> do_upsert(page, html, content_hash)
  end

  defp do_upsert(nil, page, html, content_hash) do
    save_article(:insert, nil, page, html, content_hash)
  end

  defp do_upsert(%Article{upstream_hash: hash} = existing, _page, _html, hash) do
    {:unchanged, existing}
  end

  defp do_upsert(existing, page, html, content_hash) do
    save_article(:update, existing, page, html, content_hash)
  end

  defp save_article(operation, existing, page, html, content_hash) do
    with {:ok, html_key} <- Storage.put_html(@source, page.slug, html),
         {:ok, raw_key} <- Storage.put_raw(@source, page.slug, page.content),
         attrs = build_article_attrs(operation, page, html, html_key, raw_key, content_hash),
         {:ok, article} <- Common.persist_article(operation, existing, attrs) do
      Cache.invalidate(@source, page.slug)
      log_operation(operation, page.title)
      {Common.operation_result(operation), article}
    else
      {:error, changeset} -> {:error, {:"#{operation}_failed", changeset}}
    end
  end

  defp build_article_attrs(:insert, page, html, html_key, raw_key, content_hash) do
    %{
      source: @source,
      slug: page.slug,
      title: page.title,
      extracted_text: Common.extract_text(html),
      rendered_html_key: html_key,
      raw_content_key: raw_key,
      upstream_url: Common.upstream_url(@upstream_base, page.slug),
      upstream_hash: content_hash,
      status: :synced,
      license: @license,
      metadata: %{
        "categories" => page.categories,
        "has_math" => MathRenderer.has_math?(page.content)
      },
      synced_at: DateTime.utc_now()
    }
  end

  defp build_article_attrs(:update, page, html, html_key, raw_key, content_hash) do
    %{
      title: page.title,
      extracted_text: Common.extract_text(html),
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
  end

  defp log_operation(:insert, title), do: Logger.info("Created nLab article: #{title}")
  defp log_operation(:update, title), do: Logger.info("Updated nLab article: #{title}")

  defp render_page(page) do
    page.content
    |> MathRenderer.prepare_math()
    |> render_markdown()
    |> wrap_html(page.title)
  end

  defp render_markdown(content) do
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

  defp default_since do
    DateTime.utc_now() |> DateTime.add(-7 * 24 * 3600, :second)
  end
end
