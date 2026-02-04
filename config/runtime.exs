import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# Set environment for Droodotfoo.Core.Config (avoids Mix.env() at runtime)
config :droodotfoo, :environment, config_env()

# Session security salts are configured in config.exs/prod.exs (compile-time)
# because they're used in module attributes that are evaluated at compile time.
# For releases, these are baked into the release at build time.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/droodotfoo start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :droodotfoo, DroodotfooWeb.Endpoint, server: true
end

# Blog API token for Obsidian publishing (all environments)
config :droodotfoo, :blog_api_token, System.get_env("BLOG_API_TOKEN")

# Sentry error tracking (all environments, but only active when DSN is set)
if sentry_dsn = System.get_env("SENTRY_DSN") do
  config :sentry,
    dsn: sentry_dsn,
    environment_name: config_env(),
    enable_source_code_context: true,
    root_source_code_paths: [File.cwd!()],
    # Filter out noisy events
    before_send: {Droodotfoo.SentryFilter, :filter_event}
end

# OpenTelemetry configuration (production)
# Export traces to Sentry via OTLP if SENTRY_DSN is set
# Or to a custom OTLP endpoint if OTEL_EXPORTER_OTLP_ENDPOINT is set
if otel_endpoint = System.get_env("OTEL_EXPORTER_OTLP_ENDPOINT") do
  config :opentelemetry_exporter,
    otlp_endpoint: otel_endpoint,
    otlp_headers:
      (System.get_env("OTEL_EXPORTER_OTLP_HEADERS") || "")
      |> String.split(",", trim: true)
      |> Enum.map(fn header ->
        case String.split(header, "=", parts: 2) do
          [key, value] -> {String.trim(key), String.trim(value)}
          _ -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)
else
  # Disable OTLP export if no endpoint configured
  config :opentelemetry, traces_exporter: :none
end

# GitHub API token for higher rate limits (all environments, optional)
config :droodotfoo, :github_token, System.get_env("GITHUB_TOKEN")

# Resume source configuration (all environments)
# Load resume from Fileverse/IPFS if configured, otherwise use hardcoded data
if resume_cid = System.get_env("RESUME_IPFS_CID") do
  config :droodotfoo, :resume_source,
    type: :ipfs,
    cid: resume_cid
end

if resume_url = System.get_env("RESUME_FILEVERSE_URL") do
  config :droodotfoo, :resume_source,
    type: :fileverse,
    url: resume_url
end

if config_env() == :prod do
  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  # CDN configuration for Cloudflare Pages
  # If CDN_HOST is set, static assets will be served from there
  cdn_host = System.get_env("CDN_HOST")

  config :droodotfoo, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  # Spotify API configuration
  config :droodotfoo, :spotify,
    client_id: System.get_env("SPOTIFY_CLIENT_ID"),
    client_secret: System.get_env("SPOTIFY_CLIENT_SECRET"),
    redirect_uri:
      System.get_env("SPOTIFY_REDIRECT_URI") || "https://#{host}/auth/spotify/callback"

  # Web3/Ethereum configuration
  config :ethereumex,
    url: System.get_env("ETHEREUM_RPC_URL") || "https://eth.llamarpc.com",
    http_options: [timeout: 30_000, recv_timeout: 30_000]

  config :droodotfoo, Droodotfoo.Web3.Manager,
    default_chain_id: String.to_integer(System.get_env("CHAIN_ID") || "1"),
    opensea_api_key: System.get_env("OPENSEA_API_KEY"),
    alchemy_api_key: System.get_env("ALCHEMY_API_KEY"),
    etherscan_api_key: System.get_env("ETHERSCAN_API_KEY"),
    walletconnect_project_id: System.get_env("WALLETCONNECT_PROJECT_ID")

  endpoint_config = [
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Bind to all IPv4 interfaces for Fly.io compatibility
      # Fly.io's proxy expects apps to listen on 0.0.0.0
      ip: {0, 0, 0, 0},
      port: port,
      # Bandit thousand_island settings
      thousand_island_options: [
        # Timeout for reading request data (30s)
        read_timeout: 30_000,
        # Grace period for connections during shutdown (60s)
        shutdown_timeout: 60_000
      ]
    ],
    secret_key_base: secret_key_base
  ]

  # Add static_url config if CDN is configured
  endpoint_config =
    if cdn_host do
      Keyword.put(endpoint_config, :static_url, host: cdn_host, scheme: "https")
    else
      endpoint_config
    end

  config :droodotfoo, DroodotfooWeb.Endpoint, endpoint_config

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :droodotfoo, DroodotfooWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :droodotfoo, DroodotfooWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
end
