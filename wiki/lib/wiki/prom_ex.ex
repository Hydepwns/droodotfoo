defmodule Wiki.PromEx do
  @moduledoc """
  PromEx configuration for Prometheus metrics.

  Scrape target: :4040/metrics
  Dashboards auto-uploaded to Grafana if configured.
  """

  use PromEx, otp_app: :wiki

  @doc "Get metrics in Prometheus format."
  def get_metrics do
    PromEx.get_metrics(__MODULE__)
  end

  @impl true
  def plugins do
    [
      PromEx.Plugins.Beam,
      {PromEx.Plugins.Phoenix, router: WikiWeb.Router, endpoint: WikiWeb.Endpoint},
      {PromEx.Plugins.Ecto, repos: [Wiki.Repo]},
      {PromEx.Plugins.Oban, oban_supervisors: [Oban]},
      {PromEx.Plugins.Application, otp_app: :wiki}
    ]
  end

  @impl true
  def dashboard_assigns do
    [
      datasource_id: "prometheus",
      default_selected_interval: "30s"
    ]
  end

  @impl true
  def dashboards do
    [
      {:prom_ex, "phoenix.json"},
      {:prom_ex, "ecto.json"},
      {:prom_ex, "oban.json"},
      {:prom_ex, "beam.json"}
    ]
  end
end
