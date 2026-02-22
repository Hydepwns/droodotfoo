defmodule WikiWeb.Plugs.Subdomain do
  @moduledoc """
  Assigns `:subdomain` from the Host header.

  - `wiki.droo.foo` or `wiki.localhost` -> :wiki
  - `lib.droo.foo` or `lib.localhost` -> :library
  """

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    subdomain =
      case conn.host do
        "lib." <> _ -> :library
        "lib.localhost" -> :library
        _ -> :wiki
      end

    assign(conn, :subdomain, subdomain)
  end
end
