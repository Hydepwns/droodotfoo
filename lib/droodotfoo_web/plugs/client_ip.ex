defmodule DroodotfooWeb.Plugs.ClientIP do
  @moduledoc """
  Shared utilities for extracting client IP addresses.

  Provides functions for both Plug.Conn (controllers) and Phoenix.Socket (LiveViews).
  Handles proxy headers (Fly-Client-IP, X-Forwarded-For) securely.
  """

  import Plug.Conn, only: [get_req_header: 2]

  @doc """
  Extracts client IP from a Plug.Conn (for controllers).

  Priority:
  1. Fly-Client-IP header (set by Fly.io, can't be spoofed)
  2. X-Forwarded-For (rightmost IP, most trusted in chain)
  3. conn.remote_ip (direct connection)
  """
  @spec from_conn(Plug.Conn.t()) :: String.t()
  def from_conn(conn) do
    case get_req_header(conn, "fly-client-ip") do
      [ip | _] ->
        String.trim(ip)

      [] ->
        case get_req_header(conn, "x-forwarded-for") do
          [ips] ->
            ips
            |> String.split(",")
            |> List.last()
            |> String.trim()

          [] ->
            conn.remote_ip |> :inet.ntoa() |> to_string()
        end
    end
  end

  @doc """
  Extracts client IP from a Phoenix.LiveView.Socket (for LiveViews).

  Uses peer_data from connect_info. Falls back to localhost for development.

  Note: For production with proxies, consider adding x_headers to connect_info
  in endpoint.ex to access Fly-Client-IP in LiveViews.
  """
  @spec from_socket(Phoenix.LiveView.Socket.t()) :: String.t()
  def from_socket(socket) do
    case socket.private[:connect_info] do
      %{peer_data: %{address: address}} ->
        format_ip(address)

      _ ->
        # Fallback for development or missing connect_info
        "127.0.0.1"
    end
  end

  defp format_ip({a, b, c, d}), do: "#{a}.#{b}.#{c}.#{d}"
  defp format_ip({a, b, c, d, e, f, g, h}), do: "#{a}:#{b}:#{c}:#{d}:#{e}:#{f}:#{g}:#{h}"
  defp format_ip(_), do: "127.0.0.1"
end
