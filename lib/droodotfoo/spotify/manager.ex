defmodule Droodotfoo.Spotify.Manager do
  @moduledoc """
  Spotify API manager for handling authentication and API calls.
  Provides high-level functions for Spotify integration.
  """

  require Logger
  alias Droodotfoo.Spotify.Auth

  @doc """
  Completes the OAuth authentication flow with the authorization code.
  Returns :ok on success or {:error, reason} on failure.
  """
  def complete_auth(code) do
    case Auth.exchange_code_for_tokens(code) do
      {:ok, _tokens} ->
        Logger.info("Spotify authentication completed successfully")
        :ok

      {:error, reason} ->
        Logger.error("Failed to complete Spotify authentication: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Gets the current user's profile information.
  """
  def get_current_user do
    with {:ok, access_token} <- Auth.get_access_token() do
      make_api_request("GET", "/v1/me", access_token)
    end
  end

  @doc """
  Gets the current user's playlists.
  """
  def get_user_playlists(limit \\ 20, offset \\ 0) do
    with {:ok, access_token} <- Auth.get_access_token() do
      params = %{
        limit: limit,
        offset: offset
      }

      make_api_request("GET", "/v1/me/playlists", access_token, params)
    end
  end

  @doc """
  Gets the user's currently playing track.
  """
  def get_currently_playing do
    with {:ok, access_token} <- Auth.get_access_token() do
      make_api_request("GET", "/v1/me/player/currently-playing", access_token)
    end
  end

  @doc """
  Gets the user's playback state.
  """
  def get_playback_state do
    with {:ok, access_token} <- Auth.get_access_token() do
      make_api_request("GET", "/v1/me/player", access_token)
    end
  end

  @doc """
  Starts or resumes playback.
  """
  def start_playback(device_id \\ nil) do
    with {:ok, access_token} <- Auth.get_access_token() do
      body = if device_id, do: %{device_id: device_id}, else: %{}
      make_api_request("PUT", "/v1/me/player/play", access_token, body)
    end
  end

  @doc """
  Pauses playback.
  """
  def pause_playback(device_id \\ nil) do
    with {:ok, access_token} <- Auth.get_access_token() do
      params = if device_id, do: %{device_id: device_id}, else: %{}
      make_api_request("PUT", "/v1/me/player/pause", access_token, params)
    end
  end

  @doc """
  Skips to next track.
  """
  def next_track(device_id \\ nil) do
    with {:ok, access_token} <- Auth.get_access_token() do
      params = if device_id, do: %{device_id: device_id}, else: %{}
      make_api_request("POST", "/v1/me/player/next", access_token, params)
    end
  end

  @doc """
  Skips to previous track.
  """
  def previous_track(device_id \\ nil) do
    with {:ok, access_token} <- Auth.get_access_token() do
      params = if device_id, do: %{device_id: device_id}, else: %{}
      make_api_request("POST", "/v1/me/player/previous", access_token, params)
    end
  end

  @doc """
  Sets the playback volume.
  """
  def set_volume(volume_percent, device_id \\ nil) do
    with {:ok, access_token} <- Auth.get_access_token() do
      params = %{volume_percent: volume_percent}
      params = if device_id, do: Map.put(params, :device_id, device_id), else: params

      make_api_request("PUT", "/v1/me/player/volume", access_token, params)
    end
  end

  @doc """
  Gets available devices.
  """
  def get_devices do
    with {:ok, access_token} <- Auth.get_access_token() do
      make_api_request("GET", "/v1/me/player/devices", access_token)
    end
  end

  @doc """
  Searches for tracks, artists, albums, or playlists.
  """
  def search(query, types \\ ["track"], limit \\ 20, offset \\ 0) do
    with {:ok, access_token} <- Auth.get_access_token() do
      params = %{
        q: query,
        type: Enum.join(types, ","),
        limit: limit,
        offset: offset
      }

      make_api_request("GET", "/v1/search", access_token, params)
    end
  end

  # Private helper functions

  defp make_api_request(method, endpoint, access_token, params_or_body \\ %{}) do
    url = "https://api.spotify.com#{endpoint}"

    headers = [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"}
    ]

    case method do
      "GET" ->
        make_get_request(url, headers, params_or_body)

      "POST" ->
        make_post_request(url, headers, params_or_body)

      "PUT" ->
        make_put_request(url, headers, params_or_body)

      _ ->
        {:error, :unsupported_method}
    end
  end

  defp make_get_request(url, headers, params) do
    url_with_params = add_query_params(url, params)

    case Req.get(url_with_params, headers: headers) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: status_code, body: body}} ->
        Logger.error("Spotify API error: #{status_code} - #{inspect(body)}")
        {:error, {:api_error, status_code, body}}

      {:error, reason} ->
        Logger.error("HTTP request failed: #{inspect(reason)}")
        {:error, :request_failed}
    end
  end

  defp make_post_request(url, headers, body) do
    case Req.post(url, json: body, headers: headers) do
      {:ok, %Req.Response{status: status_code, body: response_body}}
      when status_code in 200..299 ->
        if response_body == "" or response_body == %{} do
          :ok
        else
          {:ok, response_body}
        end

      {:ok, %Req.Response{status: status_code, body: body}} ->
        Logger.error("Spotify API error: #{status_code} - #{inspect(body)}")
        {:error, {:api_error, status_code, body}}

      {:error, reason} ->
        Logger.error("HTTP request failed: #{inspect(reason)}")
        {:error, :request_failed}
    end
  end

  defp make_put_request(url, headers, body) do
    case Req.put(url, json: body, headers: headers) do
      {:ok, %Req.Response{status: status_code}} when status_code in 200..299 ->
        :ok

      {:ok, %Req.Response{status: status_code, body: body}} ->
        Logger.error("Spotify API error: #{status_code} - #{inspect(body)}")
        {:error, {:api_error, status_code, body}}

      {:error, reason} ->
        Logger.error("HTTP request failed: #{inspect(reason)}")
        {:error, :request_failed}
    end
  end

  defp add_query_params(url, params) when map_size(params) == 0 do
    url
  end

  defp add_query_params(url, params) do
    query_string =
      Enum.map_join(params, "&", fn {key, value} -> "#{key}=#{URI.encode_www_form("#{value}")}" end)

    "#{url}?#{query_string}"
  end
end
