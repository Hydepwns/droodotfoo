defmodule Droodotfoo.Plugins.Spotify do
  @moduledoc """
  Spotify plugin for the terminal interface.
  Provides a terminal-based Spotify controller and display.
  """

  @behaviour Droodotfoo.PluginSystem.Plugin

  alias Droodotfoo.Spotify.{Manager, API, AsciiArt}

  defstruct [
    :mode,
    :current_track,
    :playlists,
    :devices,
    :search_results,
    :search_query,
    :volume,
    :message,
    :last_update
  ]

  @modes [:main, :playlists, :devices, :search, :controls, :volume, :auth]

  # Plugin Behaviour Callbacks

  @impl true
  def metadata do
    %{
      name: "spotify",
      version: "1.0.0",
      description: "Spotify music controller and display",
      author: "droo.foo",
      commands: ["spotify", "music", "sp"],
      category: :utility
    }
  end

  @impl true
  def init(_terminal_state) do
    initial_state = %__MODULE__{
      mode: :auth,
      current_track: nil,
      playlists: [],
      devices: [],
      search_results: [],
      search_query: "",
      volume: 50,
      message: nil,
      last_update: DateTime.utc_now()
    }

    # Check if already authenticated
    case Manager.auth_status() do
      :authenticated ->
        {:ok, %{initial_state | mode: :main}}

      _ ->
        {:ok, initial_state}
    end
  end

  @impl true
  def handle_input(input, state, _terminal_state) do
    input = String.trim(input)

    case input do
      input when input in ["q", "Q", "quit", "exit"] ->
        {:exit, ["Spotify plugin closed."]}

      "help" ->
        {:continue, state, render_help()}

      _ ->
        handle_mode_input(input, state)
    end
  end

  @impl true
  def render(state, _terminal_state) do
    header = [
      "=" |> String.duplicate(78),
      String.pad_leading(String.pad_trailing("SPOTIFY CONTROLLER", 40), 78),
      "=" |> String.duplicate(78)
    ]

    mode_indicator = [
      "",
      "Mode: #{state.mode |> to_string() |> String.upcase()}" |> String.pad_trailing(78),
      ""
    ]

    content = render_mode_content(state)

    message_section =
      if state.message do
        ["", ">> #{state.message}", ""]
      else
        []
      end

    footer = [
      "-" |> String.duplicate(78),
      "Commands: [h]elp [q]uit  |  Navigate: [1-9] numbers, [m]ain, [p]laylist",
      "-" |> String.duplicate(78)
    ]

    header ++ mode_indicator ++ content ++ message_section ++ footer
  end

  @impl true
  def cleanup(_state) do
    :ok
  end

  # Input Handling

  defp handle_mode_input(input, %{mode: :auth} = state) do
    case input do
      "1" ->
        case Manager.start_auth() do
          {:ok, url} ->
            message = "Visit this URL to authenticate: #{url}"
            {:continue, %{state | message: message}, render(state, %{})}

          {:error, reason} ->
            message = "Authentication failed: #{inspect(reason)}"
            {:continue, %{state | message: message}, render(state, %{})}
        end

      "2" ->
        # This would typically be handled by a web callback
        message = "Enter auth code via web interface"
        {:continue, %{state | message: message}, render(state, %{})}

      _ ->
        {:continue, state, render(state, %{})}
    end
  end

  defp handle_mode_input(input, %{mode: :main} = state) do
    case input do
      "p" -> switch_to_mode(state, :playlists)
      "d" -> switch_to_mode(state, :devices)
      "s" -> switch_to_mode(state, :search)
      "c" -> switch_to_mode(state, :controls)
      "v" -> switch_to_mode(state, :volume)
      "r" -> refresh_data(state)
      # Spacebar
      " " -> toggle_playback(state)
      "space" -> toggle_playback(state)
      _ -> {:continue, state, render(state, %{})}
    end
  end

  defp handle_mode_input(input, %{mode: :controls} = state) do
    case input do
      "m" -> switch_to_mode(state, :main)
      "p" -> control_playback(state, :play)
      "space" -> toggle_playback(state)
      " " -> toggle_playback(state)
      "n" -> control_playback(state, :next)
      "b" -> control_playback(state, :previous)
      _ -> {:continue, state, render(state, %{})}
    end
  end

  defp handle_mode_input(input, %{mode: :playlists} = state) do
    case input do
      "m" ->
        switch_to_mode(state, :main)

      "r" ->
        refresh_playlists(state)

      _ ->
        # Try to parse as playlist selection
        case Integer.parse(input) do
          {index, ""} when index > 0 ->
            select_playlist(state, index - 1)

          _ ->
            {:continue, state, render(state, %{})}
        end
    end
  end

  defp handle_mode_input(input, %{mode: :devices} = state) do
    case input do
      "m" -> switch_to_mode(state, :main)
      "r" -> refresh_devices(state)
      _ -> {:continue, state, render(state, %{})}
    end
  end

  defp handle_mode_input(input, %{mode: :search} = state) do
    case input do
      "m" ->
        switch_to_mode(state, :main)

      "" ->
        {:continue, state, render(state, %{})}

      _ ->
        # Perform search
        perform_search(state, input)
    end
  end

  defp handle_mode_input(input, %{mode: :volume} = state) do
    case input do
      "m" ->
        switch_to_mode(state, :main)

      "+" ->
        adjust_volume(state, 5)

      "-" ->
        adjust_volume(state, -5)

      _ ->
        case Integer.parse(input) do
          {volume, ""} when volume >= 0 and volume <= 100 ->
            set_volume(state, volume)

          _ ->
            {:continue, state, render(state, %{})}
        end
    end
  end

  # Mode Content Rendering

  defp render_mode_content(%{mode: :auth}) do
    AsciiArt.spotify_logo() ++
      [
        "",
        "Spotify Authentication Required",
        "",
        "1. Start Authentication (get URL)",
        "2. Complete Authentication (after visiting URL)",
        "",
        "Note: You'll need Spotify Client ID and Secret configured."
      ]
  end

  defp render_mode_content(%{mode: :main} = state) do
    track_display = AsciiArt.render_track_display(state.current_track)

    progress_bar =
      case state.current_track do
        %{duration_ms: duration} ->
          # Would need current position from playback state
          AsciiArt.render_progress_bar(0, duration)

        _ ->
          AsciiArt.render_progress_bar(nil, nil)
      end

    # Would check actual state
    controls = AsciiArt.render_playback_controls(false)

    menu = [
      "",
      "Navigation:",
      "[p] Playlists    [d] Devices     [s] Search",
      "[c] Controls     [v] Volume      [r] Refresh",
      "[space] Play/Pause"
    ]

    track_display ++ [""] ++ progress_bar ++ [""] ++ controls ++ menu
  end

  defp render_mode_content(%{mode: :controls} = _state) do
    AsciiArt.render_playback_controls(false) ++
      [
        "",
        "Playback Controls:",
        "[p] Play/Pause",
        "[n] Next Track",
        "[b] Previous Track",
        "[space] Play/Pause",
        "",
        "[m] Back to Main"
      ]
  end

  defp render_mode_content(%{mode: :playlists} = state) do
    AsciiArt.render_playlist_list(state.playlists) ++
      [
        "",
        "Enter playlist number to view tracks",
        "[r] Refresh playlists  [m] Back to main"
      ]
  end

  defp render_mode_content(%{mode: :devices} = state) do
    AsciiArt.render_device_list(state.devices) ++
      [
        "",
        "[r] Refresh devices  [m] Back to main"
      ]
  end

  defp render_mode_content(%{mode: :search} = state) do
    results_display =
      if state.search_query != "" do
        AsciiArt.render_search_results(state.search_results, state.search_query)
      else
        ["Enter search query to find music:"]
      end

    results_display ++
      [
        "",
        "Type to search, [m] Back to main"
      ]
  end

  defp render_mode_content(%{mode: :volume} = state) do
    AsciiArt.render_volume_control(state.volume) ++
      [
        "",
        "Volume Controls:",
        "[+] Increase   [-] Decrease",
        "Or enter exact volume (0-100)",
        "",
        "[m] Back to main"
      ]
  end

  # Action Functions

  defp switch_to_mode(state, new_mode) when new_mode in @modes do
    new_state = %{state | mode: new_mode, message: nil}
    {:continue, new_state, render(new_state, %{})}
  end

  defp refresh_data(state) do
    # Refresh current track
    spawn(fn ->
      Manager.refresh_now_playing()
    end)

    message = "Refreshing data..."
    new_state = %{state | message: message, last_update: DateTime.utc_now()}
    {:continue, new_state, render(new_state, %{})}
  end

  defp toggle_playback(state) do
    # This would need to check current state
    case Manager.control_playback(:play) do
      :ok ->
        message = "Playback toggled"
        {:continue, %{state | message: message}, render(state, %{})}

      {:error, reason} ->
        message = "Failed to toggle playback: #{inspect(reason)}"
        {:continue, %{state | message: message}, render(state, %{})}
    end
  end

  defp control_playback(state, action) do
    case Manager.control_playback(action) do
      :ok ->
        message = "#{action |> to_string() |> String.capitalize()} command sent"
        {:continue, %{state | message: message}, render(state, %{})}

      {:error, reason} ->
        message = "Failed to #{action}: #{inspect(reason)}"
        {:continue, %{state | message: message}, render(state, %{})}
    end
  end

  defp refresh_playlists(state) do
    case Manager.playlists() do
      playlists when is_list(playlists) ->
        message = "Playlists refreshed"
        new_state = %{state | playlists: playlists, message: message}
        {:continue, new_state, render(new_state, %{})}

      _ ->
        message = "Failed to refresh playlists"
        {:continue, %{state | message: message}, render(state, %{})}
    end
  end

  defp refresh_devices(state) do
    case API.get_devices() do
      {:ok, devices} ->
        message = "Devices refreshed"
        new_state = %{state | devices: devices, message: message}
        {:continue, new_state, render(new_state, %{})}

      {:error, reason} ->
        message = "Failed to refresh devices: #{inspect(reason)}"
        {:continue, %{state | message: message}, render(state, %{})}
    end
  end

  defp select_playlist(state, index) do
    if index < length(state.playlists) do
      playlist = Enum.at(state.playlists, index)
      message = "Selected: #{playlist.name}"
      {:continue, %{state | message: message}, render(state, %{})}
    else
      message = "Invalid playlist selection"
      {:continue, %{state | message: message}, render(state, %{})}
    end
  end

  defp perform_search(state, query) do
    case API.search(query) do
      {:ok, results} ->
        new_state = %{
          state
          | search_query: query,
            search_results: results,
            message: "Found #{length(results)} results"
        }

        {:continue, new_state, render(new_state, %{})}

      {:error, reason} ->
        message = "Search failed: #{inspect(reason)}"
        {:continue, %{state | message: message}, render(state, %{})}
    end
  end

  defp adjust_volume(state, delta) do
    new_volume = max(0, min(100, state.volume + delta))
    set_volume(%{state | volume: new_volume}, new_volume)
  end

  defp set_volume(state, volume) do
    case API.set_volume(volume) do
      :ok ->
        message = "Volume set to #{volume}%"
        new_state = %{state | volume: volume, message: message}
        {:continue, new_state, render(new_state, %{})}

      {:error, reason} ->
        message = "Failed to set volume: #{inspect(reason)}"
        {:continue, %{state | message: message}, render(state, %{})}
    end
  end

  defp render_help do
    [
      "=" |> String.duplicate(78),
      "SPOTIFY PLUGIN HELP",
      "=" |> String.duplicate(78),
      "",
      "MODES:",
      "  Main      - Overview and current track display",
      "  Playlists - Browse and select playlists",
      "  Devices   - View available Spotify devices",
      "  Search    - Search for tracks, artists, albums",
      "  Controls  - Playback control interface",
      "  Volume    - Volume adjustment",
      "",
      "MAIN COMMANDS:",
      "  [p] Playlists    [d] Devices     [s] Search",
      "  [c] Controls     [v] Volume      [r] Refresh",
      "  [space] Play/Pause",
      "",
      "GENERAL:",
      "  [m] Return to main mode",
      "  [h] Show this help",
      "  [q] Quit plugin",
      "",
      "=" |> String.duplicate(78)
    ]
  end
end
