defmodule Droodotfoo.Spotify.API do
  @moduledoc """
  Spotify Web API client using Req HTTP client.
  Handles authentication and provides functions for Spotify API calls.
  """

  require Logger
  alias Droodotfoo.HttpClient
  alias Droodotfoo.Performance.Cache
  alias Droodotfoo.Spotify.Auth

  @base_url "https://api.spotify.com/v1"

  # Type definitions

  @type image :: %{height: integer() | nil, width: integer() | nil, url: String.t()}
  @type artist :: %{id: String.t(), name: String.t()}
  @type album :: %{id: String.t(), name: String.t(), images: [image()]}

  @type track :: %{
          id: String.t(),
          name: String.t(),
          artists: [artist()],
          album: album(),
          duration_ms: integer(),
          explicit: boolean(),
          popularity: integer() | nil,
          preview_url: String.t() | nil,
          external_urls: map()
        }

  @type playlist :: %{
          id: String.t(),
          name: String.t(),
          description: String.t() | nil,
          images: [image()],
          owner: %{id: String.t(), display_name: String.t()},
          public: boolean() | nil,
          tracks: %{total: integer()}
        }

  @type device :: %{
          id: String.t() | nil,
          name: String.t(),
          type: String.t(),
          is_active: boolean(),
          is_private_session: boolean(),
          is_restricted: boolean(),
          volume_percent: integer() | nil
        }

  @type context :: %{
          type: String.t(),
          href: String.t(),
          external_urls: map(),
          uri: String.t()
        }

  @type user :: %{
          id: String.t(),
          display_name: String.t() | nil,
          email: String.t() | nil,
          followers: integer(),
          images: [image()],
          country: String.t() | nil,
          product: String.t() | nil
        }

  @type currently_playing :: %{
          track: track() | nil,
          is_playing: boolean(),
          progress_ms: integer() | nil,
          timestamp: integer(),
          context: context() | nil,
          device: device() | nil
        }

  @type playback_state :: %{
          device: device() | nil,
          repeat_state: String.t(),
          shuffle_state: boolean(),
          is_playing: boolean(),
          timestamp: integer(),
          progress_ms: integer() | nil,
          item: track() | nil
        }

  @type playback_action :: :play | :pause | :next | :previous
  @type search_type :: String.t()
  @type api_error :: :no_auth_token | :no_track_playing | :no_active_device | term()

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
  @spec get_current_user() :: {:ok, user()} | {:error, api_error()}
  def get_current_user do
    Cache.fetch(
      :spotify,
      "current_user",
      fn ->
        case make_request(:get, "/me") do
          {:ok, %{body: user_data}} ->
            parse_user(user_data)

          {:error, reason} ->
            {:error, reason}
        end
      end,
      ttl: 300_000
    )
    |> case do
      {:error, _} = error -> error
      user -> {:ok, user}
    end
  end

  # Playback

  @doc """
  Gets the currently playing track.
  """
  @spec get_currently_playing() :: {:ok, currently_playing()} | {:error, api_error()}
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
  @spec get_playback_state() :: {:ok, playback_state()} | {:error, api_error()}
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
  @spec control_playback(playback_action()) :: :ok | {:error, api_error()}
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
  @spec set_volume(0..100) :: :ok | {:error, api_error()}
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
  @spec get_user_playlists(pos_integer()) :: {:ok, [playlist()]} | {:error, api_error()}
  def get_user_playlists(limit \\ 20) do
    Cache.fetch(
      :spotify,
      "user_playlists_#{limit}",
      fn ->
        case make_request(:get, "/me/playlists?limit=#{limit}") do
          {:ok, %{body: %{"items" => playlists_data}}} ->
            Enum.map(playlists_data, &parse_playlist/1)

          {:error, reason} ->
            {:error, reason}
        end
      end,
      ttl: 600_000
    )
    |> case do
      {:error, _} = error -> error
      playlists -> {:ok, playlists}
    end
  end

  @doc """
  Gets tracks from a specific playlist.
  """
  @spec get_playlist_tracks(String.t(), pos_integer()) :: {:ok, [track()]} | {:error, api_error()}
  def get_playlist_tracks(playlist_id, limit \\ 50) do
    Cache.fetch(
      :spotify,
      "playlist_tracks_#{playlist_id}_#{limit}",
      fn ->
        endpoint = "/playlists/#{playlist_id}/tracks?limit=#{limit}"

        case make_request(:get, endpoint) do
          {:ok, %{body: %{"items" => tracks_data}}} ->
            Enum.map(tracks_data, fn item -> parse_track(item["track"]) end)

          {:error, reason} ->
            {:error, reason}
        end
      end,
      ttl: 300_000
    )
    |> case do
      {:error, _} = error -> error
      tracks -> {:ok, tracks}
    end
  end

  # Search

  @doc """
  Searches for tracks, artists, albums, or playlists.
  """
  @spec search(String.t(), search_type(), pos_integer()) :: {:ok, [map()]} | {:error, api_error()}
  def search(query, type \\ "track", limit \\ 20) do
    Cache.fetch(
      :spotify,
      "search_#{query}_#{type}_#{limit}",
      fn ->
        encoded_query = URI.encode(query)
        endpoint = "/search?q=#{encoded_query}&type=#{type}&limit=#{limit}"

        case make_request(:get, endpoint) do
          {:ok, %{body: results}} ->
            parse_search_results(results, type)

          {:error, reason} ->
            {:error, reason}
        end
      end,
      ttl: 600_000
    )
    |> case do
      {:error, _} = error -> error
      results -> {:ok, results}
    end
  end

  # Device Management

  @doc """
  Gets the user's available devices.
  """
  @spec get_devices() :: {:ok, [device()]} | {:error, api_error()}
  def get_devices do
    Cache.fetch(
      :spotify,
      "devices",
      fn ->
        case make_request(:get, "/me/player/devices") do
          {:ok, %{body: %{"devices" => devices_data}}} ->
            Enum.map(devices_data, &parse_device/1)

          {:error, reason} ->
            {:error, reason}
        end
      end,
      ttl: 180_000
    )
    |> case do
      {:error, _} = error -> error
      devices -> {:ok, devices}
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
