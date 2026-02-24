defmodule Droodotfoo.Wiki.Content.CrossReference do
  @moduledoc """
  Cross-references between articles from different sources.

  Links related content across wiki sources (e.g., OSRS item -> Wikipedia article).
  Can be auto-detected via pg_trgm similarity or manually curated.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @relationships ~w(same_topic related see_also)a

  schema "cross_references" do
    belongs_to(:article, Droodotfoo.Wiki.Content.Article)
    belongs_to(:related_article, Droodotfoo.Wiki.Content.Article)
    field(:relationship, Ecto.Enum, values: @relationships)
    field(:confidence, :float)
    field(:auto_detected, :boolean, default: false)

    timestamps(type: :utc_datetime)
  end

  def changeset(ref \\ %__MODULE__{}, attrs) do
    ref
    |> cast(attrs, [:article_id, :related_article_id, :relationship, :confidence, :auto_detected])
    |> validate_required([:article_id, :related_article_id, :relationship])
    |> validate_number(:confidence, greater_than_or_equal_to: 0, less_than_or_equal_to: 1)
    |> unique_constraint([:article_id, :related_article_id])
    |> foreign_key_constraint(:article_id)
    |> foreign_key_constraint(:related_article_id)
  end
end
