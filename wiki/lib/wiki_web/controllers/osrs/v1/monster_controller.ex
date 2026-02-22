defmodule WikiWeb.OSRS.V1.MonsterController do
  @moduledoc """
  OSRS Monster API for GEX.
  """

  use WikiWeb, :controller

  def index(conn, params) do
    _page = Map.get(params, "page", "1") |> String.to_integer()
    _limit = Map.get(params, "limit", "100") |> String.to_integer()

    json(conn, %{data: [], meta: %{total: 0, page: 1, limit: 100}})
  end

  def show(conn, %{"id" => id}) do
    case Integer.parse(id) do
      {_monster_id, ""} ->
        json(conn, %{error: "Monster not found"})

      _ ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid monster ID"})
    end
  end
end
