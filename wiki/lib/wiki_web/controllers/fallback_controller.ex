defmodule WikiWeb.FallbackController do
  @moduledoc """
  Fallback controller for handling errors in API controllers.

  This controller is invoked when an action returns an error tuple
  that the primary controller doesn't handle.
  """

  use WikiWeb, :controller

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(json: WikiWeb.ErrorJSON)
    |> render(:"404")
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(json: WikiWeb.ErrorJSON)
    |> render(:"401")
  end

  def call(conn, {:error, :bad_request}) do
    conn
    |> put_status(:bad_request)
    |> put_view(json: WikiWeb.ErrorJSON)
    |> render(:"400")
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: WikiWeb.ErrorJSON)
    |> render(:changeset_error, changeset: changeset)
  end
end
