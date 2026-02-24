defmodule DroodotfooWeb.Wiki.OSRS.V1.ItemController do
  @moduledoc """
  OSRS Item API for GEX.

  Endpoints:
  - GET /osrs/api/v1/items - List items with filtering
  - GET /osrs/api/v1/items/:id - Get single item by ID
  """

  use DroodotfooWeb.Wiki, :controller

  alias Droodotfoo.Wiki.OSRS
  alias DroodotfooWeb.Wiki.OSRS.V1.Params

  action_fallback DroodotfooWeb.Wiki.OSRS.V1.FallbackController

  @doc """
  List items with optional filtering.

  ## Query Parameters

  - `members` - Filter by members status ("true" or "false")
  - `tradeable` - Filter by tradeable status ("true" or "false")
  - `equipable` - Filter by equipable status ("true" or "false")
  - `name` - Filter by name (partial match)
  - `limit` - Max results (default 100, max 500)
  - `offset` - Pagination offset (default 0)

  ## Examples

      GET /osrs/api/v1/items
      GET /osrs/api/v1/items?members=true&tradeable=true
      GET /osrs/api/v1/items?name=whip&limit=10

  """
  def index(conn, params) do
    opts = parse_item_params(params)
    items = OSRS.list_items(opts)
    total = OSRS.count_items(opts)
    meta = Params.build_meta(opts, length(items), total)

    render(conn, :index, items: items, meta: meta)
  end

  @doc """
  Get a single item by ID.

  ## Examples

      GET /osrs/api/v1/items/4151

  """
  def show(conn, %{"id" => id}) do
    with {:ok, item_id} <- Params.parse_id(id),
         %OSRS.Item{} = item <- OSRS.get_item(item_id) do
      render(conn, :show, item: item)
    else
      :error ->
        conn
        |> put_status(:bad_request)
        |> render(:error, error: "Invalid item ID", status: 400)

      nil ->
        conn
        |> put_status(:not_found)
        |> render(:error, error: "Item not found", status: 404)
    end
  end

  defp parse_item_params(params) do
    []
    |> Params.maybe_add(:members, params["members"])
    |> Params.maybe_add(:tradeable, params["tradeable"])
    |> Params.maybe_add(:equipable, params["equipable"])
    |> Params.maybe_add(:stackable, params["stackable"])
    |> Params.maybe_add(:name, params["name"])
    |> Params.maybe_add(:limit, Params.parse_int(params["limit"]))
    |> Params.maybe_add(:offset, Params.parse_int(params["offset"]))
  end
end
