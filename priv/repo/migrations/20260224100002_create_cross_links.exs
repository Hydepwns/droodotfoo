defmodule Droodotfoo.Repo.Migrations.CreateCrossLinks do
  use Ecto.Migration

  def change do
    create table(:cross_links) do
      add :source_article_id, references(:articles, on_delete: :delete_all), null: false
      add :target_article_id, references(:articles, on_delete: :delete_all), null: false
      add :relationship, :string, null: false, default: "related"
      add :confidence, :float
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:cross_links, [:source_article_id])
    create index(:cross_links, [:target_article_id])
    create unique_index(:cross_links, [:source_article_id, :target_article_id])
  end
end
