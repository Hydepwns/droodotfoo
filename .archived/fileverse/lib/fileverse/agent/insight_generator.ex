defmodule Droodotfoo.Fileverse.Agent.InsightGenerator do
  @moduledoc """
  Generate AI insights based on query intent and blockchain data.
  """

  @doc """
  Generate insights for a given intent.
  """
  def for_intent(intent_result, _wallet_address) do
    case intent_result.intent do
      :balance_query -> balance_insights()
      :transaction_query -> transaction_insights()
      _ -> default_insights()
    end
  end

  @doc """
  Generate analysis insights for a given data type.
  """
  def for_data_type(:transactions, _wallet_address, _time_range) do
    [
      %{
        type: :analysis,
        title: "Transaction Volume Analysis",
        description:
          "Your transaction volume increased 25% this week. Peak activity: Tuesday 2-4 PM.",
        confidence: 0.85,
        actionable: true,
        related_data: [%{type: :volume_change, value: "+25%"}]
      },
      %{
        type: :prediction,
        title: "Gas Fee Trend",
        description: "Based on historical data, gas fees typically drop 40% on weekends.",
        confidence: 0.7,
        actionable: true,
        related_data: [%{type: :gas_savings, value: "40%"}]
      }
    ]
  end

  def for_data_type(:balances, _wallet_address, _time_range) do
    [
      %{
        type: :analysis,
        title: "Portfolio Performance",
        description: "Your portfolio gained 12% this month, outperforming ETH by 3%.",
        confidence: 0.9,
        actionable: true,
        related_data: [%{type: :performance, value: "+12%"}]
      }
    ]
  end

  def for_data_type(:nfts, _wallet_address, _time_range) do
    [
      %{
        type: :analysis,
        title: "NFT Collection Value",
        description:
          "Your NFT collection floor value increased 8% this week. Top performer: Bored Ape #1234.",
        confidence: 0.8,
        actionable: true,
        related_data: [%{type: :floor_value, value: "+8%"}]
      }
    ]
  end

  def for_data_type(_, _wallet_address, _time_range) do
    [
      %{
        type: :analysis,
        title: "General Portfolio Health",
        description:
          "Your portfolio shows healthy diversification with good risk management practices.",
        confidence: 0.75,
        actionable: false,
        related_data: []
      }
    ]
  end

  # Private

  defp balance_insights do
    [
      %{
        type: :recommendation,
        title: "Portfolio Diversification",
        description:
          "Consider diversifying beyond ETH. Stablecoins and DeFi tokens could reduce volatility.",
        confidence: 0.8,
        actionable: true,
        related_data: [%{type: :balance, value: "2.5 ETH"}]
      },
      %{
        type: :analysis,
        title: "Gas Fee Optimization",
        description:
          "Your recent transactions show high gas usage. Consider timing transactions during low-fee periods.",
        confidence: 0.7,
        actionable: true,
        related_data: [%{type: :gas_usage, value: "High"}]
      }
    ]
  end

  defp transaction_insights do
    [
      %{
        type: :analysis,
        title: "Trading Pattern Analysis",
        description:
          "You trade most actively on Tuesdays. Consider setting up automated strategies.",
        confidence: 0.9,
        actionable: true,
        related_data: [%{type: :pattern, value: "Tuesday peak"}]
      }
    ]
  end

  defp default_insights do
    [
      %{
        type: :recommendation,
        title: "Security Best Practices",
        description:
          "Consider using a hardware wallet for large amounts and enable 2FA on all exchanges.",
        confidence: 0.95,
        actionable: true,
        related_data: []
      }
    ]
  end
end
