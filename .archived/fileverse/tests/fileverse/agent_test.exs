defmodule Droodotfoo.Fileverse.AgentTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Fileverse.Agent

  describe "process_query/2" do
    test "processes balance query with valid parameters" do
      wallet_address = "0x1234567890abcdef1234567890abcdef12345678"
      query = "What's my ETH balance?"

      assert {:ok, response} = Agent.process_query(query, wallet_address: wallet_address)

      assert is_binary(response.query_id)
      assert is_binary(response.response_text)
      assert is_list(response.suggested_actions)
      assert is_list(response.related_commands)
      assert is_list(response.insights)
      assert is_float(response.confidence)
      assert is_integer(response.processing_time_ms)
    end

    test "processes transaction query" do
      wallet_address = "0x1234567890abcdef1234567890abcdef12345678"
      query = "Show my recent transactions"

      assert {:ok, response} = Agent.process_query(query, wallet_address: wallet_address)
      assert response.response_text != ""
    end

    test "processes NFT query" do
      wallet_address = "0x1234567890abcdef1234567890abcdef12345678"
      query = "List my NFTs"

      assert {:ok, response} = Agent.process_query(query, wallet_address: wallet_address)
      assert response.response_text != ""
    end

    test "processes DeFi query" do
      wallet_address = "0x1234567890abcdef1234567890abcdef12345678"
      query = "What DeFi strategies should I consider?"

      assert {:ok, response} = Agent.process_query(query, wallet_address: wallet_address)
      assert response.response_text != ""
    end

    test "processes explanation query" do
      wallet_address = "0x1234567890abcdef1234567890abcdef12345678"
      query = "Explain how gas fees work"

      assert {:ok, response} = Agent.process_query(query, wallet_address: wallet_address)
      assert response.response_text != ""
    end

    test "processes recommendation query" do
      wallet_address = "0x1234567890abcdef1234567890abcdef12345678"
      query = "What should I invest in?"

      assert {:ok, response} = Agent.process_query(query, wallet_address: wallet_address)
      assert response.response_text != ""
    end

    test "returns error when wallet address is missing" do
      query = "What's my balance?"

      assert {:error, :wallet_required} = Agent.process_query(query)
    end
  end

  describe "get_recommendations/1" do
    test "returns general recommendations" do
      wallet_address = "0x1234567890abcdef1234567890abcdef12345678"

      assert {:ok, recommendations} = Agent.get_recommendations(wallet_address: wallet_address)
      assert is_list(recommendations)
      assert recommendations != []

      recommendation = List.first(recommendations)
      assert is_atom(recommendation.type)
      assert is_binary(recommendation.title)
      assert is_binary(recommendation.description)
      assert is_float(recommendation.confidence)
      assert is_boolean(recommendation.actionable)
      assert is_list(recommendation.related_data)
    end

    test "returns DeFi recommendations" do
      wallet_address = "0x1234567890abcdef1234567890abcdef12345678"

      assert {:ok, recommendations} =
               Agent.get_recommendations(
                 wallet_address: wallet_address,
                 recommendation_type: :defi
               )

      assert is_list(recommendations)
    end

    test "returns security recommendations" do
      wallet_address = "0x1234567890abcdef1234567890abcdef12345678"

      assert {:ok, recommendations} =
               Agent.get_recommendations(
                 wallet_address: wallet_address,
                 recommendation_type: :security
               )

      assert is_list(recommendations)
    end

    test "returns error when wallet address is missing" do
      assert {:error, :wallet_required} = Agent.get_recommendations()
    end
  end

  describe "analyze_data/2" do
    test "analyzes transaction data" do
      wallet_address = "0x1234567890abcdef1234567890abcdef12345678"

      assert {:ok, insights} = Agent.analyze_data(:transactions, wallet_address: wallet_address)
      assert is_list(insights)

      if not Enum.empty?(insights) do
        insight = List.first(insights)
        assert is_atom(insight.type)
        assert is_binary(insight.title)
        assert is_binary(insight.description)
        assert is_float(insight.confidence)
        assert is_boolean(insight.actionable)
        assert is_list(insight.related_data)
      end
    end

    test "analyzes balance data" do
      wallet_address = "0x1234567890abcdef1234567890abcdef12345678"

      assert {:ok, insights} = Agent.analyze_data(:balances, wallet_address: wallet_address)
      assert is_list(insights)
    end

    test "analyzes NFT data" do
      wallet_address = "0x1234567890abcdef1234567890abcdef12345678"

      assert {:ok, insights} = Agent.analyze_data(:nfts, wallet_address: wallet_address)
      assert is_list(insights)
    end

    test "analyzes contract data" do
      wallet_address = "0x1234567890abcdef1234567890abcdef12345678"

      assert {:ok, insights} = Agent.analyze_data(:contracts, wallet_address: wallet_address)
      assert is_list(insights)
    end

    test "returns error when wallet address is missing" do
      assert {:error, :wallet_required} = Agent.analyze_data(:transactions)
    end
  end

  describe "help/0" do
    test "returns help data" do
      assert {:ok, help_data} = Agent.help()

      assert Map.has_key?(help_data, :commands)
      assert Map.has_key?(help_data, :examples)
      assert Map.has_key?(help_data, :capabilities)

      assert is_list(help_data.commands)
      assert is_list(help_data.examples)
      assert is_list(help_data.capabilities)

      assert help_data.commands != []
      assert help_data.examples != []
      assert help_data.capabilities != []
    end
  end
end
