defmodule DroodotfooWeb.HealthController do
  @moduledoc """
  Health check endpoints for load balancers and monitoring.

  - `/health` - Basic liveness check (is the app running?)
  - `/health/ready` - Readiness check (are dependencies available?)
  """

  use DroodotfooWeb, :controller

  alias Droodotfoo.CircuitBreaker

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
  Checks ETS tables, critical GenServers, circuit breakers, and cache stats.
  """
  def ready(conn, _params) do
    services = %{
      posts_cache: check_genserver(Droodotfoo.Content.Posts),
      performance_cache: check_genserver(Droodotfoo.Performance.Cache),
      spotify: check_genserver(Droodotfoo.Spotify),
      pubsub: check_pubsub()
    }

    circuits = get_circuit_status()
    caches = get_cache_stats()

    # Services must be up, but open circuits only degrade (don't fail) the check
    services_healthy = Enum.all?(services, fn {_k, v} -> v == :ok end)
    circuits_healthy = Enum.all?(circuits, fn {_k, v} -> v.state == :closed end)

    status =
      cond do
        not services_healthy -> "unhealthy"
        not circuits_healthy -> "degraded"
        true -> "ok"
      end

    http_status = if services_healthy, do: 200, else: 503

    response = %{
      status: status,
      timestamp: DateTime.utc_now(),
      services: Map.new(services, fn {k, v} -> {k, to_string(v)} end),
      circuits: circuits,
      caches: caches
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

  defp get_circuit_status do
    case Process.whereis(CircuitBreaker) do
      nil ->
        %{}

      _pid ->
        CircuitBreaker.status()
        |> Map.new(fn {name, info} ->
          {name, %{state: info.state, failures: info.failure_count}}
        end)
    end
  end

  defp get_cache_stats do
    %{
      posts: get_ets_stats(:blog_posts_cache),
      unified_cache: get_ets_stats(:droodotfoo_cache),
      rate_limits: get_ets_stats(:global_rate_limiter)
    }
    |> Enum.reject(fn {_k, v} -> v == nil end)
    |> Map.new()
  end

  defp get_ets_stats(table_name) do
    case :ets.whereis(table_name) do
      :undefined ->
        nil

      _ref ->
        info = :ets.info(table_name)

        %{
          entries: Keyword.get(info, :size, 0),
          memory_bytes: Keyword.get(info, :memory, 0) * :erlang.system_info(:wordsize)
        }
    end
  end
end
