defmodule Wiki.Library do
  @moduledoc """
  Context for the personal document library.

  Manages document uploads, storage, and retrieval.
  Documents are stored in MinIO with metadata in Postgres.
  """

  import Ecto.Query

  alias Wiki.Library.Document
  alias Wiki.Repo

  require Logger

  @library_bucket "droo-library"

  # ===========================================================================
  # Documents
  # ===========================================================================

  @doc """
  List all documents, optionally filtered.

  Options:
  - `:search` - Full-text search query
  - `:content_type` - Filter by MIME type
  - `:tag` - Filter by tag
  - `:limit` - Max results (default 50)
  - `:offset` - Pagination offset
  """
  @spec list_documents(keyword()) :: [Document.t()]
  def list_documents(opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    Document
    |> apply_filters(opts)
    |> order_by([d], desc: d.inserted_at)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  @doc """
  Get a document by slug.
  """
  @spec get_document(String.t()) :: Document.t() | nil
  def get_document(slug) when is_binary(slug) do
    Repo.get_by(Document, slug: slug)
  end

  @doc """
  Get a document by ID.
  """
  @spec get_document!(integer()) :: Document.t()
  def get_document!(id) when is_integer(id) do
    Repo.get!(Document, id)
  end

  @doc """
  Create a document record (after file is uploaded to MinIO).
  """
  @spec create_document(map()) :: {:ok, Document.t()} | {:error, Ecto.Changeset.t()}
  def create_document(attrs) do
    Document.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Update a document's metadata.
  """
  @spec update_document(Document.t(), map()) :: {:ok, Document.t()} | {:error, Ecto.Changeset.t()}
  def update_document(%Document{} = document, attrs) do
    document
    |> Document.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Delete a document and its file from storage.
  """
  @spec delete_document(Document.t()) :: {:ok, Document.t()} | {:error, term()}
  def delete_document(%Document{} = document) do
    with :ok <- delete_file(document.file_key),
         {:ok, document} <- Repo.delete(document) do
      {:ok, document}
    end
  end

  @doc """
  Count documents matching filters.
  """
  @spec count_documents(keyword()) :: integer()
  def count_documents(opts \\ []) do
    Document
    |> apply_filters(opts)
    |> Repo.aggregate(:count)
  end

  @doc """
  Get all unique tags across documents.
  """
  @spec list_tags() :: [String.t()]
  def list_tags do
    Document
    |> select([d], fragment("unnest(?)", d.tags))
    |> distinct(true)
    |> Repo.all()
    |> Enum.sort()
  end

  # ===========================================================================
  # File Storage
  # ===========================================================================

  @doc """
  Upload a file to MinIO and create a document record.

  Accepts a file path or binary content.
  """
  @spec upload_document(String.t(), String.t(), binary(), keyword()) ::
          {:ok, Document.t()} | {:error, term()}
  def upload_document(title, content_type, content, opts \\ []) do
    slug = Keyword.get_lazy(opts, :slug, fn -> generate_unique_slug(title) end)
    tags = Keyword.get(opts, :tags, [])
    file_key = "documents/#{slug}/#{slug}#{extension_for(content_type)}"

    with :ok <- upload_file(file_key, content, content_type),
         extracted <- extract_text(content_type, content),
         attrs = %{
           title: title,
           slug: slug,
           content_type: content_type,
           file_key: file_key,
           file_size: byte_size(content),
           extracted_text: extracted,
           tags: tags,
           metadata: %{}
         },
         {:ok, document} <- create_document(attrs) do
      {:ok, document}
    else
      {:error, _reason} = error ->
        # Clean up uploaded file on failure
        delete_file(file_key)
        error
    end
  end

  @doc """
  Get a signed URL for downloading a document.
  """
  @spec download_url(Document.t()) :: String.t()
  def download_url(%Document{file_key: file_key}) do
    # For MinIO, generate a presigned URL
    # In dev, just return the direct path
    config = ExAws.Config.new(:s3)

    ExAws.S3.presigned_url(config, :get, @library_bucket, file_key,
      expires_in: 3600,
      virtual_host: false
    )
    |> case do
      {:ok, url} -> url
      _ -> "/library/files/#{file_key}"
    end
  end

  @doc """
  Get the raw file content.
  """
  @spec get_file(String.t()) :: {:ok, binary()} | {:error, term()}
  def get_file(file_key) do
    @library_bucket
    |> ExAws.S3.get_object(file_key)
    |> ExAws.request()
    |> case do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, {:http_error, 404, _}} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  # ===========================================================================
  # Private Helpers
  # ===========================================================================

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:search, term}, q when is_binary(term) and term != "" ->
        where(
          q,
          [d],
          fragment(
            "to_tsvector('english', coalesce(?, '') || ' ' || coalesce(?, '')) @@ plainto_tsquery('english', ?)",
            d.title,
            d.extracted_text,
            ^term
          )
        )

      {:content_type, type}, q when is_binary(type) ->
        where(q, [d], d.content_type == ^type)

      {:tag, tag}, q when is_binary(tag) ->
        where(q, [d], ^tag in d.tags)

      _, q ->
        q
    end)
  end

  defp upload_file(key, content, content_type) do
    @library_bucket
    |> ExAws.S3.put_object(key, content, content_type: content_type)
    |> ExAws.request()
    |> case do
      {:ok, _} ->
        Logger.debug("Uploaded #{@library_bucket}/#{key}")
        :ok

      {:error, reason} = error ->
        Logger.error("Failed to upload #{@library_bucket}/#{key}: #{inspect(reason)}")
        error
    end
  end

  defp delete_file(key) do
    @library_bucket
    |> ExAws.S3.delete_object(key)
    |> ExAws.request()
    |> case do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp generate_unique_slug(title) do
    base_slug = Document.slugify(title)
    ensure_unique_slug(base_slug, 0)
  end

  defp ensure_unique_slug(base_slug, 0) do
    if Repo.exists?(from d in Document, where: d.slug == ^base_slug) do
      ensure_unique_slug(base_slug, 1)
    else
      base_slug
    end
  end

  defp ensure_unique_slug(base_slug, n) do
    slug = "#{base_slug}-#{n}"

    if Repo.exists?(from d in Document, where: d.slug == ^slug) do
      ensure_unique_slug(base_slug, n + 1)
    else
      slug
    end
  end

  defp extension_for("application/pdf"), do: ".pdf"
  defp extension_for("application/msword"), do: ".doc"

  defp extension_for("application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
    do: ".docx"

  defp extension_for("application/vnd.oasis.opendocument.text"), do: ".odt"
  defp extension_for("text/plain"), do: ".txt"
  defp extension_for("text/markdown"), do: ".md"
  defp extension_for("text/html"), do: ".html"
  defp extension_for(_), do: ""

  # Basic text extraction - can be enhanced with external tools
  defp extract_text("text/plain", content), do: content
  defp extract_text("text/markdown", content), do: content
  defp extract_text("text/html", content), do: Floki.text(Floki.parse_document!(content))
  defp extract_text(_, _), do: nil
end
