defmodule Wiki.Ingestion.SyncRun do
  @moduledoc """
  Tracks ingestion sync runs for each source.

  Records progress, errors, and timing for incremental sync support.
  """

  use Ecto.Schema
  import Ecto.{Changeset, Query}

  @type t :: %__MODULE__{}

  @sources ~w(osrs nlab wikipedia vintage_machinery wikiart)a
  @statuses ~w(running completed failed)a

  schema "sync_runs" do
    field :source, Ecto.Enum, values: @sources
    field :strategy, :string
    field :pages_processed, :integer, default: 0
    field :pages_created, :integer, default: 0
    field :pages_updated, :integer, default: 0
    field :pages_unchanged, :integer, default: 0
    field :errors, {:array, :map}, default: []
    field :started_at, :utc_datetime
    field :completed_at, :utc_datetime
    field :status, Ecto.Enum, values: @statuses
    field :error_message, :string

    timestamps(type: :utc_datetime)
  end

  @doc "Insert a new running sync run."
  def start!(source, strategy) do
    changeset(%{
      source: source,
      strategy: strategy,
      status: :running,
      started_at: DateTime.utc_now()
    })
    |> Wiki.Repo.insert!()
  end

  @doc "Mark a sync run completed or failed."
  def complete!(run, {:ok, stats}) do
    run
    |> changeset(
      Map.put(stats, :status, :completed)
      |> Map.put(:completed_at, DateTime.utc_now())
    )
    |> Wiki.Repo.update!()
  end

  def complete!(run, {:error, reason}) do
    run
    |> changeset(%{
      status: :failed,
      error_message: to_string(reason),
      completed_at: DateTime.utc_now()
    })
    |> Wiki.Repo.update!()
  end

  @doc "Timestamp of last successful sync for a source."
  @spec last_completed_at(atom()) :: DateTime.t() | nil
  def last_completed_at(source) do
    __MODULE__
    |> where([r], r.source == ^source and r.status == :completed)
    |> order_by([r], desc: r.completed_at)
    |> limit(1)
    |> select([r], r.completed_at)
    |> Wiki.Repo.one()
  end

  defp changeset(attrs), do: changeset(%__MODULE__{}, attrs)

  defp changeset(run, attrs) do
    cast(run, attrs, [
      :source,
      :strategy,
      :pages_processed,
      :pages_created,
      :pages_updated,
      :pages_unchanged,
      :errors,
      :started_at,
      :completed_at,
      :status,
      :error_message
    ])
  end
end
