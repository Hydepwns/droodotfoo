defmodule Wiki.Repo.Migrations.AddEmbeddingColumn do
  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS vector"

    alter table(:articles) do
      add :embedding, :vector, size: 768
    end

    # HNSW index for fast approximate nearest neighbor search
    execute """
    CREATE INDEX articles_embedding_idx ON articles
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64)
    """
  end

  def down do
    execute "DROP INDEX IF EXISTS articles_embedding_idx"

    alter table(:articles) do
      remove :embedding
    end
  end
end
