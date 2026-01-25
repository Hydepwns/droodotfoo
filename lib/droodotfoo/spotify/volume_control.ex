defmodule Droodotfoo.Spotify.VolumeControl do
  @moduledoc """
  Volume calculation helpers for Spotify playback.
  """

  @step 10
  @min_volume 0
  @max_volume 100
  @default_volume 50

  @doc """
  Extract current volume from playback state.
  Returns default volume if state is nil or missing volume data.
  """
  @spec get_current_volume(map() | nil) :: non_neg_integer()
  def get_current_volume(%{device: %{"volume_percent" => vol}}) when is_integer(vol), do: vol
  def get_current_volume(_), do: @default_volume

  @doc """
  Calculate new volume after adjustment.
  Clamps result between 0 and 100.
  """
  @spec calculate_new_volume(non_neg_integer(), :up | :down) :: non_neg_integer()
  def calculate_new_volume(current, :up), do: min(current + @step, @max_volume)
  def calculate_new_volume(current, :down), do: max(current - @step, @min_volume)

  @doc """
  Get new volume from playback state and direction in one call.
  """
  @spec adjust(map() | nil, :up | :down) :: non_neg_integer()
  def adjust(playback_state, direction) do
    playback_state
    |> get_current_volume()
    |> calculate_new_volume(direction)
  end
end
