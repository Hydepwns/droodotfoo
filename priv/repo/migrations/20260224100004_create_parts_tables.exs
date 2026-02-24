defmodule Droodotfoo.Repo.Migrations.CreatePartsTables do
  use Ecto.Migration

  def change do
    create table(:vehicles) do
      add :year, :integer, null: false
      add :make, :string, null: false
      add :model, :string, null: false
      add :engine, :string
      add :trim, :string
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:vehicles, [:year, :make, :model, :engine, :trim])
    create index(:vehicles, [:make])
    create index(:vehicles, [:year])

    create table(:parts) do
      add :part_number, :string, null: false
      add :name, :string, null: false
      add :description, :text
      add :category, :string, null: false, default: "other"
      add :manufacturer, :string
      add :oem_numbers, {:array, :string}, default: []
      add :cross_references, {:array, :string}, default: []
      add :notes, :text
      add :image_keys, {:array, :string}, default: []
      add :source_url, :string
      add :price_cents, :integer
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:parts, [:part_number])
    create index(:parts, [:category])
    create index(:parts, [:manufacturer])

    # GIN index for array searches
    execute(
      "CREATE INDEX parts_oem_numbers_idx ON parts USING GIN (oem_numbers)",
      "DROP INDEX parts_oem_numbers_idx"
    )

    # Full-text search on parts
    execute(
      """
      CREATE INDEX parts_fts_idx ON parts
      USING gin(to_tsvector('english', coalesce(name, '') || ' ' || coalesce(part_number, '') || ' ' || coalesce(description, '')))
      """,
      "DROP INDEX parts_fts_idx"
    )

    create table(:part_fitments, primary_key: false) do
      add :part_id, references(:parts, on_delete: :delete_all), null: false, primary_key: true

      add :vehicle_id, references(:vehicles, on_delete: :delete_all),
        null: false,
        primary_key: true

      add :notes, :string
      add :verified, :boolean, default: false

      timestamps(type: :utc_datetime)
    end

    create index(:part_fitments, [:vehicle_id])
  end
end
