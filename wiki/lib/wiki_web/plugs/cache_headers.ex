defmodule WikiWeb.Plugs.CacheHeaders do
  @moduledoc """
  Sets Cache-Control headers based on subdomain.

  - Wiki (public): 5min browser, 1hr edge (Cloudflare)
  - Library (private): no-store
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(%{assigns: %{subdomain: :library}} = conn, _opts) do
    put_resp_header(conn, "cache-control", "private, no-store")
  end

  def call(conn, _opts) do
    conn
    |> put_resp_header("cache-control", "public, max-age=300, s-maxage=3600")
    |> put_resp_header("cdn-cache-control", "max-age=3600")
  end
end
