defmodule Droodotfoo.Fileverse.Agent.ResponseGenerator do
  @moduledoc """
  Generate responses based on parsed query intent.
  """

  @doc """
  Generate a response for the given intent.
  """
  def generate(query, intent_result, _wallet_address, _context) do
    case intent_result.intent do
      :balance_query -> balance_response()
      :transaction_query -> transaction_response()
      :nft_query -> nft_response()
      :defi_query -> defi_response()
      :explanation -> explanation_response()
      :recommendation -> recommendation_response()
      _ -> general_response(query)
    end
  end

  defp balance_response do
    %{
      text: "Your ETH balance is 2.5 ETH ($4,250). You also have 1,200 USDC and 0.1 WBTC.",
      suggested_actions: ["Check token prices", "View portfolio breakdown", "Set price alerts"],
      related_commands: [":tokens", ":balance ETH", ":crypto"]
    }
  end

  defp transaction_response do
    %{
      text:
        "You have 15 transactions in the last 7 days. Total volume: 5.2 ETH. Most active day: Tuesday.",
      suggested_actions: [
        "View transaction details",
        "Export transaction history",
        "Analyze spending patterns"
      ],
      related_commands: [":tx", ":transactions", ":perf"]
    }
  end

  defp nft_response do
    %{
      text:
        "You own 8 NFTs across 3 collections. Total floor value: 1.2 ETH. Top collection: Bored Apes.",
      suggested_actions: ["View NFT details", "Check floor prices", "List for sale"],
      related_commands: [":nft list", ":nft view", ":nfts"]
    }
  end

  defp defi_response do
    %{
      text:
        "Your DeFi positions: 1.5 ETH staked (5.2% APY), 500 USDC in liquidity pool. Total yield: $127/month.",
      suggested_actions: [
        "Optimize yield farming",
        "Check impermanent loss",
        "Diversify strategies"
      ],
      related_commands: [":tokens", ":balance", ":perf"]
    }
  end

  defp explanation_response do
    %{
      text:
        "I can explain blockchain concepts, transactions, smart contracts, and DeFi protocols. What would you like to know?",
      suggested_actions: ["Explain gas fees", "How DeFi works", "Smart contract basics"],
      related_commands: [":help", ":man agent"]
    }
  end

  defp recommendation_response do
    %{
      text:
        "Based on your portfolio, I recommend: 1) Diversify into stablecoins, 2) Consider staking rewards, 3) Monitor gas fees for timing.",
      suggested_actions: ["View DeFi opportunities", "Check staking rewards", "Set up alerts"],
      related_commands: [":tokens", ":balance", ":perf"]
    }
  end

  defp general_response(query) do
    %{
      text:
        "I understand you're asking about: '#{query}'. I can help with balances, transactions, NFTs, DeFi, and blockchain explanations.",
      suggested_actions: ["Try a specific question", "View available commands", "Get help"],
      related_commands: [":agent help", ":help", ":man agent"]
    }
  end
end
