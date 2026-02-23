defmodule Wiki.Parts.PartFitment do
  @moduledoc """
  Join table for parts to vehicles fitment.

  Tracks which parts fit which vehicles, with optional notes
  about fitment specifics.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key false
  schema "part_fitments" do
    belongs_to :part, Wiki.Parts.Part, primary_key: true
    belongs_to :vehicle, Wiki.Parts.Vehicle, primary_key: true

    field :notes, :string
    field :verified, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  def changeset(fitment \\ %__MODULE__{}, attrs) do
    fitment
    |> cast(attrs, [:part_id, :vehicle_id, :notes, :verified])
    |> validate_required([:part_id, :vehicle_id])
    |> foreign_key_constraint(:part_id)
    |> foreign_key_constraint(:vehicle_id)
    |> unique_constraint([:part_id, :vehicle_id], name: :part_fitments_pkey)
  end
end
