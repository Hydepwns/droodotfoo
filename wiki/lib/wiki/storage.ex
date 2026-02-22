defmodule Wiki.Storage do
  @moduledoc """
  MinIO/S3 storage helpers for wiki content.

  Stores rendered HTML and raw wikitext content in object storage.
  Keys follow the pattern: `{source}/{slug}/{type}.{ext}`
  """

  require Logger

  @type source :: :osrs | :nlab | :wikipedia | :vintage_machinery | :wikiart
  @type upload_result :: {:ok, String.t()} | {:error, term()}

  @doc """
  Upload rendered HTML for an article.

  Returns the storage key on success.
  """
  @spec put_html(source(), String.t(), String.t()) :: upload_result()
  def put_html(source, slug, html) do
    key = html_key(source, slug)

    case upload(wiki_bucket(), key, html, content_type: "text/html") do
      :ok -> {:ok, key}
      error -> error
    end
  end

  @doc """
  Upload raw wikitext/markdown for an article.

  Returns the storage key on success.
  """
  @spec put_raw(source(), String.t(), String.t()) :: upload_result()
  def put_raw(source, slug, content) do
    key = raw_key(source, slug)

    case upload(wiki_bucket(), key, content, content_type: "text/plain") do
      :ok -> {:ok, key}
      error -> error
    end
  end

  @doc """
  Get rendered HTML for an article.
  """
  @spec get_html(String.t()) :: {:ok, String.t()} | {:error, term()}
  def get_html(key) do
    download(wiki_bucket(), key)
  end

  @doc """
  Get raw wikitext/markdown for an article.
  """
  @spec get_raw(String.t()) :: {:ok, String.t()} | {:error, term()}
  def get_raw(key) do
    download(wiki_bucket(), key)
  end

  @doc """
  Delete all content for an article.
  """
  @spec delete_article(source(), String.t()) :: :ok
  def delete_article(source, slug) do
    prefix = "#{source}/#{slug}/"

    wiki_bucket()
    |> ExAws.S3.list_objects(prefix: prefix)
    |> ExAws.stream!()
    |> Stream.map(& &1.key)
    |> Stream.each(&delete(wiki_bucket(), &1))
    |> Stream.run()

    :ok
  end

  @doc """
  Check if rendered HTML exists for an article.
  """
  @spec html_exists?(source(), String.t()) :: boolean()
  def html_exists?(source, slug) do
    exists?(wiki_bucket(), html_key(source, slug))
  end

  # Key construction

  defp html_key(source, slug), do: "#{source}/#{sanitize_slug(slug)}/rendered.html"
  defp raw_key(source, slug), do: "#{source}/#{sanitize_slug(slug)}/raw.txt"

  defp sanitize_slug(slug) do
    slug
    |> String.replace(~r/[^a-zA-Z0-9_\-]/, "_")
    |> String.downcase()
  end

  # Low-level S3 operations

  defp upload(bucket, key, content, opts) do
    content_type = Keyword.get(opts, :content_type, "application/octet-stream")

    bucket
    |> ExAws.S3.put_object(key, content, content_type: content_type)
    |> ExAws.request()
    |> case do
      {:ok, _} ->
        Logger.debug("Uploaded #{bucket}/#{key}")
        :ok

      {:error, reason} = error ->
        Logger.error("Failed to upload #{bucket}/#{key}: #{inspect(reason)}")
        error
    end
  end

  defp download(bucket, key) do
    bucket
    |> ExAws.S3.get_object(key)
    |> ExAws.request()
    |> case do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, {:http_error, 404, _}} -> {:error, :not_found}
      {:error, reason} -> {:error, reason}
    end
  end

  defp delete(bucket, key) do
    bucket
    |> ExAws.S3.delete_object(key)
    |> ExAws.request()
    |> case do
      {:ok, _} -> :ok
      {:error, reason} -> Logger.warning("Failed to delete #{bucket}/#{key}: #{inspect(reason)}")
    end
  end

  defp exists?(bucket, key) do
    case ExAws.S3.head_object(bucket, key) |> ExAws.request() do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  # Bucket names from config

  defp wiki_bucket do
    Application.get_env(:wiki, __MODULE__)[:bucket_wiki] || "droo-wiki"
  end
end
