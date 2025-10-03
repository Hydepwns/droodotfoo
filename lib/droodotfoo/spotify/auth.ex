defmodule Droodotfoo.Spotify.Auth do
  @moduledoc """
  OAuth authentication module for Spotify integration.
  Handles the OAuth 2.0 authorization code flow.
  """

  require Logger
  alias OAuth2.{Client, Strategy}

  @spotify_base_url "https://accounts.spotify.com"

  # Required scopes for the application
  @scopes [
    "user-read-currently-playing",
    "user-read-playback-state",
    "user-modify-playback-state",
    "user-read-private",
    "playlist-read-private",
    "playlist-read-collaborative"
  ]

  @doc """
  Gets the Spotify OAuth configuration from application config.
  """
  def get_config do
    %{
      client_id: Application.get_env(:droodotfoo, :spotify_client_id, ""),
      client_secret: Application.get_env(:droodotfoo, :spotify_client_secret, ""),
      redirect_uri:
        Application.get_env(
          :droodotfoo,
          :spotify_redirect_uri,
          "http://localhost:4000/auth/spotify/callback"
        )
    }
  end

  @doc """
  Creates an OAuth2 client for Spotify.
  """
  def client do
    config = get_config()

    Client.new(
      strategy: Strategy.AuthCode,
      client_id: config.client_id,
      client_secret: config.client_secret,
      site: @spotify_base_url,
      authorize_url: "/authorize",
      token_url: "/api/token",
      redirect_uri: config.redirect_uri
    )
  end

  @doc """
  Generates the authorization URL for the OAuth flow.
  Returns {:ok, url} or {:error, reason}.
  """
  def get_authorization_url do
    config = get_config()

    if config.client_id == "" or config.client_secret == "" do
      {:error, :missing_credentials}
    else
      scope = Enum.join(@scopes, " ")
      state = generate_state()

      params = [
        scope: scope,
        state: state,
        show_dialog: "false"
      ]

      url =
        client()
        |> Client.authorize_url!(params)

      # Store state for verification (in a real app, this should be in a secure store)
      :ets.new(:spotify_auth_state, [:named_table, :public])
      :ets.insert(:spotify_auth_state, {:state, state})

      {:ok, url}
    end
  rescue
    error ->
      Logger.error("Error generating authorization URL: #{inspect(error)}")
      {:error, :auth_url_generation_failed}
  end

  @doc """
  Exchanges the authorization code for access and refresh tokens.
  Returns {:ok, tokens} or {:error, reason}.
  """
  def exchange_code_for_tokens(code, state \\ nil) do
    # Verify state if provided (optional for this implementation)
    if state && !verify_state(state) do
      {:error, :invalid_state}
    else
      try do
        client = client()
        client = Client.get_token!(client, code: code)

        token_data = %{
          access_token: client.token.access_token,
          refresh_token: client.token.refresh_token,
          expires_at: calculate_expiry(client.token.expires_at),
          token_type: client.token.token_type || "Bearer"
        }

        # Store tokens (in a real app, encrypt and store securely)
        store_tokens(token_data)

        {:ok, token_data}
      rescue
        error ->
          Logger.error("Error exchanging code for tokens: #{inspect(error)}")
          {:error, :token_exchange_failed}
      end
    end
  end

  @doc """
  Gets the current stored access token.
  Automatically refreshes if expired.
  """
  def get_access_token do
    case get_stored_tokens() do
      nil ->
        {:error, :no_tokens}

      tokens ->
        if token_expired?(tokens) do
          refresh_access_token(tokens.refresh_token)
        else
          {:ok, tokens.access_token}
        end
    end
  end

  @doc """
  Refreshes the access token using the refresh token.
  """
  def refresh_access_token(refresh_token) do
    try do
      client = client()

      client =
        Client.get_token!(client, refresh_token: refresh_token, grant_type: "refresh_token")

      token_data = %{
        access_token: client.token.access_token,
        refresh_token: client.token.refresh_token || refresh_token,
        expires_at: calculate_expiry(client.token.expires_at),
        token_type: client.token.token_type || "Bearer"
      }

      store_tokens(token_data)

      {:ok, token_data.access_token}
    rescue
      error ->
        Logger.error("Error refreshing token: #{inspect(error)}")
        {:error, :token_refresh_failed}
    end
  end

  @doc """
  Clears stored authentication tokens.
  """
  def logout do
    clear_stored_tokens()
    :ok
  end

  @doc """
  Checks if the user is currently authenticated.
  """
  def authenticated? do
    case get_stored_tokens() do
      nil -> false
      tokens -> !token_expired?(tokens)
    end
  end

  # Private Functions

  defp generate_state do
    16
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp verify_state(state) do
    case :ets.lookup(:spotify_auth_state, :state) do
      [{:state, stored_state}] -> state == stored_state
      [] -> false
    end
  end

  defp calculate_expiry(expires_at) when is_integer(expires_at) do
    DateTime.from_unix!(expires_at)
  end

  defp calculate_expiry(_), do: DateTime.add(DateTime.utc_now(), 3600, :second)

  defp token_expired?(%{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) == :gt
  end

  defp store_tokens(tokens) do
    # In a real application, encrypt these and store in a database
    # For now, store in ETS for development
    :ets.new(:spotify_tokens, [:named_table, :public])
    :ets.insert(:spotify_tokens, {:tokens, tokens})
  end

  defp get_stored_tokens do
    case :ets.lookup(:spotify_tokens, :tokens) do
      [{:tokens, tokens}] -> tokens
      [] -> nil
    end
  rescue
    _ -> nil
  end

  defp clear_stored_tokens do
    try do
      :ets.delete(:spotify_tokens, :tokens)
    rescue
      _ -> :ok
    end
  end
end
