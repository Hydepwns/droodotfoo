defmodule DroodotfooWeb.Plugs.ContentSecurityPolicy do
  @moduledoc """
  Content Security Policy plug with nonce-based inline script protection.
  Generates a unique nonce per request for secure inline script execution.
  """

  def init(opts), do: opts

  def call(conn, _opts) do
    # Generate cryptographically secure nonce for this request
    nonce = generate_nonce()

    # Build CSP policy with nonce
    csp_policy = build_csp_policy(conn, nonce)

    conn
    |> Plug.Conn.assign(:csp_nonce, nonce)
    |> Plug.Conn.put_resp_header("content-security-policy", csp_policy)
    |> Plug.Conn.put_resp_header("x-content-type-options", "nosniff")
    |> Plug.Conn.put_resp_header("x-frame-options", "SAMEORIGIN")
    |> Plug.Conn.put_resp_header("x-xss-protection", "1; mode=block")
    |> Plug.Conn.put_resp_header("referrer-policy", "strict-origin-when-cross-origin")
    # Prevent caching of dynamic content (LiveView pages, API responses)
    # Static assets are cached via Plug.Static headers in endpoint.ex
    |> Plug.Conn.put_resp_header("cache-control", "no-cache, no-store, must-revalidate")
    |> Plug.Conn.put_resp_header("pragma", "no-cache")
    |> Plug.Conn.put_resp_header("expires", "0")
  end

  defp generate_nonce do
    :crypto.strong_rand_bytes(16)
    |> Base.encode64(padding: false)
  end

  defp build_csp_policy(conn, nonce) do
    # Get the host from the connection
    host = get_host(conn)

    # Build CSP policy with nonce-based inline script protection
    # Note:
    # - 'nonce-{nonce}' allows inline scripts with matching nonce attribute
    # - 'unsafe-eval' kept for WebAssembly (TODO: remove if not needed)
    # - 'unsafe-inline' kept for styles only (consider using nonces here too)
    # - Removed chrome-extension/moz-extension (overly permissive)
    [
      "default-src 'self'",
      "script-src 'self' 'nonce-#{nonce}' 'unsafe-eval' #{host}",
      "style-src 'self' 'unsafe-inline' #{host}",
      "font-src 'self' #{host}/fonts data:",
      "img-src 'self' data: blob: #{host}",
      "connect-src 'self' ws: wss: #{host}",
      "frame-src 'self' #{host} https://www.youtube.com https://www.youtube-nocookie.com https://open.spotify.com",
      "worker-src 'self' blob:",
      "object-src 'self'",
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
