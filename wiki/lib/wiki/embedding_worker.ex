defmodule Wiki.EmbeddingWorker do
  @moduledoc """
  Oban worker for generating article embeddings.

  Processes articles in batches to efficiently utilize GPU.
  Supports multiple embedding modes:

  - Unembedded only (default): Only process articles without embeddings
  - Full re-embed: Re-embed all articles
  - By source: Re-embed articles from a specific source

  ## Manual Invocation

      # Embed articles without embeddings
      %{} |> Wiki.EmbeddingWorker.new() |> Oban.insert()

      # Full re-embed of all articles
      %{full: true} |> Wiki.EmbeddingWorker.new() |> Oban.insert()

      # Re-embed specific source
      %{source: "nlab"} |> Wiki.EmbeddingWorker.new() |> Oban.insert()

  """

  use Oban.Worker,
    queue: :embeddings,
    max_attempts: 3,
    unique: [period: 600, states: [:available, :scheduled, :executing]]

  require Logger

  import Ecto.Query

  alias Wiki.Content.Article
  alias Wiki.Ollama
  alias Wiki.Repo

  @batch_size 50
  @stream_chunk_size 500

  @valid_sources ~w(osrs nlab wikipedia vintage_machinery wikiart)a

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    cond do
      Map.get(args, "full") ->
        embed_all()

      source = Map.get(args, "source") ->
        case parse_source(source) do
          {:ok, source_atom} -> embed_by_source(source_atom)
          :error -> {:error, "invalid source: #{source}"}
        end

      true ->
        embed_unembedded()
    end
  end

  defp parse_source(source) when is_binary(source) do
    atom = String.to_existing_atom(source)
    if atom in @valid_sources, do: {:ok, atom}, else: :error
  rescue
    ArgumentError -> :error
  end

  defp embed_unembedded do
    Logger.info("EmbeddingWorker: processing unembedded articles")

    query =
      from(a in Article,
        where: is_nil(a.embedding),
        order_by: a.id,
        select: [:id, :title, :extracted_text]
      )

    process_stream(query, "unembedded")
  end

  defp embed_all do
    Logger.info("EmbeddingWorker: re-embedding all articles")

    query =
      from(a in Article,
        order_by: a.id,
        select: [:id, :title, :extracted_text]
      )

    process_stream(query, "full")
  end

  defp embed_by_source(source) do
    Logger.info("EmbeddingWorker: re-embedding source=#{source}")

    query =
      from(a in Article,
        where: a.source == ^source,
        order_by: a.id,
        select: [:id, :title, :extracted_text]
      )

    process_stream(query, "source:#{source}")
  end

  defp process_stream(query, mode) do
    stats = %{processed: 0, embedded: 0, errors: 0}

    case Ollama.health_check() do
      :ok ->
        do_process_stream(query, mode, stats)

      {:error, reason} ->
        Logger.error("EmbeddingWorker: Ollama health check failed: #{inspect(reason)}")
        {:error, "Ollama unavailable: #{inspect(reason)}"}
    end
  end

  defp do_process_stream(query, mode, stats) do
    # Process in paginated batches to avoid long-running transactions
    # Each batch is its own transaction for better resource management
    final_stats = process_paginated(query, stats, 0)

    Logger.info(
      "EmbeddingWorker: completed mode=#{mode} " <>
        "processed=#{final_stats.processed} embedded=#{final_stats.embedded} errors=#{final_stats.errors}"
    )

    if final_stats.errors > 0 do
      {:error, "#{final_stats.errors} embedding failures"}
    else
      :ok
    end
  end

  defp process_paginated(query, stats, page) do
    offset = page * @stream_chunk_size

    articles =
      query
      |> limit(^@stream_chunk_size)
      |> offset(^offset)
      |> Repo.all()

    if articles == [] do
      stats
    else
      new_stats =
        articles
        |> Enum.chunk_every(@batch_size)
        |> Enum.reduce(stats, fn batch, acc ->
          process_batch(batch, acc)
        end)

      process_paginated(query, new_stats, page + 1)
    end
  end

  defp process_batch(articles, stats) do
    texts =
      Enum.map(articles, fn article ->
        Ollama.prepare_text(article.title, article.extracted_text)
      end)

    case Ollama.embed_batch(texts) do
      {:ok, embeddings} ->
        embedded_count = save_embeddings(articles, embeddings)

        %{
          stats
          | processed: stats.processed + length(articles),
            embedded: stats.embedded + embedded_count
        }

      {:error, reason} ->
        Logger.warning(
          "EmbeddingWorker: batch failed (#{length(articles)} articles): #{inspect(reason)}"
        )

        %{
          stats
          | processed: stats.processed + length(articles),
            errors: stats.errors + length(articles)
        }
    end
  end

  defp save_embeddings(articles, embeddings) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    # Bulk update using a single query with unnest
    ids = Enum.map(articles, & &1.id)

    # Convert embeddings to PostgreSQL vector format
    vectors =
      embeddings
      |> Enum.map(fn emb -> Pgvector.new(emb) end)

    %{num_rows: count} =
      Repo.query!(
        """
        UPDATE articles
        SET embedding = data.embedding::vector,
            embedded_at = $3
        FROM unnest($1::bigint[], $2::vector[]) AS data(id, embedding)
        WHERE articles.id = data.id
        """,
        [ids, vectors, now]
      )

    count
  end
end
