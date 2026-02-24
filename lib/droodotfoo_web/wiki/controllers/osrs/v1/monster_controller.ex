defmodule DroodotfooWeb.Wiki.OSRS.V1.MonsterController do
  @moduledoc """
  OSRS Monster API for GEX.

  Endpoints:
  - GET /osrs/api/v1/monsters - List monsters with filtering
  - GET /osrs/api/v1/monsters/:id - Get single monster by ID
  """

  use DroodotfooWeb.Wiki, :controller

  alias Droodotfoo.Wiki.OSRS
  alias DroodotfooWeb.Wiki.OSRS.V1.Params

  action_fallback DroodotfooWeb.Wiki.OSRS.V1.FallbackController

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
    meta = Params.build_meta(opts, length(monsters), total)

    render(conn, :index, monsters: monsters, meta: meta)
  end

  @doc """
  Get a single monster by ID.

  ## Examples

      GET /osrs/api/v1/monsters/415

  """
  def show(conn, %{"id" => id}) do
    with {:ok, monster_id} <- Params.parse_id(id),
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
    |> Params.maybe_add(:members, params["members"])
    |> Params.maybe_add(:name, params["name"])
    |> Params.maybe_add(:min_combat, Params.parse_int(params["min_combat"]))
    |> Params.maybe_add(:max_combat, Params.parse_int(params["max_combat"]))
    |> Params.maybe_add(:slayer_level, Params.parse_int(params["slayer_level"]))
    |> Params.maybe_add(:limit, Params.parse_int(params["limit"]))
    |> Params.maybe_add(:offset, Params.parse_int(params["offset"]))
  end
end
