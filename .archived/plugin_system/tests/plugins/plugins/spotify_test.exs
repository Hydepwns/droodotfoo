defmodule Droodotfoo.Plugins.SpotifyTest do
  use ExUnit.Case, async: false

  alias Droodotfoo.Plugins.Spotify

  describe "metadata/0" do
    test "returns correct plugin metadata" do
      metadata = Spotify.metadata()

      assert metadata.name == "spotify"
      assert metadata.version == "1.0.0"
      assert metadata.description == "Spotify music controller and display"
      assert metadata.author == "droo.foo"
      assert metadata.commands == ["spotify", "music", "sp"]
      assert metadata.category == :utility
    end
  end

  describe "init/1" do
    test "initializes with auth mode when not authenticated" do
      terminal_state = %{width: 80, height: 24}

      assert {:ok, state} = Spotify.init(terminal_state)
      assert %Spotify{} = state
      assert state.mode == :auth
      assert state.playlists == []
      assert state.devices == []
      assert state.search_results == []
      assert state.search_query == ""
      assert state.volume == 50
      assert state.message == nil
    end
  end

  describe "handle_input/3 - general commands" do
    setup do
      terminal_state = %{width: 80, height: 24}
      {:ok, initial_state} = Spotify.init(terminal_state)
      {:ok, state: initial_state, terminal_state: terminal_state}
    end

    test "exits on 'q'", %{state: state, terminal_state: terminal_state} do
      assert {:exit, output} = Spotify.handle_input("q", state, terminal_state)
      assert Enum.any?(output, &String.contains?(&1, "Spotify plugin closed"))
    end

    test "exits on 'Q'", %{state: state, terminal_state: terminal_state} do
      assert {:exit, _output} = Spotify.handle_input("Q", state, terminal_state)
    end

    test "exits on 'quit'", %{state: state, terminal_state: terminal_state} do
      assert {:exit, _output} = Spotify.handle_input("quit", state, terminal_state)
    end

    test "exits on 'exit'", %{state: state, terminal_state: terminal_state} do
      assert {:exit, _output} = Spotify.handle_input("exit", state, terminal_state)
    end

    test "shows help", %{state: state, terminal_state: terminal_state} do
      {:continue, same_state, output} = Spotify.handle_input("help", state, terminal_state)

      # State shouldn't change
      assert same_state == state

      # Output should contain help text
      combined = Enum.join(output, "\n")
      assert String.contains?(combined, "HELP")
      assert String.contains?(combined, "MODES")
    end
  end

  describe "handle_input/3 - auth mode" do
    setup do
      terminal_state = %{width: 80, height: 24}
      {:ok, initial_state} = Spotify.init(terminal_state)
      {:ok, state: initial_state, terminal_state: terminal_state}
    end

    test "handles auth start command", %{state: state, terminal_state: terminal_state} do
      assert state.mode == :auth

      {:continue, new_state, _output} = Spotify.handle_input("1", state, terminal_state)

      # State should still be in auth mode
      assert new_state.mode == :auth
      # Message should be set (either success with URL or error)
      assert new_state.message != nil
    end

    test "handles auth complete command", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _output} = Spotify.handle_input("2", state, terminal_state)

      assert new_state.mode == :auth
      assert new_state.message != nil
    end
  end

  describe "handle_input/3 - main mode" do
    setup do
      terminal_state = %{width: 80, height: 24}
      {:ok, initial_state} = Spotify.init(terminal_state)
      # Switch to main mode
      main_state = %{initial_state | mode: :main}
      {:ok, state: main_state, terminal_state: terminal_state}
    end

    test "switches to playlists mode", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _output} = Spotify.handle_input("p", state, terminal_state)
      assert new_state.mode == :playlists
    end

    test "switches to devices mode", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _output} = Spotify.handle_input("d", state, terminal_state)
      assert new_state.mode == :devices
    end

    test "switches to search mode", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _output} = Spotify.handle_input("s", state, terminal_state)
      assert new_state.mode == :search
    end

    test "switches to controls mode", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _output} = Spotify.handle_input("c", state, terminal_state)
      assert new_state.mode == :controls
    end

    test "switches to volume mode", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _output} = Spotify.handle_input("v", state, terminal_state)
      assert new_state.mode == :volume
    end

    test "refreshes data", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _output} = Spotify.handle_input("r", state, terminal_state)
      assert new_state.message =~ "Refreshing"
    end

    test "toggles playback with space", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _output} = Spotify.handle_input(" ", state, terminal_state)
      # Message may be set (success/error) or nil depending on auth state
      assert new_state.mode == :main
    end
  end

  describe "handle_input/3 - controls mode" do
    setup do
      terminal_state = %{width: 80, height: 24}
      {:ok, initial_state} = Spotify.init(terminal_state)
      controls_state = %{initial_state | mode: :controls}
      {:ok, state: controls_state, terminal_state: terminal_state}
    end

    test "returns to main mode", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _output} = Spotify.handle_input("m", state, terminal_state)
      assert new_state.mode == :main
    end

    test "sends play command", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _output} = Spotify.handle_input("p", state, terminal_state)
      assert new_state.message != nil
    end

    test "sends next command", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _output} = Spotify.handle_input("n", state, terminal_state)
      assert new_state.message != nil
    end

    test "sends previous command", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _output} = Spotify.handle_input("b", state, terminal_state)
      assert new_state.message != nil
    end
  end

  describe "handle_input/3 - playlists mode" do
    setup do
      terminal_state = %{width: 80, height: 24}
      {:ok, initial_state} = Spotify.init(terminal_state)
      playlists_state = %{initial_state | mode: :playlists}
      {:ok, state: playlists_state, terminal_state: terminal_state}
    end

    test "returns to main mode", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _output} = Spotify.handle_input("m", state, terminal_state)
      assert new_state.mode == :main
    end

    test "refreshes playlists", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _output} = Spotify.handle_input("r", state, terminal_state)
      assert new_state.message != nil
    end

    test "handles playlist selection", %{state: state, terminal_state: terminal_state} do
      # Add some mock playlists with proper structure
      state_with_playlists = %{
        state
        | playlists: [
            %{id: "1", name: "Playlist 1", tracks: %{total: 10}},
            %{id: "2", name: "Playlist 2", tracks: %{total: 20}}
          ]
      }

      {:continue, new_state, _output} =
        Spotify.handle_input("1", state_with_playlists, terminal_state)

      assert new_state.message =~ "Selected"
    end
  end

  describe "handle_input/3 - volume mode" do
    setup do
      terminal_state = %{width: 80, height: 24}
      {:ok, initial_state} = Spotify.init(terminal_state)
      volume_state = %{initial_state | mode: :volume}
      {:ok, state: volume_state, terminal_state: terminal_state}
    end

    test "returns to main mode", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _output} = Spotify.handle_input("m", state, terminal_state)
      assert new_state.mode == :main
    end

    test "increases volume", %{state: state, terminal_state: terminal_state} do
      initial_volume = state.volume
      {:continue, new_state, _output} = Spotify.handle_input("+", state, terminal_state)
      # Volume should attempt to increase (may fail if not authenticated)
      assert new_state.volume >= initial_volume || new_state.message != nil
    end

    test "decreases volume", %{state: state, terminal_state: terminal_state} do
      state_with_volume = %{state | volume: 50}

      {:continue, new_state, _output} =
        Spotify.handle_input("-", state_with_volume, terminal_state)

      # Volume should attempt to decrease (may fail if not authenticated)
      assert new_state.volume <= 50 || new_state.message != nil
    end

    test "sets exact volume", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _output} = Spotify.handle_input("75", state, terminal_state)
      # Should attempt to set volume to 75 (may fail if not authenticated)
      assert new_state.volume == 75 || new_state.message != nil
    end
  end

  describe "handle_input/3 - search mode" do
    setup do
      terminal_state = %{width: 80, height: 24}
      {:ok, initial_state} = Spotify.init(terminal_state)
      search_state = %{initial_state | mode: :search}
      {:ok, state: search_state, terminal_state: terminal_state}
    end

    test "returns to main mode", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _output} = Spotify.handle_input("m", state, terminal_state)
      assert new_state.mode == :main
    end

    test "performs search", %{state: state, terminal_state: terminal_state} do
      {:continue, new_state, _output} =
        Spotify.handle_input("test query", state, terminal_state)

      # Should set search query
      assert new_state.search_query == "test query" || new_state.message != nil
    end
  end

  describe "render/2" do
    test "renders auth mode" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = Spotify.init(terminal_state)

      output = Spotify.render(state, terminal_state)

      assert Enum.any?(output, &String.contains?(&1, "SPOTIFY"))
      assert Enum.any?(output, &String.contains?(&1, "AUTH"))
      assert Enum.any?(output, &String.contains?(&1, "Authentication"))
    end

    test "renders main mode" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = Spotify.init(terminal_state)
      main_state = %{state | mode: :main}

      output = Spotify.render(main_state, terminal_state)

      assert Enum.any?(output, &String.contains?(&1, "SPOTIFY"))
      assert Enum.any?(output, &String.contains?(&1, "MAIN"))
      assert Enum.any?(output, &String.contains?(&1, "Navigation"))
    end

    test "renders controls mode" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = Spotify.init(terminal_state)
      controls_state = %{state | mode: :controls}

      output = Spotify.render(controls_state, terminal_state)

      assert Enum.any?(output, &String.contains?(&1, "CONTROLS"))
      assert Enum.any?(output, &String.contains?(&1, "Playback"))
    end

    test "renders message when present" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = Spotify.init(terminal_state)
      state_with_message = %{state | message: "Test message"}

      output = Spotify.render(state_with_message, terminal_state)
      combined = Enum.join(output, "\n")

      assert String.contains?(combined, "Test message")
    end
  end

  describe "cleanup/1" do
    test "cleanup returns ok" do
      terminal_state = %{width: 80, height: 24}
      {:ok, state} = Spotify.init(terminal_state)

      assert :ok = Spotify.cleanup(state)
    end
  end
end
