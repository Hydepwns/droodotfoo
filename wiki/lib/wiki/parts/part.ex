defmodule Wiki.Parts.Part do
  @moduledoc """
  Auto part schema.

  Parts are identified by part number and can fit multiple vehicles.
  Content can be added via browser clipper or manual form entry.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @categories ~w(
    engine transmission drivetrain suspension brakes
    electrical body interior cooling fuel exhaust
    steering ignition climate other
  )a

  schema "parts" do
    field :part_number, :string
    field :name, :string
    field :description, :string
    field :category, Ecto.Enum, values: @categories, default: :other
    field :manufacturer, :string
    field :oem_numbers, {:array, :string}, default: []
    field :cross_references, {:array, :string}, default: []
    field :notes, :string
    field :image_keys, {:array, :string}, default: []
    field :source_url, :string
    field :price_cents, :integer
    field :metadata, :map, default: %{}

    many_to_many :vehicles, Wiki.Parts.Vehicle, join_through: "part_fitments"

    timestamps(type: :utc_datetime)
  end

  @required ~w(part_number name)a
  @optional ~w(description category manufacturer oem_numbers cross_references
               notes image_keys source_url price_cents metadata)a

  def changeset(part \\ %__MODULE__{}, attrs) do
    part
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_length(:part_number, min: 1, max: 100)
    |> validate_number(:price_cents, greater_than_or_equal_to: 0)
    |> unique_constraint(:part_number)
  end

  @doc "Format price as currency string."
  @spec format_price(t()) :: String.t() | nil
  def format_price(%__MODULE__{price_cents: nil}), do: nil

  def format_price(%__MODULE__{price_cents: cents}) do
    dollars = div(cents, 100)
    remainder = rem(cents, 100)
    "$#{dollars}.#{String.pad_leading(to_string(remainder), 2, "0")}"
  end

  @doc "List of valid categories."
  def categories, do: @categories
end
