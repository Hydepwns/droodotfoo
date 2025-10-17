defmodule Droodotfoo.Spotify.API do
  @moduledoc """
  Spotify Web API client using Req HTTP client.
  Handles authentication and provides functions for Spotify API calls.
  """

  require Logger
  alias Droodotfoo.HttpClient
  alias Droodotfoo.Spotify.{Auth, Cache}

  @base_url "https://api.spotify.com/v1"

  # API Client Setup

  defp client do
    case Auth.get_access_token() do
      {:ok, token} ->
        HttpClient.new(
          @base_url,
          [{"authorization", "Bearer #{token}"}]
        )

      {:error, reason} ->
        Logger.error("Failed to get access token: #{inspect(reason)}")
        nil
    end
  end

  # User Profile

  @doc """
  Gets the current user's profile information.
  """
  def get_current_user do
    cache_key = "current_user"

    case Cache.get(cache_key) do
      {:ok, user} ->
        {:ok, user}

      {:error, :not_found} ->
        case make_request(:get, "/me") do
          {:ok, %{body: user_data}} ->
            user = parse_user(user_data)
            # Cache for 5 minutes
            Cache.put(cache_key, user, 300_000)
            {:ok, user}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  # Playback

  @doc """
  Gets the currently playing track.
  """
  def get_currently_playing do
    case make_request(:get, "/me/player/currently-playing") do
      {:ok, %{body: track_data}} when track_data != "" ->
        track = parse_currently_playing(track_data)
        {:ok, track}

      {:ok, %{body: ""}} ->
        {:error, :no_track_playing}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Gets the current playback state.
  """
  def get_playback_state do
    case make_request(:get, "/me/player") do
      {:ok, %{body: playback_data}} when playback_data != "" ->
        playback = parse_playback_state(playback_data)
        {:ok, playback}

      {:ok, %{body: ""}} ->
        {:error, :no_active_device}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Controls playback (play, pause, next, previous).
  """
  def control_playback(action) do
    endpoint =
      case action do
        :play -> "/me/player/play"
        :pause -> "/me/player/pause"
        :next -> "/me/player/next"
        :previous -> "/me/player/previous"
      end

    method = if action in [:play, :pause], do: :put, else: :post

    case make_request(method, endpoint) do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Sets the volume for the current device (0-100).
  """
  def set_volume(volume) when volume >= 0 and volume <= 100 do
    case make_request(:put, "/me/player/volume?volume_percent=#{volume}") do
      {:ok, _} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  # Playlists

  @doc """
  Gets the current user's playlists.
  """
  def get_user_playlists(limit \\ 20) do
    cache_key = "user_playlists_#{limit}"

    case Cache.get(cache_key) do
      {:ok, playlists} ->
        {:ok, playlists}

      {:error, :not_found} ->
        case make_request(:get, "/me/playlists?limit=#{limit}") do
          {:ok, %{body: %{"items" => playlists_data}}} ->
            playlists = Enum.map(playlists_data, &parse_playlist/1)
            # Cache for 10 minutes
            Cache.put(cache_key, playlists, 600_000)
            {:ok, playlists}

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  @doc """
  Gets tracks from a specific playlist.
  """
  def get_playlist_tracks(playlist_id, limit \\ 50) do
    cache_key = "playlist_tracks_#{playlist_id}_#{limit}"

    case Cache.get(cache_key) do
      {:ok, tracks} ->
        {:ok, tracks}

      {:error, :not_found} ->
        fetch_and_cache_playlist_tracks(playlist_id, limit, cache_key)
    end
  end

  defp fetch_and_cache_playlist_tracks(playlist_id, limit, cache_key) do
    endpoint = "/playlists/#{playlist_id}/tracks?limit=#{limit}"

    case make_request(:get, endpoint) do
      {:ok, %{body: %{"items" => tracks_data}}} ->
        tracks = Enum.map(tracks_data, fn item -> parse_track(item["track"]) end)
        # Cache for 5 minutes
        Cache.put(cache_key, tracks, 300_000)
        {:ok, tracks}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Search

  @doc """
  Searches for tracks, artists, albums, or playlists.
  """
  def search(query, type \\ "track", limit \\ 20) do
    encoded_query = URI.encode(query)
    endpoint = "/search?q=#{encoded_query}&type=#{type}&limit=#{limit}"

    case make_request(:get, endpoint) do
      {:ok, %{body: results}} ->
        parsed_results = parse_search_results(results, type)
        {:ok, parsed_results}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Device Management

  @doc """
  Gets the user's available devices.
  """
  def get_devices do
    case make_request(:get, "/me/player/devices") do
      {:ok, %{body: %{"devices" => devices_data}}} ->
        devices = Enum.map(devices_data, &parse_device/1)
        {:ok, devices}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private Functions

  defp make_request(method, endpoint, body \\ nil) do
    case client() do
      nil ->
        {:error, :no_auth_token}

      http_client ->
        options = [method: method, url: endpoint]
        options = if body, do: options ++ [json: body], else: options

        HttpClient.request(http_client, options)
    end
  end

  # Parsing Functions

  defp parse_user(data) do
    %{
      id: data["id"],
      display_name: data["display_name"],
      email: data["email"],
      followers: data["followers"]["total"],
      images: parse_images(data["images"]),
      country: data["country"],
      product: data["product"]
    }
  end

  defp parse_currently_playing(data) do
    %{
      track: parse_track(data["item"]),
      is_playing: data["is_playing"],
      progress_ms: data["progress_ms"],
      timestamp: data["timestamp"],
      context: parse_context(data["context"]),
      device: parse_device(data["device"])
    }
  end

  defp parse_playback_state(data) do
    %{
      device: parse_device(data["device"]),
      repeat_state: data["repeat_state"],
      shuffle_state: data["shuffle_state"],
      is_playing: data["is_playing"],
      timestamp: data["timestamp"],
      progress_ms: data["progress_ms"],
      item: parse_track(data["item"])
    }
  end

  defp parse_track(nil), do: nil

  defp parse_track(data) do
    %{
      id: data["id"],
      name: data["name"],
      artists:
        Enum.map(data["artists"] || [], fn artist ->
          %{id: artist["id"], name: artist["name"]}
        end),
      album: %{
        id: data["album"]["id"],
        name: data["album"]["name"],
        images: parse_images(data["album"]["images"])
      },
      duration_ms: data["duration_ms"],
      explicit: data["explicit"],
      popularity: data["popularity"],
      preview_url: data["preview_url"],
      external_urls: data["external_urls"]
    }
  end

  defp parse_playlist(data) do
    %{
      id: data["id"],
      name: data["name"],
      description: data["description"],
      images: parse_images(data["images"]),
      owner: %{
        id: data["owner"]["id"],
        display_name: data["owner"]["display_name"]
      },
      public: data["public"],
      tracks: %{
        total: data["tracks"]["total"]
      }
    }
  end

  defp parse_device(nil), do: nil

  defp parse_device(data) do
    %{
      id: data["id"],
      name: data["name"],
      type: data["type"],
      is_active: data["is_active"],
      is_private_session: data["is_private_session"],
      is_restricted: data["is_restricted"],
      volume_percent: data["volume_percent"]
    }
  end

  defp parse_context(nil), do: nil

  defp parse_context(data) do
    %{
      type: data["type"],
      href: data["href"],
      external_urls: data["external_urls"],
      uri: data["uri"]
    }
  end

  defp parse_images(nil), do: []

  defp parse_images(images) do
    Enum.map(images, fn image ->
      %{
        height: image["height"],
        width: image["width"],
        url: image["url"]
      }
    end)
  end

  defp parse_search_results(results, type) do
    case type do
      "track" ->
        results["tracks"]["items"]
        |> Enum.map(&parse_track/1)

      "artist" ->
        results["artists"]["items"]
        |> Enum.map(&parse_artist/1)

      "album" ->
        results["albums"]["items"]
        |> Enum.map(&parse_album/1)

      "playlist" ->
        results["playlists"]["items"]
        |> Enum.map(&parse_playlist/1)

      _ ->
        []
    end
  end

  defp parse_artist(data) do
    %{
      id: data["id"],
      name: data["name"],
      genres: data["genres"],
      images: parse_images(data["images"]),
      popularity: data["popularity"],
      followers: data["followers"]["total"],
      external_urls: data["external_urls"]
    }
  end

  defp parse_album(data) do
    %{
      id: data["id"],
      name: data["name"],
      artists:
        Enum.map(data["artists"] || [], fn artist ->
          %{id: artist["id"], name: artist["name"]}
        end),
      images: parse_images(data["images"]),
      release_date: data["release_date"],
      total_tracks: data["total_tracks"],
      external_urls: data["external_urls"]
    }
  end
end
