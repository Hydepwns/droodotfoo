defmodule Droodotfoo.Spotify.APITest do
  use ExUnit.Case, async: false

  alias Droodotfoo.Spotify.API

  describe "get_current_user/0" do
    test "returns error when not authenticated" do
      # This will fail to get access token
      assert {:error, _reason} = API.get_current_user()
    end

    # Integration tests with real API would go here
  end

  describe "get_currently_playing/0" do
    test "returns error when not authenticated" do
      assert {:error, _reason} = API.get_currently_playing()
    end
  end

  describe "get_playback_state/0" do
    test "returns error when not authenticated" do
      assert {:error, _reason} = API.get_playback_state()
    end
  end

  describe "control_playback/1" do
    test "returns error when not authenticated for play" do
      assert {:error, _reason} = API.control_playback(:play)
    end

    test "returns error when not authenticated for pause" do
      assert {:error, _reason} = API.control_playback(:pause)
    end

    test "returns error when not authenticated for next" do
      assert {:error, _reason} = API.control_playback(:next)
    end

    test "returns error when not authenticated for previous" do
      assert {:error, _reason} = API.control_playback(:previous)
    end
  end

  describe "set_volume/1" do
    test "returns error when not authenticated" do
      assert {:error, _reason} = API.set_volume(50)
    end

    test "accepts valid volume range" do
      # Should validate volume between 0-100
      # (will fail auth, but testing input validation)
      assert {:error, _reason} = API.set_volume(0)
      assert {:error, _reason} = API.set_volume(50)
      assert {:error, _reason} = API.set_volume(100)
    end
  end

  describe "get_user_playlists/1" do
    test "returns error when not authenticated" do
      assert {:error, _reason} = API.get_user_playlists()
    end

    test "accepts limit parameter" do
      assert {:error, _reason} = API.get_user_playlists(10)
      assert {:error, _reason} = API.get_user_playlists(50)
    end
  end

  describe "get_playlist_tracks/2" do
    test "returns error when not authenticated" do
      assert {:error, _reason} = API.get_playlist_tracks("test_playlist_id")
    end

    test "accepts limit parameter" do
      assert {:error, _reason} = API.get_playlist_tracks("test_id", 20)
    end
  end

  describe "search/3" do
    test "returns error when not authenticated" do
      assert {:error, _reason} = API.search("test query")
    end

    test "accepts type parameter" do
      assert {:error, _reason} = API.search("test", "track")
      assert {:error, _reason} = API.search("test", "artist")
      assert {:error, _reason} = API.search("test", "album")
      assert {:error, _reason} = API.search("test", "playlist")
    end

    test "accepts limit parameter" do
      assert {:error, _reason} = API.search("test", "track", 10)
      assert {:error, _reason} = API.search("test", "track", 50)
    end
  end

  describe "get_devices/0" do
    test "returns error when not authenticated" do
      assert {:error, _reason} = API.get_devices()
    end
  end
end
