defmodule WikiWeb.HealthController do
  @moduledoc """
  Health check endpoint for Docker/Kubernetes.
  """

  use WikiWeb, :controller

  def index(conn, _params) do
    json(conn, %{status: "healthy", timestamp: DateTime.utc_now()})
  end
end
