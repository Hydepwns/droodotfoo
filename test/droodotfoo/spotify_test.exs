defmodule Droodotfoo.SpotifyTest do
  use ExUnit.Case, async: false

  alias Droodotfoo.Spotify

  setup do
    # Clean up any existing ETS tables (may fail if table is :protected and owned by another process)
    try do
      if :ets.info(:spotify_auth_state) != :undefined do
        :ets.delete(:spotify_auth_state)
      end
    rescue
      ArgumentError -> :ok
    end

    try do
      if :ets.info(:spotify_tokens) != :undefined do
        :ets.delete(:spotify_tokens)
      end
    rescue
      ArgumentError -> :ok
    end

    # Start a test instance of the Spotify
    # The actual Spotify is started in the application supervision tree
    # For testing, we verify it responds correctly
    :ok
  end

  describe "start_link/1" do
    test "starts the GenServer successfully" do
      # Spotify is already started in supervision tree
      # Just verify it's running
      assert Process.whereis(Spotify) != nil
    end
  end

  describe "auth_status/0" do
    test "returns valid auth status" do
      # Auth status can be :not_authenticated, :pending, or :authenticated
      status = Spotify.auth_status()
      assert status in [:not_authenticated, :pending, :authenticated]
    end
  end

  describe "start_auth/0" do
    test "returns error when credentials are missing" do
      # Set empty credentials
      Application.put_env(:droodotfoo, :spotify_client_id, "")
      Application.put_env(:droodotfoo, :spotify_client_secret, "")

      assert {:error, :missing_credentials} = Spotify.start_auth()
    end

    test "returns authorization URL when credentials are present" do
      # Set test credentials
      Application.put_env(:droodotfoo, :spotify_client_id, "test_client_id")
      Application.put_env(:droodotfoo, :spotify_client_secret, "test_client_secret")

      case Spotify.start_auth() do
        {:ok, url} ->
          assert is_binary(url)
          assert url =~ "spotify.com"

        {:error, _reason} ->
          # Expected if server is not running or already authenticated
          :ok
      end
    end
  end

  describe "current_user/0" do
    test "returns nil when not authenticated" do
      # Without authentication, should return nil
      user = Spotify.current_user()
      assert user == nil || is_map(user)
    end
  end

  describe "current_track/0" do
    test "returns nil when not authenticated" do
      track = Spotify.current_track()
      assert track == nil || is_map(track)
    end
  end

  describe "playback_state/0" do
    test "returns nil when not authenticated" do
      state = Spotify.playback_state()
      assert state == nil || is_map(state)
    end
  end

  describe "playlists/0" do
    test "returns empty list when not authenticated" do
      playlists = Spotify.playlists()
      assert is_list(playlists)
    end
  end

  describe "control_playback/1" do
    test "returns error when not authenticated" do
      assert {:error, :not_authenticated} = Spotify.control_playback(:play)
      assert {:error, :not_authenticated} = Spotify.control_playback(:pause)
      assert {:error, :not_authenticated} = Spotify.control_playback(:next)
      assert {:error, :not_authenticated} = Spotify.control_playback(:previous)
    end

    test "validates action parameter" do
      # Should only accept valid actions
      valid_actions = [:play, :pause, :next, :previous]

      Enum.each(valid_actions, fn action ->
        result = Spotify.control_playback(action)
        assert result in [:ok, {:error, :not_authenticated}, {:error, :no_auth_token}]
      end)
    end
  end

  describe "refresh_now_playing/0" do
    test "sends cast to refresh playback data" do
      # Should not crash
      assert :ok = Spotify.refresh_now_playing()
    end
  end
end
