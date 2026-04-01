defmodule Droodotfoo.Fileverse.Agent.IntentParser do
  @moduledoc """
  Parse natural language queries to determine user intent.
  """

  @doc """
  Parse a query to determine the user's intent and extract parameters.
  """
  def parse(query) do
    query_lower = String.downcase(query)

    cond do
      matches_balance?(query_lower) ->
        %{
          intent: :balance_query,
          confidence: 0.9,
          parameters: %{asset_type: extract_asset_type(query_lower)}
        }

      matches_transaction?(query_lower) ->
        %{
          intent: :transaction_query,
          confidence: 0.85,
          parameters: %{time_range: extract_time_range(query_lower)}
        }

      matches_nft?(query_lower) ->
        %{intent: :nft_query, confidence: 0.8, parameters: %{collection_type: :all}}

      matches_defi?(query_lower) ->
        %{intent: :defi_query, confidence: 0.75, parameters: %{strategy_type: :general}}

      matches_explanation?(query_lower) ->
        %{intent: :explanation, confidence: 0.7, parameters: %{explanation_type: :general}}

      matches_recommendation?(query_lower) ->
        %{intent: :recommendation, confidence: 0.8, parameters: %{recommendation_type: :general}}

      true ->
        %{intent: :general_query, confidence: 0.5, parameters: %{}}
    end
  end

  # Pattern matchers

  defp matches_balance?(query), do: contains_any?(query, ["balance", "eth", "token"])
  defp matches_transaction?(query), do: contains_any?(query, ["transaction", "tx", "history"])
  defp matches_nft?(query), do: contains_any?(query, ["nft", "collection"])
  defp matches_defi?(query), do: contains_any?(query, ["defi", "stake", "yield"])
  defp matches_explanation?(query), do: contains_any?(query, ["explain", "what", "how"])

  defp matches_recommendation?(query),
    do: contains_any?(query, ["recommend", "suggest", "advice"])

  defp contains_any?(query, keywords) do
    Enum.any?(keywords, &String.contains?(query, &1))
  end

  # Parameter extractors

  defp extract_asset_type(query) do
    cond do
      String.contains?(query, "eth") -> :eth
      String.contains?(query, "btc") -> :btc
      String.contains?(query, "token") -> :tokens
      true -> :all
    end
  end

  defp extract_time_range(query) do
    cond do
      contains_any?(query, ["today", "24h"]) -> :day
      contains_any?(query, ["week", "7d"]) -> :week
      contains_any?(query, ["month", "30d"]) -> :month
      true -> :all
    end
  end
end
