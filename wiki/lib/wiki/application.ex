defmodule Wiki.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Data layer
      Wiki.Repo,
      {Phoenix.PubSub, name: Wiki.PubSub},

      # Background jobs
      {Oban, Application.fetch_env!(:wiki, Oban)},

      # Caching
      {Cachex, Application.fetch_env!(:wiki, :cachex)},

      # Observability
      WikiWeb.Telemetry,
      Wiki.PromEx,

      # Clustering
      {DNSCluster, query: Application.get_env(:wiki, :dns_cluster_query) || :ignore},

      # HTTP server (last)
      WikiWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Wiki.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    WikiWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
