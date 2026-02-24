defmodule Droodotfoo.Repo.Migrations.CreateDocuments do
  use Ecto.Migration

  def change do
    create table(:documents) do
      add :title, :string, null: false
      add :slug, :string, null: false
      add :content_type, :string, null: false
      add :file_key, :string, null: false
      add :file_size, :integer, null: false
      add :extracted_text, :text
      add :metadata, :map, default: %{}
      add :tags, {:array, :string}, default: []

      timestamps(type: :utc_datetime)
    end

    create unique_index(:documents, [:slug])
    create index(:documents, [:content_type])
    create index(:documents, [:tags], using: :gin)

    # Full-text search on title and extracted text
    execute """
            CREATE INDEX documents_fts_idx ON documents
            USING gin(to_tsvector('english', coalesce(title, '') || ' ' || coalesce(extracted_text, '')))
            """,
            "DROP INDEX documents_fts_idx"
  end
end
