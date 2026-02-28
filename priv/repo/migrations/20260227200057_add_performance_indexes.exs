defmodule Droodotfoo.Repo.Migrations.AddPerformanceIndexes do
  use Ecto.Migration

  def change do
    # Index for embedding worker queries (articles without embeddings)
    create_if_not_exists index(:articles, [:embedded_at])

    # Composite index for sync worker queries
    create_if_not_exists index(:articles, [:status, :synced_at])

    # Index for sync run lookups
    create_if_not_exists index(:sync_runs, [:source, :status, :completed_at])

    # Index for document queries by inserted_at (creation time)
    create_if_not_exists index(:documents, [:inserted_at])
  end
end
