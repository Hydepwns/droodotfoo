defmodule Droodotfoo.Repo.Migrations.CreatePendingEdits do
  use Ecto.Migration

  def change do
    create table(:pending_edits) do
      add :article_id, references(:articles, on_delete: :delete_all), null: false
      add :suggested_content, :text, null: false
      add :reason, :text
      add :submitter_email, :string
      add :submitter_ip, :string, null: false
      add :status, :string, null: false, default: "pending"
      add :reviewed_at, :utc_datetime
      add :reviewer_note, :text

      timestamps(type: :utc_datetime)
    end

    create index(:pending_edits, [:article_id])
    create index(:pending_edits, [:status])
    create index(:pending_edits, [:submitter_ip])
  end
end
