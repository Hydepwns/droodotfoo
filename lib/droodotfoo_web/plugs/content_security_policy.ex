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
    |> Plug.Conn.put_resp_header("permissions-policy", permissions_policy())
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
    #
    # Security notes:
    # - 'nonce-{nonce}' allows inline scripts with matching nonce attribute
    # - 'unsafe-inline' intentionally kept for styles because:
    #   1. Phoenix LiveView injects inline styles for DOM patching
    #   2. HEEx templates use inline style attributes for dynamic styling
    #   3. Nonce-based styles would require modifying every style="" attribute
    #   Style injection XSS is lower risk than script injection
    # - Removed chrome-extension/moz-extension (overly permissive)
    # - 'unsafe-eval' removed after security audit (no WASM/eval usage found)
    [
      "default-src 'self'",
      "script-src 'self' 'nonce-#{nonce}' #{host}",
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

  defp permissions_policy do
    # Restrict browser features to minimize attack surface
    # - Disabled: geolocation, camera, microphone, payment, usb, etc.
    # - Allowed: fullscreen (YouTube/Spotify embeds), picture-in-picture
    [
      "accelerometer=()",
      "ambient-light-sensor=()",
      "autoplay=(self)",
      "battery=()",
      "camera=()",
      "display-capture=()",
      "document-domain=()",
      "encrypted-media=(self)",
      "fullscreen=(self)",
      "geolocation=()",
      "gyroscope=()",
      "magnetometer=()",
      "microphone=()",
      "midi=()",
      "payment=()",
      "picture-in-picture=(self)",
      "publickey-credentials-get=()",
      "screen-wake-lock=()",
      "usb=()",
      "xr-spatial-tracking=()"
    ]
    |> Enum.join(", ")
  end
end
