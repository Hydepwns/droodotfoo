defmodule Droodotfoo.Spotify.AuthTest do
  use ExUnit.Case, async: false

  alias Droodotfoo.Spotify.Auth

  # Helper to store encrypted tokens the same way Auth module does
  defp store_test_tokens(tokens) do
    secret = Application.get_env(:droodotfoo, DroodotfooWeb.Endpoint)[:secret_key_base]
    encrypted = Plug.Crypto.encrypt(secret, "spotify_tokens", tokens)

    if :ets.whereis(:spotify_tokens) == :undefined do
      :ets.new(:spotify_tokens, [:named_table, :public])
    end

    :ets.insert(:spotify_tokens, {:tokens, encrypted})
  end

  setup do
    # Clear entries from ETS tables (tables may be owned by another process)
    try do
      if :ets.whereis(:spotify_auth_state) != :undefined do
        :ets.delete_all_objects(:spotify_auth_state)
      end
    rescue
      _ -> :ok
    end

    try do
      if :ets.whereis(:spotify_tokens) != :undefined do
        :ets.delete_all_objects(:spotify_tokens)
      end
    rescue
      _ -> :ok
    end

    :ok
  end

  describe "get_config/0" do
    test "returns configuration from application env" do
      config = Auth.get_config()

      assert Map.has_key?(config, :client_id)
      assert Map.has_key?(config, :client_secret)
      assert Map.has_key?(config, :redirect_uri)
      assert is_binary(config.redirect_uri)
    end

    test "uses default redirect URI when not configured" do
      config = Auth.get_config()

      assert config.redirect_uri =~ "localhost:4000"
      assert config.redirect_uri =~ "/auth/spotify/callback"
    end
  end

  describe "client/0" do
    test "creates OAuth2 client with correct configuration" do
      client = Auth.client()

      assert client.strategy == OAuth2.Strategy.AuthCode
      assert client.site == "https://accounts.spotify.com"
      assert client.authorize_url == "/authorize"
      assert client.token_url == "/api/token"
    end
  end

  describe "get_authorization_url/0" do
    test "returns error when credentials are missing" do
      # Temporarily set empty credentials
      Application.put_env(:droodotfoo, :spotify_client_id, "")
      Application.put_env(:droodotfoo, :spotify_client_secret, "")

      assert {:error, :missing_credentials} = Auth.get_authorization_url()
    end

    test "generates authorization URL with correct parameters" do
      # Set test credentials
      Application.put_env(:droodotfoo, :spotify_client_id, "test_client_id")
      Application.put_env(:droodotfoo, :spotify_client_secret, "test_client_secret")

      assert {:ok, url} = Auth.get_authorization_url()

      assert is_binary(url)
      assert url =~ "https://accounts.spotify.com/authorize"
      assert url =~ "client_id=test_client_id"
      assert url =~ "response_type=code"
      assert url =~ "scope="
      assert url =~ "state="
    end

    test "stores state in ETS for verification with expiry" do
      Application.put_env(:droodotfoo, :spotify_client_id, "test_client_id")
      Application.put_env(:droodotfoo, :spotify_client_secret, "test_client_secret")

      {:ok, url} = Auth.get_authorization_url()

      # Extract state from URL
      uri = URI.parse(url)
      params = URI.decode_query(uri.query || "")
      state = params["state"]

      assert state != nil
      # State now includes expiry timestamp (5 minutes from creation)
      assert [{:state, ^state, expires_at}] = :ets.lookup(:spotify_auth_state, :state)
      # Verify expiry is in the future (within 5 minutes + some buffer)
      now = System.system_time(:second)
      assert expires_at > now
      assert expires_at <= now + 310
    end
  end

  describe "authenticated?/0" do
    test "returns false when no tokens are stored" do
      refute Auth.authenticated?()
    end

    test "returns false when tokens are expired" do
      expired_tokens = %{
        access_token: "test_token",
        refresh_token: "refresh_token",
        expires_at: DateTime.add(DateTime.utc_now(), -3600, :second),
        token_type: "Bearer"
      }

      store_test_tokens(expired_tokens)

      refute Auth.authenticated?()
    end

    test "returns true when valid tokens exist" do
      valid_tokens = %{
        access_token: "test_token",
        refresh_token: "refresh_token",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second),
        token_type: "Bearer"
      }

      store_test_tokens(valid_tokens)

      assert Auth.authenticated?()
    end
  end

  describe "logout/0" do
    test "clears stored tokens" do
      # Store some tokens
      tokens = %{
        access_token: "test_token",
        refresh_token: "refresh_token",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second),
        token_type: "Bearer"
      }

      store_test_tokens(tokens)

      assert :ok = Auth.logout()
      assert [] = :ets.lookup(:spotify_tokens, :tokens)
    end

    test "succeeds even when no tokens are stored" do
      assert :ok = Auth.logout()
    end
  end

  describe "get_access_token/0" do
    test "returns error when no tokens are stored" do
      assert {:error, :no_tokens} = Auth.get_access_token()
    end

    test "returns access token when valid tokens exist" do
      valid_tokens = %{
        access_token: "test_access_token",
        refresh_token: "refresh_token",
        expires_at: DateTime.add(DateTime.utc_now(), 3600, :second),
        token_type: "Bearer"
      }

      store_test_tokens(valid_tokens)

      assert {:ok, "test_access_token"} = Auth.get_access_token()
    end

    # Note: Testing automatic refresh would require mocking OAuth2 client
    # which is more suitable for integration tests
  end
end
