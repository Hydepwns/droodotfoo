defmodule WikiWeb.OSRS.V1.ItemController do
  @moduledoc """
  OSRS Item API for GEX.

  Endpoints:
  - GET /osrs/api/v1/items - List all items
  - GET /osrs/api/v1/items/:id - Get single item
  """

  use WikiWeb, :controller

  def index(conn, params) do
    # TODO: Implement Wiki.OSRS.list_items/1
    _page = Map.get(params, "page", "1") |> String.to_integer()
    _limit = Map.get(params, "limit", "100") |> String.to_integer()

    json(conn, %{data: [], meta: %{total: 0, page: 1, limit: 100}})
  end

  def show(conn, %{"id" => id}) do
    # TODO: Implement Wiki.OSRS.get_item/1
    case Integer.parse(id) do
      {_item_id, ""} ->
        json(conn, %{error: "Item not found"})

      _ ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid item ID"})
    end
  end
end
