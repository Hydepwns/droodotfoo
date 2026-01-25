defmodule Droodotfoo.Fileverse.Agent.RecommendationEngine do
  @moduledoc """
  Generate and filter AI recommendations based on user preferences.
  """

  @doc """
  Generate recommendations for the given type and limit.
  """
  def generate(_wallet_address, recommendation_type, limit) do
    base_recommendations()
    |> filter_by_type(recommendation_type)
    |> Enum.take(limit)
  end

  defp base_recommendations do
    [
      %{
        type: :recommendation,
        title: "Consider Staking ETH",
        description:
          "With 2.5 ETH, you could earn ~5% APY through staking. Estimated monthly yield: $18.",
        confidence: 0.85,
        actionable: true,
        related_data: [%{type: :balance, value: "2.5 ETH"}, %{type: :apy, value: "5%"}]
      },
      %{
        type: :recommendation,
        title: "Diversify with Stablecoins",
        description:
          "Add USDC or DAI to reduce portfolio volatility. Consider 20-30% allocation.",
        confidence: 0.8,
        actionable: true,
        related_data: [%{type: :allocation, value: "20-30%"}]
      },
      %{
        type: :analysis,
        title: "Gas Fee Optimization",
        description:
          "Your recent transactions averaged 45 gwei. Optimal timing could save 30-50% on fees.",
        confidence: 0.9,
        actionable: true,
        related_data: [%{type: :gas_usage, value: "45 gwei avg"}]
      },
      %{
        type: :recommendation,
        title: "DeFi Yield Farming",
        description:
          "Consider providing liquidity to earn yield. USDC/ETH pairs offer 8-12% APY.",
        confidence: 0.75,
        actionable: true,
        related_data: [%{type: :apy, value: "8-12%"}]
      },
      %{
        type: :alert,
        title: "Security Reminder",
        description:
          "Enable 2FA on all exchanges and consider a hardware wallet for amounts >1 ETH.",
        confidence: 0.95,
        actionable: true,
        related_data: []
      }
    ]
  end

  defp filter_by_type(recommendations, :defi) do
    Enum.filter(recommendations, &(&1.type in [:recommendation, :analysis]))
  end

  defp filter_by_type(recommendations, :security) do
    Enum.filter(recommendations, &(&1.type == :alert))
  end

  defp filter_by_type(recommendations, _), do: recommendations
end
