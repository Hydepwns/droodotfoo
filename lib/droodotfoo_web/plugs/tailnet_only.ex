defmodule DroodotfooWeb.Plugs.TailnetOnly do
  @moduledoc """
  Restricts access to Tailscale network only.

  Admin routes return 404 when accessed via Cloudflare tunnel.
  Tailscale IPs are in the 100.x.x.x range.
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if tailnet_request?(conn) do
      conn
    else
      conn
      |> put_status(:not_found)
      |> Phoenix.Controller.put_view(DroodotfooWeb.ErrorHTML)
      |> Phoenix.Controller.render("404.html")
      |> halt()
    end
  end

  defp tailnet_request?(conn) do
    case get_peer_ip(conn) do
      {100, _, _, _} -> true
      # Allow localhost in development
      {127, 0, 0, 1} -> true
      _ -> false
    end
  end

  defp get_peer_ip(conn) do
    # Check X-Forwarded-For header first (behind reverse proxy)
    case get_req_header(conn, "x-forwarded-for") do
      [forwarded | _] ->
        forwarded
        |> String.split(",")
        |> List.first()
        |> String.trim()
        |> parse_ip()

      [] ->
        conn.remote_ip
    end
  end

  defp parse_ip(ip_string) do
    case :inet.parse_address(String.to_charlist(ip_string)) do
      {:ok, ip} -> ip
      _ -> {0, 0, 0, 0}
    end
  end
end
