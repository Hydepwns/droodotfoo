defmodule Wiki.Content.Article do
  @moduledoc """
  Article schema for wiki content from multiple sources.

  Content is stored in MinIO (rendered HTML, raw wikitext/markdown).
  Metadata and FTS index are stored in PostgreSQL.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @sources ~w(osrs nlab wikipedia vintage_machinery wikiart)a
  @statuses ~w(synced diverged local_only)a

  schema "articles" do
    field :source, Ecto.Enum, values: @sources
    field :slug, :string
    field :title, :string
    field :extracted_text, :string
    field :rendered_html_key, :string
    field :raw_content_key, :string
    field :upstream_url, :string
    field :upstream_hash, :string
    field :status, Ecto.Enum, values: @statuses, default: :synced
    field :license, :string
    field :metadata, :map, default: %{}
    field :synced_at, :utc_datetime

    has_many :revisions, Wiki.Content.Revision
    has_many :cross_references, Wiki.Content.CrossReference
    has_many :outbound_links, Wiki.Content.CrossLink, foreign_key: :source_article_id
    has_many :inbound_links, Wiki.Content.CrossLink, foreign_key: :target_article_id

    timestamps(type: :utc_datetime)
  end

  @required ~w(source slug title)a
  @optional ~w(extracted_text rendered_html_key raw_content_key upstream_url
               upstream_hash status license metadata synced_at)a

  def changeset(article \\ %__MODULE__{}, attrs) do
    article
    |> cast(attrs, @required ++ @optional)
    |> validate_required(@required)
    |> unique_constraint([:source, :slug])
  end
end
