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
