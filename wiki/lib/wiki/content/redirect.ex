defmodule Wiki.Content.Redirect do
  @moduledoc """
  Redirect mapping for wiki pages.

  Handles alternative titles, moved pages, and common misspellings.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @sources ~w(osrs nlab wikipedia)a

  schema "wiki_redirects" do
    field :source, Ecto.Enum, values: @sources
    field :from_slug, :string
    field :to_slug, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(redirect \\ %__MODULE__{}, attrs) do
    redirect
    |> cast(attrs, [:source, :from_slug, :to_slug])
    |> validate_required([:source, :from_slug, :to_slug])
    |> unique_constraint([:source, :from_slug])
  end
end
