defmodule Droodotfoo.Wiki.Content.Revision do
  @moduledoc """
  Revision history for articles.

  Tracks changes over time for auditing and potential rollback.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "revisions" do
    belongs_to(:article, Droodotfoo.Wiki.Content.Article)
    field(:upstream_revision_id, :string)
    field(:content_hash, :string)
    field(:raw_content_key, :string)
    field(:editor, :string)
    field(:comment, :string)
    field(:synced_at, :utc_datetime)

    timestamps(type: :utc_datetime)
  end

  @required ~w(article_id content_hash)a
  @optional ~w(upstream_revision_id raw_content_key editor comment synced_at)a

  def changeset(revision \\ %__MODULE__{}, attrs) do
    revision
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> foreign_key_constraint(:article_id)
  end
end
