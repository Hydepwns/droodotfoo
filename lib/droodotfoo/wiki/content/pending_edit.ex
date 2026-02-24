defmodule Droodotfoo.Wiki.Content.PendingEdit do
  @moduledoc """
  Schema for community edit suggestions.

  Users can suggest edits to articles. These are reviewed by admins
  via the Tailnet-only admin interface.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @statuses ~w(pending approved rejected)a

  schema "pending_edits" do
    belongs_to(:article, Droodotfoo.Wiki.Content.Article)
    field(:suggested_content, :string)
    field(:reason, :string)
    field(:submitter_email, :string)
    field(:submitter_ip, :string)
    field(:status, Ecto.Enum, values: @statuses, default: :pending)
    field(:reviewed_at, :utc_datetime)
    field(:reviewer_note, :string)

    timestamps(type: :utc_datetime)
  end

  @required ~w(article_id suggested_content submitter_ip)a
  @optional ~w(reason submitter_email)a

  @doc """
  Changeset for creating a new pending edit.
  """
  def changeset(pending_edit \\ %__MODULE__{}, attrs) do
    pending_edit
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> validate_length(:suggested_content, min: 1, max: 500_000)
    |> validate_length(:reason, max: 2000)
    |> validate_format(:submitter_email, ~r/@/, message: "must be a valid email")
    |> foreign_key_constraint(:article_id)
  end

  @doc """
  Changeset for approving or rejecting an edit.
  """
  def review_changeset(pending_edit, attrs) do
    pending_edit
    |> cast(attrs, [:status, :reviewer_note, :reviewed_at])
    |> validate_required([:status, :reviewed_at])
    |> validate_inclusion(:status, [:approved, :rejected])
  end
end
