defmodule WikiWeb.OSRS.V1.ItemJSON do
  @moduledoc """
  JSON rendering for OSRS items.

  Follows Phoenix 1.7+ JSON resource conventions.
  """

  alias Wiki.OSRS.Item

  @doc """
  Renders a list of items.
  """
  def index(%{items: items, meta: meta}) do
    %{
      data: Enum.map(items, &data/1),
      meta: meta,
      api_version: "v1"
    }
  end

  @doc """
  Renders a single item with full details.
  """
  def show(%{item: item}) do
    %{
      data: item |> data() |> Map.merge(detail(item)),
      api_version: "v1"
    }
  end

  @doc """
  Renders an error response.
  """
  def error(%{error: message, status: status}) do
    %{
      error: %{
        message: message,
        status: status
      },
      api_version: "v1"
    }
  end

  # Base data included in both list and detail views
  defp data(%Item{} = item) do
    %{
      id: item.item_id,
      name: item.name,
      members: item.members,
      tradeable: item.tradeable,
      equipable: item.equipable,
      stackable: item.stackable,
      buy_limit: item.buy_limit,
      high_alch: item.high_alch,
      low_alch: item.low_alch,
      wiki_url: wiki_url(item.wiki_slug)
    }
  end

  # Additional detail for single item view
  defp detail(%Item{} = item) do
    %{
      quest_item: item.quest_item,
      value: item.value,
      weight: item.weight,
      examine: item.examine,
      release_date: item.release_date,
      equipment_stats: item.equipment_stats,
      icon_url: icon_url(item.icon_key)
    }
  end

  defp wiki_url(nil), do: nil
  defp wiki_url(slug), do: "/osrs/#{slug}"

  defp icon_url(nil), do: nil
  defp icon_url(key), do: "/osrs/images/#{Path.basename(key)}"
end
