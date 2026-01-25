defmodule Droodotfoo.Spotify.DataRefresher do
  @moduledoc """
  Async data fetching for Spotify state updates.
  Fetches data from Spotify API and sends results back to the GenServer.
  """

  require Logger

  alias Droodotfoo.Spotify.API

  @doc """
  Fetch initial data (user, playlists, playback) and send updates to GenServer.
  Called after successful authentication.
  """
  @spec fetch_initial_data(module()) :: :ok
  def fetch_initial_data(server \\ Droodotfoo.Spotify) do
    fetch_user(server)
    fetch_playlists(server)
    fetch_playback(server)
    :ok
  end

  @doc """
  Refresh playback data (current track and playback state).
  Called periodically and after playback actions.
  """
  @spec refresh_playback(module()) :: :ok
  def refresh_playback(server \\ Droodotfoo.Spotify) do
    fetch_playback(server)
    :ok
  end

  # Private fetchers

  defp fetch_user(server) do
    case API.get_current_user() do
      {:ok, user} ->
        GenServer.cast(server, {:update_user, user})

      {:error, reason} ->
        Logger.error("Failed to fetch user data: #{inspect(reason)}")
    end
  end

  defp fetch_playlists(server) do
    case API.get_user_playlists() do
      {:ok, playlists} ->
        GenServer.cast(server, {:update_playlists, playlists})

      {:error, reason} ->
        Logger.error("Failed to fetch playlists: #{inspect(reason)}")
    end
  end

  defp fetch_playback(server) do
    fetch_current_track(server)
    fetch_playback_state(server)
  end

  defp fetch_current_track(server) do
    case API.get_currently_playing() do
      {:ok, track} ->
        GenServer.cast(server, {:update_current_track, track})

      {:error, reason} ->
        Logger.debug("No currently playing track: #{inspect(reason)}")
        GenServer.cast(server, {:update_current_track, nil})
    end
  end

  defp fetch_playback_state(server) do
    case API.get_playback_state() do
      {:ok, playback} ->
        GenServer.cast(server, {:update_playback_state, playback})

      {:error, reason} ->
        Logger.debug("No playback state: #{inspect(reason)}")
        GenServer.cast(server, {:update_playback_state, nil})
    end
  end
end
