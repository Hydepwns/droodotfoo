defmodule Droodotfoo.Spotify.PlaybackController do
  @moduledoc """
  Playback control operations for Spotify.
  Wraps API calls with standardized error handling.
  """

  require Logger

  alias Droodotfoo.Spotify.API

  @type playback_action :: :play | :pause | :next | :previous
  @type result :: :ok | {:error, term()}

  @doc """
  Execute a playback control action.
  """
  @spec execute(playback_action()) :: result()
  def execute(action) when action in [:play, :pause, :next, :previous] do
    case API.control_playback(action) do
      :ok ->
        :ok

      {:error, reason} = error ->
        Logger.error("Failed to control playback (#{action}): #{inspect(reason)}")
        error
    end
  end

  @doc """
  Set volume to a specific level (0-100).
  """
  @spec set_volume(non_neg_integer()) :: result()
  def set_volume(volume) when volume >= 0 and volume <= 100 do
    case API.set_volume(volume) do
      :ok ->
        :ok

      {:error, reason} = error ->
        Logger.error("Failed to set volume to #{volume}: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Determine the toggle action based on current playback state.
  Returns :pause if playing, :play otherwise.
  """
  @spec toggle_action(map() | nil) :: :play | :pause
  def toggle_action(%{is_playing: true}), do: :pause
  def toggle_action(_), do: :play
end
