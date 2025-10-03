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
      # Start performance monitoring
      Droodotfoo.PerformanceMonitor,
      # Start terminal bridge
      Droodotfoo.TerminalBridge,
      # Start Raxol terminal app
      Droodotfoo.RaxolApp,
      # Start Spotify services
      Droodotfoo.Spotify.Cache,
      Droodotfoo.Spotify.Manager,
      # Start plugin system manager
      Droodotfoo.PluginSystem.Manager,
      # Start a worker by calling: Droodotfoo.Worker.start_link(arg)
      # {Droodotfoo.Worker, arg},
      # Start to serve requests, typically the last entry
      DroodotfooWeb.Endpoint
    ]

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
end
