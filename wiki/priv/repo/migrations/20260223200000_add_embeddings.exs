defmodule Wiki.Repo.Migrations.AddEmbeddings do
  use Ecto.Migration

  def up do
    # Skip for now - pgvector extension library not installed
    # Add embedded_at column without vector type
    alter table(:articles) do
      add :embedded_at, :utc_datetime
    end
  end

  def down do
    execute "DROP INDEX IF EXISTS articles_embedding_idx"

    alter table(:articles) do
      remove_if_exists :embedding, :vector
      remove_if_exists :embedded_at, :utc_datetime
    end
  end
end
