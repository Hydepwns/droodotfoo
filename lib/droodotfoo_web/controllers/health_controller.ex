defmodule DroodotfooWeb.HealthController do
  @moduledoc """
  Health check endpoints for load balancers and monitoring.

  - `/health` - Basic liveness check (is the app running?)
  - `/health/ready` - Readiness check (are dependencies available?)
  """

  use DroodotfooWeb, :controller

  @doc """
  Liveness probe - returns 200 if the application is running.
  Used by load balancers to check if the instance should receive traffic.
  """
  def index(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{status: "ok", timestamp: DateTime.utc_now()}))
  end

  @doc """
  Readiness probe - returns 200 if the application and its dependencies are ready.
  Checks ETS tables and critical GenServers are running.
  """
  def ready(conn, _params) do
    checks = %{
      posts_cache: check_genserver(Droodotfoo.Content.Posts),
      pattern_cache: check_genserver(Droodotfoo.Content.PatternCache),
      spotify: check_genserver(Droodotfoo.Spotify),
      github_cache: check_genserver(Droodotfoo.GitHub.Cache),
      pubsub: check_pubsub()
    }

    all_healthy = Enum.all?(checks, fn {_k, v} -> v == :ok end)

    status = if all_healthy, do: "ok", else: "degraded"
    http_status = if all_healthy, do: 200, else: 503

    response = %{
      status: status,
      timestamp: DateTime.utc_now(),
      checks: Map.new(checks, fn {k, v} -> {k, to_string(v)} end)
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(http_status, Jason.encode!(response))
  end

  defp check_genserver(name) do
    case Process.whereis(name) do
      nil -> :down
      pid when is_pid(pid) -> if Process.alive?(pid), do: :ok, else: :down
    end
  end

  defp check_pubsub do
    case Process.whereis(Droodotfoo.PubSub) do
      nil -> :down
      _pid -> :ok
    end
  end
end
