defmodule Droodotfoo.Wiki.Library.DocumentRevision do
  @moduledoc """
  Schema for document revision history.

  Tracks previous versions of documents for version control.
  Each revision stores the file key in MinIO and metadata.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Droodotfoo.Wiki.Library.Document

  @type t :: %__MODULE__{}

  schema "document_revisions" do
    belongs_to(:document, Document)
    field(:content_hash, :string)
    field(:file_key, :string)
    field(:file_size, :integer)
    field(:comment, :string)

    timestamps(type: :utc_datetime)
  end

  @required ~w(document_id content_hash file_key file_size)a
  @optional ~w(comment)a

  def changeset(revision \\ %__MODULE__{}, attrs) do
    revision
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> foreign_key_constraint(:document_id)
  end
end
