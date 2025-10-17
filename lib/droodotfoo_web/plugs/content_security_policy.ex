defmodule DroodotfooWeb.Plugs.ContentSecurityPolicy do
  @moduledoc """
  Custom Content Security Policy plug that allows necessary resources for the terminal interface.
  """

  # import Plug.Conn  # Not needed since we use Plug.Conn.put_resp_header directly

  def init(opts), do: opts

  def call(conn, _opts) do
    # Define a permissive CSP policy for development
    # In production, this should be more restrictive
    csp_policy = build_csp_policy(conn)

    conn
    |> Plug.Conn.put_resp_header("content-security-policy", csp_policy)
    |> Plug.Conn.put_resp_header("x-content-type-options", "nosniff")
    |> Plug.Conn.put_resp_header("x-frame-options", "SAMEORIGIN")
    |> Plug.Conn.put_resp_header("x-xss-protection", "1; mode=block")
  end

  defp build_csp_policy(conn) do
    # Get the host from the connection
    host = get_host(conn)

    # Build CSP policy that allows necessary resources
    # Note: 'unsafe-eval' is needed for WebAssembly and some libraries
    [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval' #{host} chrome-extension: moz-extension:",
      "style-src 'self' 'unsafe-inline' #{host}",
      "font-src 'self' #{host}/fonts data:",
      "img-src 'self' data: blob: #{host}",
      "connect-src 'self' ws: wss: #{host} chrome-extension: moz-extension:",
      "frame-src 'self' #{host} chrome-extension: moz-extension:",
      "worker-src 'self' blob:",
      "object-src 'none'",
      "base-uri 'self'",
      "form-action 'self'",
      "frame-ancestors 'self'"
    ]
    |> Enum.join("; ")
  end

  defp get_host(conn) do
    case conn.host do
      "localhost" -> "http://localhost:4000"
      host -> "https://#{host}"
    end
  end
end
