defmodule Wiki.OSRS.Item do
  @moduledoc """
  OSRS Item schema for structured game data.

  Extracted from wiki infoboxes during ingestion.
  Serves the GEX API at /osrs/api/v1/items.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "osrs_items" do
    field :item_id, :integer
    field :name, :string
    field :members, :boolean
    field :tradeable, :boolean
    field :equipable, :boolean
    field :stackable, :boolean
    field :quest_item, :boolean
    field :buy_limit, :integer
    field :high_alch, :integer
    field :low_alch, :integer
    field :value, :integer
    field :weight, :float
    field :examine, :string
    field :release_date, :date
    field :wiki_slug, :string
    field :icon_key, :string
    field :equipment_stats, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  @required ~w(item_id name)a
  @optional ~w(members tradeable equipable stackable quest_item buy_limit
               high_alch low_alch value weight examine release_date
               wiki_slug icon_key equipment_stats)a

  def changeset(item \\ %__MODULE__{}, attrs) do
    item
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> unique_constraint(:item_id)
  end
end
