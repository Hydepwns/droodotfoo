Postgrex.Types.define(
  Wiki.PostgresTypes,
  [Pgvector.Extensions.Vector] ++ Ecto.Adapters.Postgres.extensions()
)
