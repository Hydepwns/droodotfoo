defmodule Droodotfoo.Wiki.Content.CrossLink do
  @moduledoc """
  Schema for cross-source article links.

  Represents a relationship between two articles from different sources,
  detected via pg_trgm fuzzy matching or manual curation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @relationships ~w(same_topic related see_also)a

  schema "cross_links" do
    belongs_to(:source_article, Droodotfoo.Wiki.Content.Article)
    belongs_to(:target_article, Droodotfoo.Wiki.Content.Article)

    field(:relationship, Ecto.Enum, values: @relationships, default: :related)
    field(:confidence, :float)
    field(:metadata, :map, default: %{})

    timestamps(type: :utc_datetime)
  end

  @required ~w(source_article_id target_article_id)a
  @optional ~w(relationship confidence metadata)a

  def changeset(cross_link \\ %__MODULE__{}, attrs) do
    cross_link
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_number(:confidence, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    |> foreign_key_constraint(:source_article_id)
    |> foreign_key_constraint(:target_article_id)
    |> unique_constraint([:source_article_id, :target_article_id])
  end
end
