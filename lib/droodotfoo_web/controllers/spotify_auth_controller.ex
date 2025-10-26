defmodule DroodotfooWeb.SpotifyAuthController do
  @moduledoc """
  Handles Spotify OAuth2 authentication callbacks.
  """

  use DroodotfooWeb, :controller
  require Logger

  alias Droodotfoo.Spotify.{Auth, Manager}

  @doc """
  Initiates the Spotify OAuth flow.
  Redirects user to Spotify authorization page.
  """
  def authorize(conn, _params) do
    case Auth.get_authorization_url() do
      {:ok, url} ->
        redirect(conn, external: url)

      {:error, :missing_credentials} ->
        conn
        |> put_flash(:error, "Spotify credentials not configured")
        |> redirect(to: "/")

      {:error, reason} ->
        Logger.error("Failed to start Spotify auth: #{inspect(reason)}")

        conn
        |> put_flash(:error, "Failed to start authentication")
        |> redirect(to: "/")
    end
  end

  @doc """
  Handles the OAuth callback from Spotify.
  Exchanges authorization code for access tokens.
  Validates state parameter to prevent CSRF attacks.
  """
  def callback(conn, %{"code" => code, "state" => state}) do
    case Manager.complete_auth(code, state) do
      :ok ->
        conn
        |> put_flash(:info, "Successfully connected to Spotify!")
        |> put_session(:spotify_authenticated, true)
        |> redirect(to: "/")

      {:error, :invalid_state} ->
        Logger.warning("Spotify auth failed: invalid state (potential CSRF attack)")

        conn
        |> put_flash(:error, "Authentication failed: security validation error")
        |> redirect(to: "/")

      {:error, reason} ->
        Logger.error("Failed to complete Spotify auth: #{inspect(reason)}")

        conn
        |> put_flash(:error, "Authentication failed. Please try again.")
        |> redirect(to: "/")
    end
  end

  def callback(conn, %{"error" => error}) do
    Logger.warning("Spotify auth error: #{error}")

    conn
    |> put_flash(:error, "Authentication cancelled or failed: #{error}")
    |> redirect(to: "/")
  end

  def callback(conn, _params) do
    conn
    |> put_flash(:error, "Invalid authentication callback")
    |> redirect(to: "/")
  end

  @doc """
  Logs out from Spotify (clears tokens).
  """
  def logout(conn, _params) do
    Auth.logout()

    conn
    |> put_flash(:info, "Disconnected from Spotify")
    |> put_session(:spotify_authenticated, false)
    |> redirect(to: "/")
  end
end
