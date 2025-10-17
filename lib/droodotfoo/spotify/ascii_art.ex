defmodule Droodotfoo.Spotify.AsciiArt do
  @moduledoc """
  ASCII art generation for Spotify content.
  Creates terminal-friendly visualizations for tracks, albums, and playback state.
  """

  alias Droodotfoo.{Ascii, AsciiChart}

  @doc """
  Renders the Spotify logo in ASCII art.
  """
  def spotify_logo do
    [
      "   ▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄▄",
      "  ▐                             ▌",
      "  ▐  ●●●●   ●●●●  ●●●●●●●●●●●  ▌",
      "  ▐  ●   ●  ●   ● ●   ●   ●   ● ▌",
      "  ▐  ●●●●   ●●●●  ●   ●   ●   ● ▌",
      "  ▐       ●      ● ●   ●   ●   ● ▌",
      "  ▐  ●●●●   ●●●●  ●   ●   ●   ● ▌",
      "  ▐                             ▌",
      "   ▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀▀"
    ]
  end

  @doc """
  Renders a track info display with ASCII art formatting.
  """
  def render_track_display(track, options \\ []) do
    width = Keyword.get(options, :width, 78)

    if track do
      render_playing_track(track, width)
    else
      render_no_track(width)
    end
  end

  @doc """
  Renders a progress bar for track playback.
  """
  def render_progress_bar(progress_ms, duration_ms, width \\ 50) do
    if progress_ms && duration_ms && duration_ms > 0 do
      progress_ratio = progress_ms / duration_ms
      percentage = progress_ratio * 100

      progress_time = Ascii.format_duration_ms(progress_ms)
      total_time = Ascii.format_duration_ms(duration_ms)

      bar = AsciiChart.bar_chart(percentage, max: 100, width: width)

      [
        "#{progress_time} [#{bar}] #{total_time}"
      ]
    else
      empty_bar = AsciiChart.bar_chart(0, max: 100, width: width)
      ["--:-- [#{empty_bar}] --:--"]
    end
  end

  @doc """
  Renders playback controls with ASCII art.
  """
  def render_playback_controls(is_playing \\ false) do
    play_pause_icon = if is_playing, do: "⏸ ", else: "▶ "

    [
      "┌─ Controls ──────────────────────────────┐",
      "│  ⏮  #{play_pause_icon}  ⏭     [P]lay/Pause   │",
      "│                      [N]ext Track     │",
      "│                      [B]ack Track     │",
      "└─────────────────────────────────────────┘"
    ]
  end

  @doc """
  Renders a playlist display with ASCII art.
  """
  def render_playlist_list(playlists, options \\ []) do
    max_items = Keyword.get(options, :max_items, 10)
    width = Keyword.get(options, :width, 78)

    header = [Ascii.box_header("Your Playlists", width)]

    content =
      if Enum.empty?(playlists) do
        [Ascii.box_content(" No playlists found", width)]
      else
        playlists
        |> Enum.take(max_items)
        |> Enum.with_index(1)
        |> Enum.map(fn {playlist, index} ->
          name = Ascii.truncate_text(playlist.name, width - 10)
          track_count = playlist.tracks.total

          text = "#{index}. #{name} (#{track_count} tracks)"
          Ascii.box_content(text, width)
        end)
      end

    footer = [Ascii.box_footer(width)]

    header ++ content ++ footer
  end

  @doc """
  Renders a device list with ASCII art.
  """
  def render_device_list(devices, options \\ []) do
    width = Keyword.get(options, :width, 78)

    header = [Ascii.box_header("Available Devices", width)]

    content =
      if Enum.empty?(devices) do
        [Ascii.box_content(" No devices found", width)]
      else
        devices
        |> Enum.with_index(1)
        |> Enum.map(fn {device, index} ->
          format_device_entry(device, index, width)
        end)
      end

    footer = [Ascii.box_footer(width)]

    header ++ content ++ footer
  end

  @doc """
  Renders a search results display.
  """
  def render_search_results(results, query, type \\ "track", options \\ []) do
    max_items = Keyword.get(options, :max_items, 10)
    width = Keyword.get(options, :width, 78)

    truncated_query = Ascii.truncate_text(query, 20)
    header = [Ascii.box_header("Search Results: \"#{truncated_query}\"", width)]

    content =
      if Enum.empty?(results) do
        [Ascii.box_content(" No results found", width)]
      else
        results
        |> Enum.take(max_items)
        |> Enum.with_index(1)
        |> Enum.map(fn {item, index} ->
          render_search_result_item(item, index, type, width)
        end)
      end

    footer = [Ascii.box_footer(width)]

    header ++ content ++ footer
  end

  @doc """
  Renders a volume control display.
  """
  def render_volume_control(volume, options \\ []) do
    width = Keyword.get(options, :width, 40)
    bar_width = width - 10

    volume_bar = AsciiChart.bar_chart(volume, max: 100, width: bar_width)

    [
      "┌─ Volume ──────────────────────────────┐",
      "│ #{String.pad_leading("#{volume}%", 3)} [#{volume_bar}] │",
      "└───────────────────────────────────────┘"
    ]
  end

  # Private Functions

  defp render_playing_track(track, width) do
    title_line = Ascii.truncate_text(track.name, width - 4)

    artist_line =
      track.artists
      |> Enum.map_join(", ", & &1.name)
      |> Ascii.truncate_text(width - 4)

    album_line = Ascii.truncate_text(track.album.name, width - 4)

    border_line = String.duplicate("═", width - 2)

    [
      "┌" <> border_line <> "┐",
      "│ ♫ #{String.pad_trailing(title_line, width - 5)}│",
      "│   #{String.pad_trailing("by #{artist_line}", width - 5)}│",
      "│   #{String.pad_trailing("from #{album_line}", width - 5)}│",
      "└" <> border_line <> "┘"
    ]
  end

  defp render_no_track(width) do
    border_line = String.duplicate("═", width - 2)
    empty_line = String.duplicate(" ", width - 4)

    [
      "┌" <> border_line <> "┐",
      "│ #{String.pad_trailing("No track playing", width - 3)}│",
      "│ #{empty_line} │",
      "│ #{String.pad_trailing("Start playing music on Spotify", width - 3)}│",
      "└" <> border_line <> "┘"
    ]
  end

  defp render_search_result_item(item, index, type, width) do
    text =
      case type do
        "track" ->
          artists = Enum.map_join(item.artists, ", ", & &1.name)
          "#{item.name} - #{artists}"

        "artist" ->
          follower_count = Ascii.format_number(item.followers)
          "#{item.name} (#{follower_count} followers)"

        "album" ->
          artists = Enum.map_join(item.artists, ", ", & &1.name)
          "#{item.name} by #{artists}"

        "playlist" ->
          "#{item.name} (#{item.tracks.total} tracks)"

        _ ->
          to_string(item)
      end

    truncated = Ascii.truncate_text(text, width - 8)
    Ascii.box_content("#{index}. #{truncated}", width)
  end

  defp format_device_entry(device, index, width) do
    status = if device.is_active, do: "●", else: "○"
    name = Ascii.truncate_text(device.name, width - 15)
    type = device.type
    volume = if device.volume_percent, do: " #{device.volume_percent}%", else: ""

    text = "#{status} #{index}. #{name} (#{type})#{volume}"
    Ascii.box_content(text, width)
  end
end
