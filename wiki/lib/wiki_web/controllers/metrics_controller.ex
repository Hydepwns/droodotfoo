defmodule WikiWeb.MetricsController do
  @moduledoc """
  Prometheus metrics endpoint for PromEx.
  """

  use WikiWeb, :controller

  def index(conn, _params) do
    metrics = Wiki.PromEx.get_metrics()

    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, metrics)
  end
end
