defmodule Wiki.CrossLinkWorker do
  @moduledoc """
  Oban worker for detecting cross-source article links.

  Uses pg_trgm similarity to find related articles across different sources.
  Can be triggered after ingestion sync or run periodically.

  ## Manual Invocation

      # Detect links for all OSRS articles
      %{source: "osrs"} |> Wiki.CrossLinkWorker.new() |> Oban.insert()

      # Detect links for a specific article
      %{article_id: 123} |> Wiki.CrossLinkWorker.new() |> Oban.insert()

      # Full scan of all sources
      %{full_scan: true} |> Wiki.CrossLinkWorker.new() |> Oban.insert()

  """

  use Oban.Worker,
    queue: :ingestion,
    max_attempts: 2,
    unique: [period: 300, states: [:available, :scheduled, :executing]]

  require Logger

  alias Wiki.CrossLinks
  alias Wiki.Content.Article
  alias Wiki.Repo

  @sources [:osrs, :nlab, :wikipedia, :vintage_machinery, :wikiart]

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    cond do
      article_id = args["article_id"] ->
        detect_for_article(article_id)

      source = args["source"] ->
        detect_for_source(String.to_existing_atom(source))

      args["full_scan"] ->
        full_scan()

      true ->
        {:error, "Invalid arguments"}
    end
  end

  defp detect_for_article(article_id) do
    case Repo.get(Article, article_id) do
      nil ->
        Logger.warning("Article #{article_id} not found for cross-link detection")
        {:error, :not_found}

      article ->
        case CrossLinks.detect_links(article) do
          {:ok, count} ->
            Logger.info("Detected #{count} cross-links for article #{article_id}")
            :ok

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  defp detect_for_source(source) do
    Logger.info("Starting cross-link detection for source: #{source}")

    case CrossLinks.detect_all(source) do
      {:ok, stats} ->
        Logger.info(
          "Cross-link detection complete for #{source}: " <>
            "#{stats.total_links} links, #{stats.articles_with_links}/#{stats.articles_processed} articles"
        )

        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp full_scan do
    Logger.info("Starting full cross-link scan for all sources")

    results =
      Enum.map(@sources, fn source ->
        case CrossLinks.detect_all(source, limit: 50_000) do
          {:ok, stats} -> {source, stats}
          {:error, reason} -> {source, %{error: reason}}
        end
      end)

    total_links = results |> Enum.map(fn {_, s} -> Map.get(s, :total_links, 0) end) |> Enum.sum()
    Logger.info("Full cross-link scan complete: #{total_links} total links detected")

    :ok
  end
end
