defmodule Droodotfoo.Wiki.Parts.Vehicle do
  @moduledoc """
  Vehicle schema for auto parts fitment.

  Represents a vehicle that parts can fit. Vehicles are identified by
  year, make, model, and optional engine/trim.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "vehicles" do
    field(:year, :integer)
    field(:make, :string)
    field(:model, :string)
    field(:engine, :string)
    field(:trim, :string)
    field(:metadata, :map, default: %{})

    many_to_many(:parts, Droodotfoo.Wiki.Parts.Part, join_through: "part_fitments")

    timestamps(type: :utc_datetime)
  end

  @required ~w(year make model)a
  @optional ~w(engine trim metadata)a

  def changeset(vehicle \\ %__MODULE__{}, attrs) do
    vehicle
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_number(:year, greater_than: 1885, less_than: 2100)
    |> unique_constraint([:year, :make, :model, :engine, :trim])
  end

  @doc "Format vehicle as display string."
  @spec display_name(t()) :: String.t()
  def display_name(%__MODULE__{} = v) do
    base = "#{v.year} #{v.make} #{v.model}"

    extras =
      [v.engine, v.trim]
      |> Enum.reject(&is_nil/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.join(" ")

    if extras == "", do: base, else: "#{base} (#{extras})"
  end
end
