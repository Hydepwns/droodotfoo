defmodule Droodotfoo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Set up OpenTelemetry instrumentation
    setup_opentelemetry()

    # Initialize MediaWiki rate limiter ETS table
    Droodotfoo.Wiki.Ingestion.MediaWikiClient.init()

    # Add Sentry logger handler for capturing crashed process exceptions
    :logger.add_handler(:sentry_handler, Sentry.LoggerHandler, %{
      config: %{metadata: [:file, :line]}
    })

    children =
      [
        DroodotfooWeb.Telemetry,
        # Database
        Droodotfoo.Repo,
        # Background jobs
        {Oban, Application.fetch_env!(:droodotfoo, Oban)},
        # Wiki cache
        {Cachex, Application.get_env(:droodotfoo, :wiki_cache)},
        {DNSCluster, query: Application.get_env(:droodotfoo, :dns_cluster_query) || :ignore},
        {Phoenix.PubSub, name: Droodotfoo.PubSub},
        # Circuit breaker for external API resilience
        Droodotfoo.CircuitBreaker,
        # Start performance monitoring
        Droodotfoo.PerformanceMonitor,
        # Start performance cache and metrics
        Droodotfoo.Performance.Cache,
        Droodotfoo.Performance.Metrics,
        # Start resume preset manager
        Droodotfoo.Resume.PresetManager,
        # Terminal services archived - see .archived_terminal/README.md
        # Droodotfoo.TerminalBridge,
        # Droodotfoo.RaxolApp,
        # Start Spotify services
        Droodotfoo.Spotify,
        # Start GitHub services
        Droodotfoo.GitHub.Fetcher,
        # Start Web3 server
        Droodotfoo.Web3,
        # Start plugin system
        Droodotfoo.PluginSystem,
        # Start blog post system
        Droodotfoo.Content.Posts,
        # Start Portal presence server
        Droodotfoo.Fileverse.Portal.PresenceServer,
        # Start contact form rate limiter
        Droodotfoo.Contact.RateLimiter,
        # Start post API rate limiter
        Droodotfoo.Content.PostRateLimiter,
        # Start pattern endpoint rate limiter
        Droodotfoo.Content.PatternRateLimiter,
        # Start wiki search rate limiter
        Droodotfoo.Wiki.Search.RateLimiter,
        # Start a worker by calling: Droodotfoo.Worker.start_link(arg)
        # {Droodotfoo.Worker, arg},
        # Start to serve requests, typically the last entry
        DroodotfooWeb.Endpoint
      ] ++
        dev_only_children() ++
        chromic_pdf_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Droodotfoo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DroodotfooWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  # Development-only children (compile-time check to avoid Mix.env() at runtime)
  if Mix.env() == :dev do
    defp dev_only_children, do: [Droodotfoo.Dev.FileWatcher]
  else
    defp dev_only_children, do: []
  end

  # ChromicPDF children - only start in dev/test (Chrome doesn't work reliably in Fly.io)
  if Mix.env() in [:dev, :test] do
    defp chromic_pdf_children do
      chrome_path =
        [
          "/usr/bin/chromium",
          "/usr/bin/chromium-browser",
          "/usr/bin/google-chrome",
          "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
          "/Applications/Chromium.app/Contents/MacOS/Chromium"
        ]
        |> Enum.find(&File.exists?/1)

      base_opts = [
        discard_utility_output: true,
        no_sandbox: true,
        session_pool: [timeout: 15_000, init_timeout: 15_000]
      ]

      opts =
        if chrome_path,
          do: Keyword.put(base_opts, :chrome_executable, chrome_path),
          else: base_opts

      [{ChromicPDF, opts}]
    end
  else
    defp chromic_pdf_children, do: []
  end

  # Set up OpenTelemetry instrumentation for Phoenix and Bandit
  defp setup_opentelemetry do
    # Attach Phoenix telemetry handlers for request tracing
    :ok = OpentelemetryPhoenix.setup(adapter: :bandit)

    # Attach Bandit telemetry handlers for HTTP server tracing
    :ok = OpentelemetryBandit.setup()

    :ok
  end
end
