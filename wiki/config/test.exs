import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :wiki, Wiki.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "wiki_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# Oban testing mode - jobs execute inline
config :wiki, Oban, testing: :inline

# MediaWiki client for tests (uses Bypass)
config :wiki, Wiki.Ingestion.MediaWikiClient,
  base_url: "http://localhost:9999/api.php",
  user_agent: "DrooFoo-WikiMirror/1.0 (test)",
  rate_limit_ms: 0

# MinIO/S3 mock for tests
config :ex_aws,
  access_key_id: "test",
  secret_access_key: "test",
  region: "us-east-1"

config :ex_aws, :s3,
  scheme: "http://",
  host: "localhost",
  port: 9000

config :wiki, Wiki.Storage,
  bucket_wiki: "test-wiki",
  bucket_library: "test-library",
  bucket_backups: "test-backups"

# Disable PromEx polling in tests (avoids sandbox ownership issues)
config :wiki, Wiki.PromEx, disabled: true

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :wiki, WikiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "5PABi94GpyHFV5OLGWPw73GL2jda30Tb2qGaqt11S5kD7oR8FCXYjgw7VnWEW7sJ",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
