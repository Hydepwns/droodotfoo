defmodule Droodotfoo.Wiki.Library.Document do
  @moduledoc """
  Schema for personal document library.

  Documents are stored in MinIO with metadata in Postgres.
  Supports PDFs, DOCX, and other file types with text extraction.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @allowed_types ~w(
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.oasis.opendocument.text
    text/plain
    text/markdown
    text/html
  )

  schema "documents" do
    field(:title, :string)
    field(:slug, :string)
    field(:content_type, :string)
    field(:file_key, :string)
    field(:file_size, :integer)
    field(:extracted_text, :string)
    field(:metadata, :map, default: %{})
    field(:tags, {:array, :string}, default: [])
    field(:content_hash, :string)

    has_many(:revisions, Droodotfoo.Wiki.Library.DocumentRevision)

    timestamps(type: :utc_datetime)
  end

  @doc "Changeset for creating a new document."
  def changeset(attrs) do
    changeset(%__MODULE__{}, attrs)
  end

  def changeset(document, attrs) do
    document
    |> cast(attrs, [
      :title,
      :slug,
      :content_type,
      :file_key,
      :file_size,
      :extracted_text,
      :metadata,
      :tags,
      :content_hash
    ])
    |> validate_required([:title, :slug, :content_type, :file_key, :file_size])
    |> validate_inclusion(:content_type, @allowed_types, message: "unsupported file type")
    |> validate_length(:title, min: 1, max: 255)
    |> validate_format(:slug, ~r/^[a-z0-9-]+$/,
      message: "must be lowercase alphanumeric with dashes"
    )
    |> unique_constraint(:slug)
  end

  @doc "Generate a slug from a title."
  def slugify(title) when is_binary(title) do
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
    |> String.slice(0, 100)
  end

  @doc "Check if a content type is allowed."
  def allowed_type?(content_type), do: content_type in @allowed_types

  @doc "Get human-readable file type."
  def type_label("application/pdf"), do: "PDF"
  def type_label("application/msword"), do: "Word"

  def type_label("application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
    do: "Word"

  def type_label("application/vnd.oasis.opendocument.text"), do: "ODT"
  def type_label("text/plain"), do: "Text"
  def type_label("text/markdown"), do: "Markdown"
  def type_label("text/html"), do: "HTML"
  def type_label(_), do: "File"

  @doc "Get abbreviated file type for badges."
  def type_abbr("application/pdf"), do: "PDF"
  def type_abbr("application/msword"), do: "DOC"

  def type_abbr("application/vnd.openxmlformats-officedocument.wordprocessingml.document"),
    do: "DOCX"

  def type_abbr("application/vnd.oasis.opendocument.text"), do: "ODT"
  def type_abbr("text/plain"), do: "TXT"
  def type_abbr("text/markdown"), do: "MD"
  def type_abbr("text/html"), do: "HTML"
  def type_abbr(_), do: "FILE"

  @doc "Format file size for display."
  def format_size(bytes) when bytes < 1024, do: "#{bytes} B"
  def format_size(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"
  def format_size(bytes), do: "#{Float.round(bytes / 1024 / 1024, 1)} MB"
end
