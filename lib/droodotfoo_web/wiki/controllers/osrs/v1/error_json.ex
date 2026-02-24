defmodule DroodotfooWeb.Wiki.OSRS.V1.ErrorJSON do
  @moduledoc """
  JSON rendering for API errors.
  """

  def render("404.json", _assigns) do
    %{
      error: %{
        message: "Not found",
        status: 404
      },
      api_version: "v1"
    }
  end

  def render("401.json", _assigns) do
    %{
      error: %{
        message: "Unauthorized",
        status: 401
      },
      api_version: "v1"
    }
  end

  def render("400.json", _assigns) do
    %{
      error: %{
        message: "Bad request",
        status: 400
      },
      api_version: "v1"
    }
  end

  def render("changeset_error.json", %{changeset: changeset}) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)

    %{
      error: %{
        message: "Validation failed",
        status: 422,
        details: errors
      },
      api_version: "v1"
    }
  end
end
