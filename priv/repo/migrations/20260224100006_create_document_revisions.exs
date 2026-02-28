defmodule Droodotfoo.Repo.Migrations.CreateDocumentRevisions do
  use Ecto.Migration

  def change do
    create table(:document_revisions) do
      add :document_id, references(:documents, on_delete: :delete_all), null: false
      add :content_hash, :string, null: false
      add :file_key, :string, null: false
      add :file_size, :integer, null: false
      add :comment, :text

      timestamps(type: :utc_datetime)
    end

    create index(:document_revisions, [:document_id])
    create index(:document_revisions, [:inserted_at])

    alter table(:documents) do
      add :content_hash, :string
    end
  end
end
