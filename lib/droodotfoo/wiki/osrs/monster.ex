defmodule Droodotfoo.Wiki.OSRS.Monster do
  @moduledoc """
  OSRS Monster schema for structured game data.

  Extracted from wiki infoboxes during ingestion.
  Serves the GEX API at /osrs/api/v1/monsters.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "osrs_monsters" do
    field(:monster_id, :integer)
    field(:name, :string)
    field(:combat_level, :integer)
    field(:hitpoints, :integer)
    field(:max_hit, :integer)
    field(:attack_style, :string)
    field(:slayer_level, :integer)
    field(:slayer_xp, :float)
    field(:members, :boolean)
    field(:wiki_slug, :string)
    field(:examine, :string)
    field(:release_date, :date)
    field(:locations, {:array, :string}, default: [])
    field(:drops, :map, default: %{})

    timestamps(type: :utc_datetime)
  end

  @required ~w(monster_id name)a
  @optional ~w(combat_level hitpoints max_hit attack_style slayer_level
               slayer_xp members wiki_slug examine release_date
               locations drops)a

  def changeset(monster \\ %__MODULE__{}, attrs) do
    monster
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> unique_constraint(:monster_id)
  end
end
