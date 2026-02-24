import Config

# Configure your database
config :droodotfoo, Droodotfoo.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "droodotfoo_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2,
  types: Droodotfoo.PostgresTypes

# Oban testing mode - jobs execute inline
config :droodotfoo, Oban, testing: :inline

# MediaWiki client for tests (uses Bypass)
config :droodotfoo, Droodotfoo.Wiki.Ingestion.MediaWikiClient,
  base_url: "http://localhost:9999/api.php",
  user_agent: "DrooFoo-WikiMirror/1.0 (test)",
  rate_limit_ms: 0

# Ollama for tests (uses Bypass)
config :droodotfoo, Droodotfoo.Wiki.Ollama,
  base_url: "http://localhost:9998",
  model: "nomic-embed-text",
  timeout: 5_000

# MinIO/S3 mock for tests
config :ex_aws,
  access_key_id: "test",
  secret_access_key: "test",
  region: "us-east-1"

config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 9000

config :droodotfoo, Droodotfoo.Wiki.Storage,
  bucket_wiki: "test-wiki",
  bucket_library: "test-library",
  bucket_backups: "test-backups"

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :droodotfoo, DroodotfooWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ZMokfGT0BKb5f7pA8rtV35UfFOYeb+7MotNj1rMtriIVdGtH+BTEelaKavv5jpcl",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
