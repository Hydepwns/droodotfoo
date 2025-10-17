defmodule Droodotfoo.Raxol.Renderer.Spotify do
  @moduledoc """
  Spotify UI rendering components for the terminal.
  Handles all Spotify-related views including authentication, playback, playlists, and controls.
  """

  alias Droodotfoo.Raxol.BoxConfig
  alias Droodotfoo.Raxol.Renderer.Helpers
  alias Droodotfoo.Spotify

  @doc """
  Draw the Spotify authentication prompt when user is not authenticated.
  """
  def draw_auth_prompt do
    [
      "┌─ Spotify ───────────────────────────────────────────────────────────┐",
      "│                                                                     │",
      "│  Status: [NOT AUTHENTICATED]                                        │",
      "│                                                                     │",
      "│  To use Spotify features, authenticate:                             │",
      "│                                                                     │",
      "│  ┌──────────────────────────────────────────────────────────────┐   │",
      "│  │  1. Run: :spotify auth                                       │   │",
      "│  │     - Opens browser automatically                            │   │",
      "│  │     - Log in with your Spotify account                       │   │",
      "│  │     - Grant access to droo.foo                               │   │",
      "│  └──────────────────────────────────────────────────────────────┘   │",
      "│                                                                     │",
      "│  Or visit manually:                                                 │",
      "│    http://localhost:4000/auth/spotify                               │",
      "│                                                                     │",
      "│  Features available after auth:                                     │",
      "│    [>] Now Playing Display with real-time progress                  │",
      "│    [>] Playback Controls (play/pause/next/prev/volume)              │",
      "│    [>] Playlist Browser                                             │",
      "│    [>] Device Control                                               │",
      "│    [>] Search & Play                                                │",
      "│                                                                     │",
      "│  Press 'a' to start authentication                                  │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]
  end

  @doc """
  Draw the main Spotify dashboard with now playing and controls.
  """
  def draw_dashboard do
    playback_data = gather_playback_data()
    state_icon = get_state_icon(playback_data)

    header = build_dashboard_header(playback_data)
    now_playing = build_now_playing_section(playback_data.current_track, playback_data.playback, state_icon)
    controls = build_controls_section()
    buttons = build_dashboard_buttons()

    header ++ now_playing ++ controls ++ buttons
  end

  defp gather_playback_data do
    %{
      current_track: Spotify.current_track(),
      playback: Spotify.playback_state(),
      loading: Spotify.loading?(),
      last_error: Spotify.last_error()
    }
  end

  defp get_state_icon(%{loading: true}), do: "[~]"
  defp get_state_icon(%{playback: %{is_playing: true}}), do: "[>]"
  defp get_state_icon(%{playback: %{is_playing: false}}), do: "[||]"
  defp get_state_icon(_), do: "[--]"

  defp build_dashboard_header(playback_data) do
    status_line = build_status_line(playback_data)
    last_update_line = build_last_update_line(playback_data.playback)

    [
      "┌─ Spotify ───────────────────────────────────────────────────────────┐",
      "│                                                                     │",
      status_line,
      last_update_line,
      "│                                                                     │"
    ]
  end

  defp build_status_line(%{loading: true}),
    do: "│  Status: [LOADING...]                                           │"

  defp build_status_line(%{last_error: error}) when not is_nil(error) do
    error_msg = BoxConfig.truncate_and_pad(to_string(error), BoxConfig.content_width() - 23)
    "│  Status: [ERROR: #{error_msg}] │"
  end

  defp build_status_line(_),
    do: "│  Status: [CONNECTED]                                            │"

  defp build_last_update_line(%{timestamp: ts}) when not is_nil(ts) do
    time_ago = Helpers.format_time_ago(ts)
    "│  Last refresh: #{BoxConfig.truncate_and_pad(time_ago, BoxConfig.content_width() - 18)}│"
  end

  defp build_last_update_line(_),
    do: "│  Last refresh: --                                                │"

  defp build_now_playing_section(%{name: name, artists: artists}, playback, state_icon) do
    artist_names = Enum.map_join(artists, ", ", & &1["name"])
    truncated_name = String.slice(name, 0..40)
    truncated_artist = String.slice(artist_names, 0..40)
    progress_bar = build_progress_bar(playback)

    [
      "│  Now Playing: #{state_icon}                                         │",
      "│    #{BoxConfig.truncate_and_pad(truncated_name, BoxConfig.content_width() - 6)}│",
      "│    #{BoxConfig.truncate_and_pad(truncated_artist, BoxConfig.content_width() - 6)}│",
      "│                                                                     │",
      "│  #{progress_bar} │"
    ]
  end

  defp build_now_playing_section(_, _, state_icon) do
    [
      "│  Now Playing: #{state_icon} --                                      │",
      "│                                                                     │"
    ]
  end

  defp build_controls_section do
    [
      "│                                                                     │",
      "│     [B]PREV  [SPACE]PLAY/PAUSE  [N]EXT    [=/-]VOL  [R]EFRESH     │"
    ]
  end

  defp build_dashboard_buttons do
    [
      "│                                                                     │",
      "│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │",
      "│  │ [P]LAYLISTS  │  │  [D]EVICES   │  │   [S]EARCH   │               │",
      "│  └──────────────┘  └──────────────┘  └──────────────┘               │",
      "│                                                                     │",
      "│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │",
      "│  │ [C]ONTROLS   │  │  [V]OLUME    │  │  [R]EFRESH   │               │",
      "│  └──────────────┘  └──────────────┘  └──────────────┘               │",
      "│                                                                     │",
      "│  Quick: [SPACE]Play/Pause [N]ext [B]ack [=/-]Volume                 │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]
  end

  @doc """
  Draw the appropriate Spotify view based on the current mode.
  """
  def draw_view(state) do
    case Map.get(state, :spotify_mode, :dashboard) do
      :dashboard -> draw_dashboard()
      :playlists -> draw_playlists()
      :devices -> draw_devices()
      :search -> draw_search()
      :controls -> draw_controls()
      :volume -> draw_volume()
      _ -> draw_dashboard()
    end
  end

  @doc """
  Draw the playlists view.
  """
  def draw_playlists do
    playlists = Spotify.playlists() || []

    header = [
      "┌─ Spotify > Playlists ───────────────────────────────────────────────┐",
      "│                                                                     │"
    ]

    playlist_lines =
      if Enum.empty?(playlists) do
        [
          "│  No playlists found.                                               │",
          "│                                                                     │",
          "│  Loading playlists...                                              │"
        ]
      else
        playlists
        |> Enum.take(15)
        |> Enum.map(fn playlist ->
          # "│  > " (4) + " " (1) + "│" (1) = 6, so content = 71 - 6 = 65
          # Split: 52 for name, 1 space, 12 for info
          name = BoxConfig.truncate_and_pad(playlist["name"] || "Untitled", 52)
          track_count = playlist["tracks"]["total"] || 0
          info = BoxConfig.truncate_and_pad("#{track_count} tracks", 12)
          "│  > #{name} #{info}│"
        end)
      end

    footer = [
      "│                                                                     │",
      "│  [ESC] Back to Dashboard  [ENTER] Play Playlist  [R] Refresh       │",
      "│  Quick: [P]laylists [D]evices [S]earch [C]ontrols [V]olume         │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]

    header ++ playlist_lines ++ footer
  end

  @doc """
  Draw the devices view.
  """
  def draw_devices do
    playback = Spotify.playback_state()
    current_device = playback && playback.device

    header = [
      "┌─ Spotify > Devices ─────────────────────────────────────────────────┐",
      "│                                                                     │"
    ]

    device_lines =
      if current_device do
        device_name = String.slice(current_device["name"] || "Unknown", 0..40)
        device_type = String.slice(current_device["type"] || "Unknown", 0..15)
        volume = current_device["volume_percent"] || 0
        is_active = if current_device["is_active"], do: "[ACTIVE]", else: ""

        [
          "│  Current Device:                                                   │",
          # "│    " (5) + "│" (1) = 6, so content = 71 - 6 = 65
          "│    #{BoxConfig.truncate_and_pad(device_name, BoxConfig.content_width() - 6)}│",
          # "│    Type: " (10) + "│" (1) = 11, so content = 71 - 11 = 60
          "│    Type: #{BoxConfig.truncate_and_pad(device_type, BoxConfig.content_width() - 11)}│",
          # "│    Volume: " (12) + "│" (1) = 13, so content = 71 - 13 = 58
          "│    Volume: #{BoxConfig.truncate_and_pad("#{volume}%", BoxConfig.content_width() - 13)}│",
          "│    #{BoxConfig.truncate_and_pad(is_active, BoxConfig.content_width() - 6)}│"
        ]
      else
        [
          "│  No active device found.                                           │",
          "│                                                                     │",
          "│  Please start playback on a Spotify device.                        │"
        ]
      end

    footer = [
      "│                                                                     │",
      "│  [ESC] Back to Dashboard  [=/-] Adjust Volume  [R] Refresh         │",
      "│  Quick: [P]laylists [D]evices [S]earch [C]ontrols [V]olume         │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]

    header ++ device_lines ++ footer
  end

  @doc """
  Draw the search view.
  """
  def draw_search do
    [
      "┌─ Spotify > Search ──────────────────────────────────────────────────┐",
      "│                                                                     │",
      "│  Search Mode                                                        │",
      "│                                                                     │",
      "│  Enter search query:                                                │",
      "│  ┌──────────────────────────────────────────────────────────────┐   │",
      "│  │ _                                                            │   │",
      "│  └──────────────────────────────────────────────────────────────┘   │",
      "│                                                                     │",
      "│  Results will appear here...                                        │",
      "│                                                                     │",
      "│  Search for:                                                        │",
      "│    - Tracks                                                         │",
      "│    - Albums                                                         │",
      "│    - Artists                                                        │",
      "│    - Playlists                                                      │",
      "│                                                                     │",
      "│  [ESC] Back to Dashboard  [ENTER] Search  [R] Refresh               │",
      "│  Quick: [P]laylists [D]evices [S]earch [C]ontrols [V]olume          │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]
  end

  @doc """
  Draw the playback controls view.
  """
  def draw_controls do
    current_track = Spotify.current_track()
    playback = Spotify.playback_state()

    state_icon =
      cond do
        playback && playback.is_playing -> "[>]"
        playback && !playback.is_playing -> "[||]"
        true -> "[--]"
      end

    progress_bar = build_progress_bar(playback)

    now_playing =
      case current_track do
        %{name: name, artists: artists} ->
          artist_names = Enum.map_join(artists, ", ", & &1["name"])
          truncated_name = String.slice(name, 0..50)
          truncated_artist = String.slice(artist_names, 0..50)

          [
            # "│  [>] " (7) + "│" (1) = 8, so content = 71 - 8 = 63
            "│  #{state_icon} #{BoxConfig.truncate_and_pad(truncated_name, BoxConfig.content_width() - 8)}│",
            # "│    by " (7) + "│" (1) = 8, so content = 71 - 8 = 63
            "│    by #{BoxConfig.truncate_and_pad(truncated_artist, BoxConfig.content_width() - 8)}│"
          ]

        _ ->
          [
            "│  #{state_icon} No track playing                                     │",
            "│                                                                     │"
          ]
      end

    header = [
      "┌─ Spotify > Playback Controls ───────────────────────────────────────┐",
      "│                                                                    │"
    ]

    controls = [
      "│                                                                     │",
      "│  #{progress_bar} │",
      "│                                                                     │",
      "│                  Playback Controls                                  │",
      "│                                                                     │",
      "│              ┌──────────────────────────────┐                        │",
      "│              │   [B] PREV   [SPACE] PLAY    │                       │",
      "│              │   [N] NEXT     [=/-] VOLUME  │                       │",
      "│              └──────────────────────────────┘                        │",
      "│                                                                     │"
    ]

    footer = [
      "│  [ESC] Back to Dashboard  [R] Refresh                              │",
      "│  Quick: [P]laylists [D]evices [S]earch [C]ontrols [V]olume         │",
      "│                                                                     │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]

    header ++ now_playing ++ controls ++ footer
  end

  @doc """
  Draw the volume control view.
  """
  def draw_volume do
    playback = Spotify.playback_state()

    current_volume =
      case playback do
        %{device: %{"volume_percent" => vol}} -> vol
        _ -> 50
      end

    # Build volume bar (0-100)
    bar_width = 50
    filled = round(current_volume / 100 * bar_width)
    empty = bar_width - filled
    volume_bar = String.duplicate("█", filled) <> String.duplicate("░", empty)

    header = [
      "┌─ Spotify > Volume Control ──────────────────────────────────────────┐",
      "│                                                                    │"
    ]

    volume_display = [
      # "│  Current Volume: " (19) + "│" (1) = 20, so content = 71 - 20 = 51
      "│  Current Volume: #{BoxConfig.truncate_and_pad("#{current_volume}%", BoxConfig.content_width() - 20)}│",
      "│                                                                     │",
      # "│  " (3) + "│" (1) = 4, so content = 71 - 4 = 67
      "│  #{BoxConfig.truncate_and_pad(volume_bar, BoxConfig.inner_width())}│",
      "│                                                                     │",
      "│                                                                     │",
      "│                  Volume Controls                                    │",
      "│                                                                     │",
      "│              ┌──────────────────────────────┐                       │",
      "│              │   [=] Volume Up              │                       │",
      "│              │   [-] Volume Down            │                       │",
      "│              │   [0-9] Set volume (0-100%)  │                       │",
      "│              └──────────────────────────────┘                       │",
      "│                                                                     │"
    ]

    footer = [
      "│  [ESC] Back to Dashboard  [R] Refresh                             │",
      "│  Quick: [P]laylists [D]evices [S]earch [C]ontrols [V]olume        │",
      "│                                                                   │",
      "└─────────────────────────────────────────────────────────────────────┘"
    ]

    header ++ volume_display ++ footer
  end

  @doc """
  Build a progress bar for playback position.
  """
  def build_progress_bar(playback) do
    case playback do
      %{progress_ms: progress, duration_ms: duration} when progress > 0 and duration > 0 ->
        # Calculate progress percentage
        percentage = progress / duration
        bar_width = 50
        filled = round(percentage * bar_width)
        empty = bar_width - filled

        # Build bar with block characters
        bar = String.duplicate("█", filled) <> String.duplicate("░", empty)

        # Format time
        current_time = Helpers.format_time(progress)
        total_time = Helpers.format_time(duration)

        time_str = "#{current_time} / #{total_time}"

        # Progress bar uses inner_width (67)
        padding =
          String.duplicate(
            " ",
            max(0, BoxConfig.inner_width() - String.length(bar) - String.length(time_str) - 2)
          )

        "#{bar}  #{time_str}#{padding}"

      _ ->
        # No playback data
        String.pad_trailing("--:-- / --:--", BoxConfig.inner_width())
    end
  end
end
