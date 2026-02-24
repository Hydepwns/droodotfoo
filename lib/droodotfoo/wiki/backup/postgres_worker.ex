defmodule Droodotfoo.Wiki.Backup.PostgresWorker do
  @moduledoc """
  Oban worker for PostgreSQL database backups.

  Runs daily at 3am (configured in runtime.exs) to:
  1. Dump the database using pg_dump
  2. Compress with gzip
  3. Upload to MinIO backups bucket
  4. Prune old backups (keep last 7)

  ## Manual Invocation

      # Run backup now
      %{} |> Droodotfoo.Wiki.Backup.PostgresWorker.new() |> Oban.insert()

      # Skip pruning
      %{prune: false} |> Droodotfoo.Wiki.Backup.PostgresWorker.new() |> Oban.insert()

  """

  use Oban.Worker,
    queue: :backups,
    max_attempts: 2,
    unique: [period: 3600, states: [:available, :scheduled, :executing]]

  require Logger

  alias Droodotfoo.Wiki.Storage

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    prune? = Map.get(args, "prune", true)

    with {:ok, filename, size} <- create_backup(),
         :ok <- maybe_prune(prune?) do
      Logger.info("Backup completed: #{filename} (#{size})")
      :ok
    else
      {:error, reason} ->
        Logger.error("Backup failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp create_backup do
    timestamp = Calendar.strftime(DateTime.utc_now(), "%Y%m%d-%H%M%S")
    filename = "wiki-db-#{timestamp}.sql.gz"
    tmp_path = Path.join(System.tmp_dir!(), filename)

    try do
      with :ok <- run_pg_dump(tmp_path),
           {:ok, body} <- File.read(tmp_path),
           :ok <- Storage.put_backup(filename, body) do
        {:ok, filename, format_size(byte_size(body))}
      end
    after
      File.rm(tmp_path)
    end
  end

  defp run_pg_dump(output_path) do
    db_config = Application.fetch_env!(:droodotfoo, Droodotfoo.Repo)

    # Build connection string or use URL
    {env, args} =
      case Keyword.get(db_config, :url) do
        nil ->
          # Build from individual config
          host = Keyword.get(db_config, :hostname, "localhost")
          port = Keyword.get(db_config, :port, 5432)
          database = Keyword.fetch!(db_config, :database)
          username = Keyword.fetch!(db_config, :username)
          password = Keyword.get(db_config, :password, "")

          env = [{"PGPASSWORD", password}]

          args = [
            "-h",
            host,
            "-p",
            to_string(port),
            "-U",
            username,
            "-d",
            database,
            "--no-owner",
            "--no-acl",
            "-Z",
            "9"
          ]

          {env, args}

        url ->
          # Use connection URL directly
          {[], [url, "--no-owner", "--no-acl", "-Z", "9"]}
      end

    Logger.info("Running pg_dump...")

    case System.cmd("pg_dump", args, env: env, stderr_to_stdout: true) do
      {output, 0} ->
        File.write!(output_path, output)
        :ok

      {error, code} ->
        Logger.error("pg_dump failed (exit #{code}): #{error}")
        {:error, {:pg_dump_failed, code, error}}
    end
  end

  defp maybe_prune(false), do: :ok

  defp maybe_prune(true) do
    Logger.info("Pruning old backups...")
    Storage.prune_backups(7)
  end

  defp format_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_size(bytes) when bytes < 1024 * 1024, do: "#{Float.round(bytes / 1024, 1)} KB"
  defp format_size(bytes), do: "#{Float.round(bytes / 1024 / 1024, 1)} MB"
end
