defmodule DroodotfooWeb.Wiki.OSRS.V1.MonsterJSON do
  @moduledoc """
  JSON rendering for OSRS monsters.

  Follows Phoenix 1.7+ JSON resource conventions.
  """

  alias Droodotfoo.Wiki.OSRS.Monster

  @doc """
  Renders a list of monsters.
  """
  def index(%{monsters: monsters, meta: meta}) do
    %{
      data: Enum.map(monsters, &data/1),
      meta: meta,
      api_version: "v1"
    }
  end

  @doc """
  Renders a single monster with full details.
  """
  def show(%{monster: monster}) do
    %{
      data: monster |> data() |> Map.merge(detail(monster)),
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
  defp data(%Monster{} = monster) do
    %{
      id: monster.monster_id,
      name: monster.name,
      combat_level: monster.combat_level,
      hitpoints: monster.hitpoints,
      max_hit: monster.max_hit,
      attack_style: monster.attack_style,
      members: monster.members,
      slayer_level: monster.slayer_level,
      wiki_url: wiki_url(monster.wiki_slug)
    }
  end

  # Additional detail for single monster view
  defp detail(%Monster{} = monster) do
    %{
      slayer_xp: monster.slayer_xp,
      examine: monster.examine,
      release_date: monster.release_date,
      locations: monster.locations,
      drops: monster.drops
    }
  end

  defp wiki_url(nil), do: nil
  defp wiki_url(slug), do: "/osrs/#{slug}"
end
