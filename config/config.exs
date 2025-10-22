# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configure timezone database
config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :droodotfoo,
  generators: [timestamp_type: :utc_datetime]

# Terminal configuration
config :droodotfoo, :terminal,
  width: 80,
  height: 24,
  default_font_size: 16,
  refresh_rate: 60

# Performance settings
config :droodotfoo, :performance,
  adaptive_refresh: true,
  min_fps: 15,
  max_fps: 60,
  debounce_delay: 50

# Configures the endpoint
config :droodotfoo, DroodotfooWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: DroodotfooWeb.ErrorHTML, json: DroodotfooWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Droodotfoo.PubSub,
  live_view: [signing_salt: "Q0b0apxR"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  droodotfoo: [
    args:
      ~w(js/app.ts --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=. --loader:.ts=ts --loader:.tsx=tsx),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  droodotfoo: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure Swoosh for email functionality
config :droodotfoo, Droodotfoo.Mailer, adapter: Swoosh.Adapters.Local

# Configure ChromicPDF
config :chromic_pdf,
  # Use offline mode (don't spawn browser automatically)
  offline: false,
  # Disable telemetry
  discard_utility_output: true

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
