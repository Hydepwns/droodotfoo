defmodule Droodotfoo.Spotify do
  @moduledoc """
  GenServer for Spotify integration state management and API orchestration.

  Responsibilities:
  - Manage Spotify OAuth authentication flow
  - Track current playback state and user information
  - Orchestrate API calls to Spotify Web API
  - Provide periodic updates (5-second intervals)
  - Cache user data (playlists, current user, playback)

  ## Authentication Flow

  1. Call `start_auth/0` to get authorization URL
  2. User visits URL and authorizes app
  3. Call `complete_auth/1` with authorization code
  4. System automatically fetches initial data and starts periodic updates

  ## Auto-refresh

  When authenticated, playback state refreshes every 5 seconds automatically.
  Manual refresh available via `refresh_now_playing/0`.

  ## Examples

      # Start authentication
      {:ok, url} = Droodotfoo.Spotify.start_auth()
      # User visits URL...

      # Complete with authorization code
      :ok = Droodotfoo.Spotify.complete_auth("code_from_callback")

      # Control playback
      :ok = Droodotfoo.Spotify.play_pause()
      :ok = Droodotfoo.Spotify.next_track()

      # Get state
      track = Droodotfoo.Spotify.current_track()
      playlists = Droodotfoo.Spotify.playlists()

  """

  use GenServer
  require Logger

  alias Droodotfoo.Spotify.{Auth, DataRefresher, PlaybackController, VolumeControl}

  defstruct [
    :auth_state,
    :current_user,
    :current_track,
    :playback_state,
    :playlists,
    :last_update,
    :loading,
    :last_error
  ]

  # Type definitions

  @type auth_state :: :not_authenticated | :pending | :authenticated
  @type user :: map() | nil
  @type track :: map() | nil
  @type playback :: map() | nil
  @type playlist :: map()
  @type playback_action :: :play | :pause | :next | :previous
  @type volume_direction :: :up | :down
  @type error_reason :: String.t() | atom()

  ## Client API

  @doc """
  Start the Spotify GenServer.

  Automatically schedules periodic playback updates (every 5 seconds).

  ## Examples

      iex> {:ok, pid} = Droodotfoo.Spotify.start_link()
      iex> Process.alive?(pid)
      true

  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Initiates the Spotify OAuth flow.

  Returns the authorization URL that users should visit in their browser
  to grant app permissions.

  ## Returns

  - `{:ok, url}` - Authorization URL for user to visit
  - `{:error, reason}` - Failed to generate URL

  ## Examples

      iex> {:ok, url} = Droodotfoo.Spotify.start_auth()
      iex> String.starts_with?(url, "https://accounts.spotify.com")
      true

  """
  @spec start_auth() :: {:ok, String.t()} | {:error, error_reason()}
  def start_auth do
    GenServer.call(__MODULE__, :start_auth)
  end

  @doc """
  Completes the OAuth flow with the authorization code.

  Call this after user authorizes app and you receive the callback code.
  Automatically fetches initial user data (profile, playlists, playback).

  ## Parameters

  - `code`: Authorization code from OAuth callback

  ## Examples

      iex> Droodotfoo.Spotify.complete_auth("AQD...")
      :ok

  """
  @spec complete_auth(String.t()) :: :ok | {:error, error_reason()}
  def complete_auth(code) do
    GenServer.call(__MODULE__, {:complete_auth, code})
  end

  @doc """
  Gets the current authentication status.

  ## Returns

  - `:not_authenticated` - No user logged in
  - `:pending` - Authorization URL generated, waiting for callback
  - `:authenticated` - User successfully authenticated

  ## Examples

      iex> Droodotfoo.Spotify.auth_status()
      :not_authenticated

  """
  @spec auth_status() :: auth_state()
  def auth_status do
    GenServer.call(__MODULE__, :auth_status)
  end

  @doc """
  Gets the current user information.

  Returns user profile data including display name, email, and Spotify URI.

  ## Examples

      iex> user = Droodotfoo.Spotify.current_user()
      iex> is_map(user)
      true

  """
  @spec current_user() :: user()
  def current_user do
    GenServer.call(__MODULE__, :current_user)
  end

  @doc """
  Gets the currently playing track.

  Returns track metadata including name, artist, album, and duration.
  Returns `nil` if nothing is playing.

  ## Examples

      iex> track = Droodotfoo.Spotify.current_track()
      iex> is_map(track) or is_nil(track)
      true

  """
  @spec current_track() :: track()
  def current_track do
    GenServer.call(__MODULE__, :current_track)
  end

  @doc """
  Gets the current playback state.

  Returns playback information including: is_playing, progress, device, volume.

  ## Examples

      iex> state = Droodotfoo.Spotify.playback_state()
      iex> is_map(state) or is_nil(state)
      true

  """
  @spec playback_state() :: playback()
  def playback_state do
    GenServer.call(__MODULE__, :playback_state)
  end

  @doc """
  Gets user playlists.

  Returns list of playlist objects with metadata (name, owner, track count).

  ## Examples

      iex> playlists = Droodotfoo.Spotify.playlists()
      iex> is_list(playlists)
      true

  """
  @spec playlists() :: [playlist()]
  def playlists do
    GenServer.call(__MODULE__, :playlists)
  end

  @doc """
  Refreshes current playing information immediately.

  Triggers an out-of-band update of playback state and current track.
  Useful after user actions that might change playback.

  ## Examples

      iex> Droodotfoo.Spotify.refresh_now_playing()
      :ok

  """
  @spec refresh_now_playing() :: :ok
  def refresh_now_playing do
    GenServer.cast(__MODULE__, :refresh_now_playing)
  end

  @doc """
  Controls playback with the specified action.

  ## Parameters

  - `action`: One of `:play`, `:pause`, `:next`, `:previous`

  ## Returns

  - `:ok` - Action successful
  - `{:error, :not_authenticated}` - User not logged in
  - `{:error, reason}` - API call failed

  ## Examples

      iex> Droodotfoo.Spotify.control_playback(:play)
      :ok

      iex> Droodotfoo.Spotify.control_playback(:next)
      :ok

  """
  @spec control_playback(playback_action()) :: :ok | {:error, error_reason()}
  def control_playback(action) when action in [:play, :pause, :next, :previous] do
    GenServer.call(__MODULE__, {:control_playback, action})
  end

  @doc """
  Toggles play/pause based on current playback state.

  Pauses if currently playing, plays if currently paused.
  Convenience wrapper around `control_playback/1`.

  ## Examples

      iex> Droodotfoo.Spotify.play_pause()
      :ok

  """
  @spec play_pause() :: :ok | {:error, error_reason()}
  def play_pause do
    playback_state()
    |> PlaybackController.toggle_action()
    |> control_playback()
  end

  @doc """
  Skips to the next track.

  Convenience wrapper around `control_playback(:next)`.

  ## Examples

      iex> Droodotfoo.Spotify.next_track()
      :ok

  """
  @spec next_track() :: :ok | {:error, error_reason()}
  def next_track do
    control_playback(:next)
  end

  @doc """
  Skips to the previous track.

  Convenience wrapper around `control_playback(:previous)`.

  ## Examples

      iex> Droodotfoo.Spotify.previous_track()
      :ok

  """
  @spec previous_track() :: :ok | {:error, error_reason()}
  def previous_track do
    control_playback(:previous)
  end

  @doc """
  Adjusts volume up or down by 10%.

  ## Parameters

  - `direction`: Either `:up` or `:down`

  Volume is clamped between 0 and 100.

  ## Examples

      iex> Droodotfoo.Spotify.adjust_volume(:up)
      :ok

      iex> Droodotfoo.Spotify.adjust_volume(:down)
      :ok

  """
  @spec adjust_volume(volume_direction()) :: :ok | {:error, error_reason()}
  def adjust_volume(direction) when direction in [:up, :down] do
    GenServer.call(__MODULE__, {:adjust_volume, direction})
  end

  @doc """
  Gets loading state.

  Returns `true` if background data fetching is in progress.

  ## Examples

      iex> Droodotfoo.Spotify.loading?()
      false

  """
  @spec loading?() :: boolean()
  def loading? do
    GenServer.call(__MODULE__, :loading)
  end

  @doc """
  Gets last error if any.

  Returns error from most recent API call failure, or `nil` if none.

  ## Examples

      iex> error = Droodotfoo.Spotify.last_error()
      iex> is_nil(error) or is_binary(error)
      true

  """
  @spec last_error() :: String.t() | nil
  def last_error do
    GenServer.call(__MODULE__, :last_error)
  end

  ## Server Callbacks

  # Server Callbacks

  @impl true
  def init(_opts) do
    # Schedule periodic updates
    schedule_periodic_update()

    state = %__MODULE__{
      auth_state: :not_authenticated,
      current_user: nil,
      current_track: nil,
      playback_state: nil,
      playlists: [],
      last_update: nil,
      loading: false,
      last_error: nil
    }

    {:ok, state}
  end

  @impl true
  def handle_call(:start_auth, _from, state) do
    case Auth.get_authorization_url() do
      {:ok, url} ->
        new_state = %{state | auth_state: :pending}
        {:reply, {:ok, url}, new_state}

      {:error, reason} ->
        Logger.error("Failed to start Spotify auth: #{inspect(reason)}")
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:complete_auth, code}, _from, state) do
    case Auth.exchange_code_for_tokens(code) do
      {:ok, _tokens} ->
        spawn(fn -> DataRefresher.fetch_initial_data() end)
        new_state = %{state | auth_state: :authenticated}
        {:reply, :ok, new_state}

      {:error, reason} ->
        Logger.error("Failed to complete Spotify auth: #{inspect(reason)}")
        new_state = %{state | auth_state: :not_authenticated}
        {:reply, {:error, reason}, new_state}
    end
  end

  @impl true
  def handle_call(:auth_status, _from, state) do
    {:reply, state.auth_state, state}
  end

  @impl true
  def handle_call(:current_user, _from, state) do
    {:reply, state.current_user, state}
  end

  @impl true
  def handle_call(:current_track, _from, state) do
    {:reply, state.current_track, state}
  end

  @impl true
  def handle_call(:playback_state, _from, state) do
    {:reply, state.playback_state, state}
  end

  @impl true
  def handle_call(:playlists, _from, state) do
    {:reply, state.playlists, state}
  end

  @impl true
  def handle_call(:loading, _from, state) do
    {:reply, state.loading, state}
  end

  @impl true
  def handle_call(:last_error, _from, state) do
    {:reply, state.last_error, state}
  end

  @impl true
  def handle_call({:control_playback, action}, _from, state) do
    if state.auth_state == :authenticated do
      case PlaybackController.execute(action) do
        :ok ->
          spawn(fn -> DataRefresher.refresh_playback() end)
          {:reply, :ok, state}

        {:error, _reason} = error ->
          {:reply, error, state}
      end
    else
      {:reply, {:error, :not_authenticated}, state}
    end
  end

  @impl true
  def handle_call({:adjust_volume, direction}, _from, state) do
    if state.auth_state == :authenticated do
      new_volume = VolumeControl.adjust(state.playback_state, direction)

      case PlaybackController.set_volume(new_volume) do
        :ok ->
          spawn(fn -> DataRefresher.refresh_playback() end)
          {:reply, :ok, state}

        {:error, _reason} = error ->
          {:reply, error, state}
      end
    else
      {:reply, {:error, :not_authenticated}, state}
    end
  end

  @impl true
  def handle_cast(:refresh_now_playing, state) do
    if state.auth_state == :authenticated do
      spawn(fn -> DataRefresher.refresh_playback() end)
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:update_current_track, track}, state) do
    new_state = %{state | current_track: track, last_update: DateTime.utc_now()}
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_playback_state, playback}, state) do
    new_state = %{state | playback_state: playback, last_update: DateTime.utc_now()}
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_user, user}, state) do
    new_state = %{state | current_user: user}
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_playlists, playlists}, state) do
    new_state = %{state | playlists: playlists}
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:periodic_update, state) do
    if state.auth_state == :authenticated do
      spawn(fn -> DataRefresher.refresh_playback() end)
    end

    schedule_periodic_update()
    {:noreply, state}
  end

  # Private Functions

  defp schedule_periodic_update do
    Process.send_after(self(), :periodic_update, 5_000)
  end
end
