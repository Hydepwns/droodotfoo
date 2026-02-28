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

# Forgejo Git server configuration (for git.droo.foo subdomain)
# Default to mini-axol Tailnet host for local development
config :droodotfoo, :forgejo,
  base_url: System.get_env("FORGEJO_URL", "http://mini-axol:3000"),
  token: System.get_env("FORGEJO_TOKEN"),
  default_owner: System.get_env("FORGEJO_OWNER", "droo")

# GitHub configuration for git browser (separate from :github_token)
config :droodotfoo, :github, owner: System.get_env("GITHUB_OWNER", "hydepwns")

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
  # --- Database ---
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :droodotfoo, Droodotfoo.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE", "10")),
    socket_options: maybe_ipv6,
    types: Droodotfoo.PostgresTypes

  # --- MinIO ---
  if System.get_env("MINIO_ACCESS_KEY") do
    config :ex_aws,
      access_key_id: System.fetch_env!("MINIO_ACCESS_KEY"),
      secret_access_key: System.fetch_env!("MINIO_SECRET_KEY"),
      region: "us-east-1"

    config :ex_aws, :s3,
      scheme: "http://",
      host: System.get_env("MINIO_HOST", "localhost"),
      port: String.to_integer(System.get_env("MINIO_PORT", "9000"))

    config :droodotfoo, Droodotfoo.Wiki.Storage,
      bucket_wiki: System.get_env("MINIO_BUCKET_WIKI", "droo-wiki"),
      bucket_library: System.get_env("MINIO_BUCKET_LIBRARY", "droo-library"),
      bucket_backups: System.get_env("MINIO_BUCKET_BACKUPS", "xochimilco-backups")
  end

  # --- MediaWiki Client ---
  config :droodotfoo, Droodotfoo.Wiki.Ingestion.MediaWikiClient,
    base_url: "https://oldschool.runescape.wiki/api.php",
    user_agent: "DrooFoo-WikiMirror/1.0 (https://droo.foo; contact@droo.foo)",
    rate_limit_ms: 1_000

  # --- VintageMachinery Client ---
  config :droodotfoo, Droodotfoo.Wiki.Ingestion.VintageMachineryClient,
    base_url: "https://vintagemachinery.org",
    local_path: System.get_env("VM_MIRROR_PATH", "/var/lib/wiki/vintage-machinery"),
    rate_limit_ms: 2_000,
    include_paths: ["pubs/", "mfgindex/"]

  # --- Wikipedia Client ---
  config :droodotfoo, Droodotfoo.Wiki.Ingestion.WikipediaClient,
    base_url: "https://en.wikipedia.org/api/rest_v1",
    user_agent: "DrooFoo-WikiMirror/1.0 (https://droo.foo; contact@droo.foo)",
    rate_limit_ms: 1_000

  # --- Ollama (embeddings) ---
  config :droodotfoo, Droodotfoo.Wiki.Ollama,
    base_url: System.get_env("OLLAMA_URL", "http://mini-axol.tail9b2ce8.ts.net:11434"),
    model: System.get_env("OLLAMA_MODEL", "nomic-embed-text"),
    timeout: String.to_integer(System.get_env("OLLAMA_TIMEOUT", "60000"))

  # --- Oban ---
  config :droodotfoo, Oban,
    engine: Oban.Engines.Basic,
    repo: Droodotfoo.Repo,
    queues: [ingestion: 2, images: 4, backups: 1, embeddings: 1, notifications: 2],
    plugins: [
      Oban.Plugins.Pruner,
      {Oban.Plugins.Cron,
       crontab: [
         # OSRS Wiki sync every 15 minutes
         {"*/15 * * * *", Droodotfoo.Wiki.Ingestion.OSRSSyncWorker},
         # nLab sync daily at 4am
         {"0 4 * * *", Droodotfoo.Wiki.Ingestion.NLabSyncWorker},
         # VintageMachinery sync weekly on Sunday at 2am
         {"0 2 * * 0", Droodotfoo.Wiki.Ingestion.VintageMachinerySyncWorker},
         # Wikipedia refresh weekly on Saturday at 2am
         {"0 2 * * 6", Droodotfoo.Wiki.Ingestion.WikipediaSyncWorker},
         # Cross-source link detection daily at 5am (after syncs)
         {"0 5 * * *", Droodotfoo.Wiki.CrossLinkWorker},
         # PostgreSQL backup daily at 3am
         {"0 3 * * *", Droodotfoo.Wiki.Backup.PostgresWorker},
         # Embedding refresh nightly at 6am (after all syncs complete)
         {"0 6 * * *", Droodotfoo.Wiki.EmbeddingWorker}
       ]}
    ]

  config :droodotfoo, :wiki_admin_email, System.get_env("WIKI_ADMIN_EMAIL", "droo@droo.foo")

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

  port =
    case Integer.parse(System.get_env("PORT") || "4000") do
      {port, ""} -> port
      _ -> raise "PORT must be a valid integer"
    end

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

  chain_id =
    case Integer.parse(System.get_env("CHAIN_ID") || "1") do
      {id, ""} -> id
      _ -> 1
    end

  config :droodotfoo, Droodotfoo.Web3.Manager,
    default_chain_id: chain_id,
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
