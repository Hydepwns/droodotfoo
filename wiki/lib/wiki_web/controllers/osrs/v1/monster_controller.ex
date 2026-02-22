defmodule WikiWeb.OSRS.V1.MonsterController do
  @moduledoc """
  OSRS Monster API for GEX.

  Endpoints:
  - GET /osrs/api/v1/monsters - List monsters with filtering
  - GET /osrs/api/v1/monsters/:id - Get single monster by ID
  """

  use WikiWeb, :controller

  alias Wiki.OSRS

  action_fallback WikiWeb.FallbackController

  @doc """
  List monsters with optional filtering.

  ## Query Parameters

  - `members` - Filter by members status ("true" or "false")
  - `name` - Filter by name (partial match)
  - `min_combat` - Minimum combat level
  - `max_combat` - Maximum combat level
  - `slayer_level` - Required slayer level
  - `limit` - Max results (default 100, max 500)
  - `offset` - Pagination offset (default 0)

  ## Examples

      GET /osrs/api/v1/monsters
      GET /osrs/api/v1/monsters?members=true&min_combat=100
      GET /osrs/api/v1/monsters?name=dragon&limit=20

  """
  def index(conn, params) do
    opts = parse_monster_params(params)
    monsters = OSRS.list_monsters(opts)
    total = OSRS.count_monsters(opts)

    limit = Keyword.get(opts, :limit, 100)
    offset = Keyword.get(opts, :offset, 0)

    meta = %{
      total: total,
      limit: limit,
      offset: offset,
      has_more: offset + length(monsters) < total
    }

    render(conn, :index, monsters: monsters, meta: meta)
  end

  @doc """
  Get a single monster by ID.

  ## Examples

      GET /osrs/api/v1/monsters/415

  """
  def show(conn, %{"id" => id}) do
    with {:ok, monster_id} <- parse_id(id),
         %OSRS.Monster{} = monster <- OSRS.get_monster(monster_id) do
      render(conn, :show, monster: monster)
    else
      :error ->
        conn
        |> put_status(:bad_request)
        |> render(:error, error: "Invalid monster ID", status: 400)

      nil ->
        conn
        |> put_status(:not_found)
        |> render(:error, error: "Monster not found", status: 404)
    end
  end

  defp parse_monster_params(params) do
    []
    |> maybe_add(:members, params["members"])
    |> maybe_add(:name, params["name"])
    |> maybe_add(:min_combat, parse_int(params["min_combat"]))
    |> maybe_add(:max_combat, parse_int(params["max_combat"]))
    |> maybe_add(:slayer_level, parse_int(params["slayer_level"]))
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
