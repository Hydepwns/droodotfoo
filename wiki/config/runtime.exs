import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere.

if System.get_env("PHX_SERVER") do
  config :wiki, WikiWeb.Endpoint, server: true
end

config :wiki, WikiWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT", "4040"))]

if config_env() == :prod do
  # --- Database ---

  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :wiki, Wiki.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE", "10")),
    socket_options: maybe_ipv6

  # --- Phoenix ---

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  session_signing_salt =
    System.get_env("SESSION_SIGNING_SALT") ||
      raise """
      environment variable SESSION_SIGNING_SALT is missing.
      You can generate one by calling: mix phx.gen.secret 32
      """

  host = System.get_env("PHX_HOST", "wiki.droo.foo")

  config :wiki, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :wiki, WikiWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT", "4040"))],
    secret_key_base: secret_key_base,
    server: true,
    session_options: [
      store: :cookie,
      key: "_droo_session",
      signing_salt: session_signing_salt,
      domain: ".droo.foo"
    ]

  # --- MinIO ---

  config :ex_aws,
    access_key_id: System.fetch_env!("MINIO_ACCESS_KEY"),
    secret_access_key: System.fetch_env!("MINIO_SECRET_KEY"),
    region: "us-east-1"

  config :ex_aws, :s3,
    scheme: "http://",
    host: System.get_env("MINIO_HOST", "localhost"),
    port: String.to_integer(System.get_env("MINIO_PORT", "9000"))

  config :wiki, Wiki.Storage,
    bucket_wiki: System.get_env("MINIO_BUCKET_WIKI", "droo-wiki"),
    bucket_library: System.get_env("MINIO_BUCKET_LIBRARY", "droo-library"),
    bucket_backups: System.get_env("MINIO_BUCKET_BACKUPS", "xochimilco-backups")

  # --- MediaWiki Client ---

  config :wiki, Wiki.Ingestion.MediaWikiClient,
    base_url: "https://oldschool.runescape.wiki/api.php",
    user_agent: "DrooFoo-WikiMirror/1.0 (https://droo.foo; contact@droo.foo)",
    rate_limit_ms: 1_000

  # --- Oban ---

  config :wiki, Oban,
    engine: Oban.Engines.Basic,
    repo: Wiki.Repo,
    queues: [ingestion: 2, images: 4, backups: 1],
    plugins: [
      Oban.Plugins.Pruner,
      {Oban.Plugins.Cron,
       crontab: [
         # OSRS Wiki sync every 15 minutes
         {"*/15 * * * *", Wiki.Ingestion.OSRSSyncWorker},
         # nLab sync daily at 4am
         {"0 4 * * *", Wiki.Ingestion.NLabSyncWorker},
         # PostgreSQL backup daily at 3am
         {"0 3 * * *", Wiki.Backup.PostgresWorker}
       ]}
    ]

  # --- PromEx ---

  config :wiki, Wiki.PromEx,
    manual_metrics_start_delay: :no_delay,
    grafana: :disabled
end
