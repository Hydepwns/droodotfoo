Postgrex.Types.define(
  Droodotfoo.PostgresTypes,
  [Pgvector.Extensions.Vector] ++ Ecto.Adapters.Postgres.extensions()
)
