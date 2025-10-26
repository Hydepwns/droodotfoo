defmodule Droodotfoo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DroodotfooWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:droodotfoo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Droodotfoo.PubSub},
      # Start ChromicPDF
      {ChromicPDF, chromic_pdf_opts()},
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
      Droodotfoo.Spotify.Cache,
      Droodotfoo.Spotify,
      # Start GitHub services
      Droodotfoo.GitHub.Cache,
      Droodotfoo.GitHub.Fetcher,
      # Start Web3 server
      Droodotfoo.Web3,
      # Start plugin system
      Droodotfoo.PluginSystem,
      # Start blog post system
      Droodotfoo.Content.Posts,
      # Start pattern cache for SVG pattern generation
      Droodotfoo.Content.PatternCache,
      # Start Portal presence server
      Droodotfoo.Fileverse.Portal.PresenceServer,
      # Start contact form rate limiter
      Droodotfoo.Contact.RateLimiter,
      # Start post API rate limiter
      Droodotfoo.Content.PostRateLimiter,
      # Start pattern endpoint rate limiter
      Droodotfoo.Content.PatternRateLimiter,
      # Start a worker by calling: Droodotfoo.Worker.start_link(arg)
      # {Droodotfoo.Worker, arg},
      # Start to serve requests, typically the last entry
      DroodotfooWeb.Endpoint
    ]

    # Add dev-only services
    children = if Mix.env() == :dev, do: children ++ [Droodotfoo.Dev.FileWatcher], else: children

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

  defp chromic_pdf_opts do
    # Try to find Chrome/Chromium in common locations
    chrome_path =
      [
        "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
        "/Applications/Chromium.app/Contents/MacOS/Chromium",
        "/usr/bin/chromium",
        "/usr/bin/chromium-browser",
        "/usr/bin/google-chrome"
      ]
      |> Enum.find(&File.exists?/1)

    if chrome_path do
      [
        chrome_executable: chrome_path,
        discard_utility_output: true
      ]
    else
      # Let ChromicPDF try to find Chrome automatically
      [discard_utility_output: true]
    end
  end
end
