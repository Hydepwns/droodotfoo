defmodule WikiWeb.OSRS.V1.ItemController do
  @moduledoc """
  OSRS Item API for GEX.

  Endpoints:
  - GET /osrs/api/v1/items - List items with filtering
  - GET /osrs/api/v1/items/:id - Get single item by ID
  """

  use WikiWeb, :controller

  alias Wiki.OSRS

  action_fallback WikiWeb.FallbackController

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

    limit = Keyword.get(opts, :limit, 100)
    offset = Keyword.get(opts, :offset, 0)

    meta = %{
      total: total,
      limit: limit,
      offset: offset,
      has_more: offset + length(items) < total
    }

    render(conn, :index, items: items, meta: meta)
  end

  @doc """
  Get a single item by ID.

  ## Examples

      GET /osrs/api/v1/items/4151

  """
  def show(conn, %{"id" => id}) do
    with {:ok, item_id} <- parse_id(id),
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
    |> maybe_add(:members, params["members"])
    |> maybe_add(:tradeable, params["tradeable"])
    |> maybe_add(:equipable, params["equipable"])
    |> maybe_add(:stackable, params["stackable"])
    |> maybe_add(:name, params["name"])
    |> maybe_add(:limit, parse_int(params["limit"]))
    |> maybe_add(:offset, parse_int(params["offset"]))
  end

  defp maybe_add(opts, _key, nil), do: opts
  defp maybe_add(opts, key, "true"), do: Keyword.put(opts, key, true)
  defp maybe_add(opts, key, "false"), do: Keyword.put(opts, key, false)
  defp maybe_add(opts, key, value) when is_binary(value), do: Keyword.put(opts, key, value)
  defp maybe_add(opts, key, value) when is_integer(value), do: Keyword.put(opts, key, value)
  defp maybe_add(opts, _key, _value), do: opts

  defp parse_int(nil), do: nil

  defp parse_int(str) when is_binary(str) do
    case Integer.parse(str) do
      {n, ""} -> n
      _ -> nil
    end
  end

  defp parse_id(str) when is_binary(str) do
    case Integer.parse(str) do
      {n, ""} when n > 0 -> {:ok, n}
      _ -> :error
    end
  end
end
