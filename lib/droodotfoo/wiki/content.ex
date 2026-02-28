defmodule Droodotfoo.Wiki.Content do
  @moduledoc """
  Context module for wiki content operations.

  Provides high-level functions for querying and managing articles
  across all sources.
  """

  import Ecto.Query

  alias Droodotfoo.Wiki.Content.{Article, PendingEdit, Redirect, Revision}
  alias Droodotfoo.Wiki.{Cache, Storage}
  alias Droodotfoo.Repo

  @type source :: :osrs | :nlab | :wikipedia | :vintage_machinery | :wikiart

  @doc """
  Get an article by source and slug.

  Follows redirects automatically. Returns the article with HTML content
  loaded from storage.
  """
  @spec get_article(source(), String.t()) :: {:ok, Article.t(), String.t()} | {:error, :not_found}
  def get_article(source, slug) do
    slug = resolve_redirect(source, slug)

    case Repo.one(from(a in Article, where: a.source == ^source and a.slug == ^slug)) do
      nil ->
        {:error, :not_found}

      article ->
        html = load_html(article)
        {:ok, article, html}
    end
  end

  @doc """
  Get an article by ID.
  """
  @spec get_article_by_id(integer()) :: Article.t() | nil
  def get_article_by_id(id) do
    Repo.get(Article, id)
  end

  @doc """
  List articles for a source.

  Options:
  - :limit - max results (default 50)
  - :offset - pagination offset
  - :order_by - :title | :updated_at (default :title)
  - :letter - filter by first letter of title (e.g., "A")
  """
  @spec list_articles(source(), keyword()) :: [Article.t()]
  def list_articles(source, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)
    order_by = Keyword.get(opts, :order_by, :title)
    letter = Keyword.get(opts, :letter)

    from(a in Article, where: a.source == ^source)
    |> maybe_filter_letter(letter)
    |> order_by_field(order_by)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  @doc """
  Count articles for a source with optional filters.

  Options:
  - :letter - filter by first letter of title
  """
  @spec count_articles(source(), keyword()) :: non_neg_integer()
  def count_articles(source, opts \\ []) do
    letter = Keyword.get(opts, :letter)

    from(a in Article, where: a.source == ^source)
    |> maybe_filter_letter(letter)
    |> Repo.aggregate(:count)
  end

  @doc """
  Search articles by title or content.

  Uses PostgreSQL full-text search on the extracted_text field.
  """
  @spec search(String.t(), keyword()) :: [Article.t()]
  def search(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    source = Keyword.get(opts, :source)

    tsquery = to_tsquery(query)

    from(a in Article)
    |> maybe_filter_source(source)
    |> where(
      [a],
      fragment(
        "to_tsvector('english', coalesce(?, '') || ' ' || coalesce(?, '')) @@ to_tsquery('english', ?)",
        a.title,
        a.extracted_text,
        ^tsquery
      )
    )
    |> order_by([a],
      desc:
        fragment(
          "ts_rank(to_tsvector('english', coalesce(?, '') || ' ' || coalesce(?, '')), to_tsquery('english', ?))",
          a.title,
          a.extracted_text,
          ^tsquery
        )
    )
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Count articles per source.
  """
  @spec count_by_source() :: %{source() => integer()}
  def count_by_source do
    from(a in Article, group_by: a.source, select: {a.source, count(a.id)})
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Get recent articles across all sources.
  """
  @spec recent_articles(integer()) :: [Article.t()]
  def recent_articles(limit \\ 20) do
    from(a in Article, order_by: [desc: a.synced_at], limit: ^limit)
    |> Repo.all()
  end

  # Redirects

  defp resolve_redirect(source, slug) do
    case Repo.one(from(r in Redirect, where: r.source == ^source and r.from_slug == ^slug)) do
      nil -> slug
      redirect -> redirect.to_slug
    end
  end

  @doc """
  Create a redirect from one slug to another.
  """
  @spec create_redirect(source(), String.t(), String.t()) ::
          {:ok, Redirect.t()} | {:error, Ecto.Changeset.t()}
  def create_redirect(source, from_slug, to_slug) do
    %Redirect{}
    |> Redirect.changeset(%{source: source, from_slug: from_slug, to_slug: to_slug})
    |> Repo.insert(on_conflict: :replace_all, conflict_target: [:source, :from_slug])
  end

  @doc """
  List all redirects, optionally filtered by source.

  Options:
  - :source - filter by source
  - :limit - max results (default 100)
  - :offset - pagination offset
  """
  @spec list_redirects(keyword()) :: [Redirect.t()]
  def list_redirects(opts \\ []) do
    source = Keyword.get(opts, :source)
    limit = Keyword.get(opts, :limit, 100)
    offset = Keyword.get(opts, :offset, 0)

    from(r in Redirect)
    |> maybe_filter_redirect_source(source)
    |> order_by([r], asc: r.source, asc: r.from_slug)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  defp maybe_filter_redirect_source(query, nil), do: query
  defp maybe_filter_redirect_source(query, source), do: where(query, [r], r.source == ^source)

  @doc """
  Delete a redirect by ID.
  """
  @spec delete_redirect(integer()) :: {:ok, Redirect.t()} | {:error, :not_found}
  def delete_redirect(id) do
    case Repo.get(Redirect, id) do
      nil -> {:error, :not_found}
      redirect -> Repo.delete(redirect)
    end
  end

  @doc """
  Get total count of redirects.
  """
  @spec count_redirects() :: integer()
  def count_redirects do
    Repo.aggregate(Redirect, :count)
  end

  @doc """
  Get redirect by ID.
  """
  @spec get_redirect(integer()) :: Redirect.t() | nil
  def get_redirect(id) do
    Repo.get(Redirect, id)
  end

  # Private helpers

  defp load_html(%Article{} = article) do
    Cache.fetch_html(article)
  end

  defp order_by_field(query, :title), do: order_by(query, [a], asc: a.title)
  defp order_by_field(query, :updated_at), do: order_by(query, [a], desc: a.updated_at)
  defp order_by_field(query, _), do: order_by(query, [a], asc: a.title)

  defp maybe_filter_source(query, nil), do: query
  defp maybe_filter_source(query, source), do: where(query, [a], a.source == ^source)

  defp maybe_filter_letter(query, nil), do: query

  defp maybe_filter_letter(query, letter) when is_binary(letter) do
    upper_letter = String.upcase(letter)
    where(query, [a], fragment("upper(left(?, 1)) = ?", a.title, ^upper_letter))
  end

  defp to_tsquery(query) do
    query
    |> String.split(~r/\s+/)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.replace(&1, ~r/[^\w]/, ""))
    |> Enum.reject(&(&1 == ""))
    |> Enum.join(" & ")
  end

  # --- Pending Edits ---

  @max_pending_per_ip 5
  @max_submissions_per_day 10

  @doc """
  List pending edits by status.

  Options:
  - :status - filter by status (default: :pending)
  - :limit - max results (default: 50)
  """
  @spec list_pending_edits(keyword()) :: [PendingEdit.t()]
  def list_pending_edits(opts \\ []) do
    status = Keyword.get(opts, :status, :pending)
    limit = Keyword.get(opts, :limit, 50)

    from(pe in PendingEdit,
      where: pe.status == ^status,
      preload: [:article],
      order_by: [asc: pe.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc """
  Get a pending edit by ID with article preloaded.
  """
  @spec get_pending_edit(integer()) :: PendingEdit.t() | nil
  def get_pending_edit(id) do
    Repo.get(PendingEdit, id)
    |> Repo.preload(:article)
  end

  @doc """
  Create a pending edit suggestion.

  Returns error if rate limited.
  """
  @spec create_pending_edit(map()) ::
          {:ok, PendingEdit.t()} | {:error, :rate_limited | Ecto.Changeset.t()}
  def create_pending_edit(attrs) do
    ip = attrs[:submitter_ip] || attrs["submitter_ip"]

    if rate_limited?(ip) do
      {:error, :rate_limited}
    else
      result =
        %PendingEdit{}
        |> PendingEdit.changeset(attrs)
        |> Repo.insert()

      with {:ok, pending_edit} <- result do
        enqueue_notification(:new_edit, pending_edit.id)
        {:ok, pending_edit}
      end
    end
  end

  @doc """
  Approve a pending edit.

  Updates the article content and creates a revision.
  """
  @spec approve_pending_edit(PendingEdit.t(), String.t() | nil) ::
          {:ok, PendingEdit.t()} | {:error, term()}
  def approve_pending_edit(%PendingEdit{} = pending_edit, reviewer_note \\ nil) do
    Repo.transaction(fn ->
      # Update article content
      article = get_article_by_id(pending_edit.article_id)
      new_html = pending_edit.suggested_content

      # Store new content in MinIO
      case Storage.put_html(article.source, article.slug, new_html) do
        {:ok, _key} -> :ok
        {:error, reason} -> Repo.rollback({:storage_error, reason})
      end

      # Invalidate cache
      Cache.invalidate(article.source, article.slug)

      # Create revision
      content_hash = :crypto.hash(:sha256, new_html) |> Base.encode16(case: :lower)

      %Revision{}
      |> Revision.changeset(%{
        article_id: article.id,
        content_hash: content_hash,
        editor: pending_edit.submitter_email || "anonymous",
        comment: pending_edit.reason || "Community edit"
      })
      |> Repo.insert!()

      # Mark edit as approved
      pending_edit
      |> PendingEdit.review_changeset(%{
        status: :approved,
        reviewer_note: reviewer_note,
        reviewed_at: DateTime.utc_now()
      })
      |> Repo.update!()
    end)
    |> tap(fn
      {:ok, approved_edit} -> enqueue_notification(:approved, approved_edit.id)
      _ -> :ok
    end)
  end

  @doc """
  Reject a pending edit with an optional note.
  """
  @spec reject_pending_edit(PendingEdit.t(), String.t() | nil) ::
          {:ok, PendingEdit.t()} | {:error, Ecto.Changeset.t()}
  def reject_pending_edit(%PendingEdit{} = pending_edit, reviewer_note \\ nil) do
    result =
      pending_edit
      |> PendingEdit.review_changeset(%{
        status: :rejected,
        reviewer_note: reviewer_note,
        reviewed_at: DateTime.utc_now()
      })
      |> Repo.update()

    with {:ok, rejected_edit} <- result do
      enqueue_notification(:rejected, rejected_edit.id)
      {:ok, rejected_edit}
    end
  end

  @doc """
  Count pending edits by status.
  """
  @spec count_pending_edits_by_status() :: %{atom() => integer()}
  def count_pending_edits_by_status do
    from(pe in PendingEdit, group_by: pe.status, select: {pe.status, count(pe.id)})
    |> Repo.all()
    |> Map.new()
  end

  defp rate_limited?(ip) when is_binary(ip) do
    # Check pending count for this IP
    pending_count =
      from(pe in PendingEdit,
        where: pe.submitter_ip == ^ip and pe.status == :pending,
        select: count(pe.id)
      )
      |> Repo.one()

    if pending_count >= @max_pending_per_ip do
      true
    else
      # Check 24h submission count
      day_ago = DateTime.utc_now() |> DateTime.add(-24 * 60 * 60, :second)

      day_count =
        from(pe in PendingEdit,
          where: pe.submitter_ip == ^ip and pe.inserted_at > ^day_ago,
          select: count(pe.id)
        )
        |> Repo.one()

      day_count >= @max_submissions_per_day
    end
  end

  defp rate_limited?(_), do: true

  defp enqueue_notification(type, pending_edit_id) do
    %{type: to_string(type), pending_edit_id: pending_edit_id}
    |> Droodotfoo.Wiki.Notifications.NotificationWorker.new()
    |> Oban.insert()
  end
end
