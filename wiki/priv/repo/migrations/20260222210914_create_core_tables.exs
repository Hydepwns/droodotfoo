defmodule Wiki.Repo.Migrations.CreateCoreTables do
  use Ecto.Migration

  def change do
    # Enable pg_trgm for fuzzy text matching
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm", "DROP EXTENSION IF EXISTS pg_trgm"

    # --- Articles ---

    create table(:articles) do
      add :source, :string, null: false
      add :slug, :string, null: false
      add :title, :string, null: false
      add :extracted_text, :text
      add :rendered_html_key, :string
      add :raw_content_key, :string
      add :upstream_url, :string
      add :upstream_hash, :string
      add :status, :string, null: false, default: "synced"
      add :license, :string
      add :metadata, :map, default: %{}
      add :synced_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:articles, [:source, :slug])
    create index(:articles, [:source])
    create index(:articles, [:status])

    # Full-text search index
    execute """
            CREATE INDEX articles_fts_idx ON articles
            USING gin(to_tsvector('english', coalesce(title, '') || ' ' || coalesce(extracted_text, '')))
            """,
            "DROP INDEX articles_fts_idx"

    # --- Revisions ---

    create table(:revisions) do
      add :article_id, references(:articles, on_delete: :delete_all), null: false
      add :upstream_revision_id, :string
      add :content_hash, :string, null: false
      add :raw_content_key, :string
      add :editor, :string
      add :comment, :text
      add :synced_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:revisions, [:article_id])

    # --- Redirects ---

    create table(:wiki_redirects) do
      add :source, :string, null: false
      add :from_slug, :string, null: false
      add :to_slug, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:wiki_redirects, [:source, :from_slug])

    # --- Cross-references ---

    create table(:cross_references) do
      add :article_id, references(:articles, on_delete: :delete_all), null: false
      add :related_article_id, references(:articles, on_delete: :delete_all), null: false
      add :relationship, :string, null: false
      add :confidence, :float
      add :auto_detected, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:cross_references, [:article_id, :related_article_id])
    create index(:cross_references, [:related_article_id])

    # --- OSRS Items ---

    create table(:osrs_items) do
      add :item_id, :integer, null: false
      add :name, :string, null: false
      add :members, :boolean
      add :tradeable, :boolean
      add :equipable, :boolean
      add :stackable, :boolean
      add :quest_item, :boolean
      add :buy_limit, :integer
      add :high_alch, :integer
      add :low_alch, :integer
      add :value, :integer
      add :weight, :float
      add :examine, :text
      add :release_date, :date
      add :wiki_slug, :string
      add :icon_key, :string
      add :equipment_stats, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:osrs_items, [:item_id])
    create index(:osrs_items, [:name])
    create index(:osrs_items, [:tradeable])

    # --- OSRS Monsters ---

    create table(:osrs_monsters) do
      add :monster_id, :integer, null: false
      add :name, :string, null: false
      add :combat_level, :integer
      add :hitpoints, :integer
      add :max_hit, :integer
      add :attack_style, :string
      add :slayer_level, :integer
      add :slayer_xp, :float
      add :members, :boolean
      add :wiki_slug, :string
      add :examine, :text
      add :release_date, :date
      add :locations, {:array, :string}, default: []
      add :drops, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:osrs_monsters, [:monster_id])
    create index(:osrs_monsters, [:name])

    # --- Sync Runs ---

    create table(:sync_runs) do
      add :source, :string, null: false
      add :strategy, :string
      add :pages_processed, :integer, default: 0
      add :pages_created, :integer, default: 0
      add :pages_updated, :integer, default: 0
      add :pages_unchanged, :integer, default: 0
      add :errors, {:array, :map}, default: []
      add :started_at, :utc_datetime
      add :completed_at, :utc_datetime
      add :status, :string, null: false
      add :error_message, :text

      timestamps(type: :utc_datetime)
    end

    create index(:sync_runs, [:source, :status])
    create index(:sync_runs, [:completed_at])
  end
end
