defmodule Droodotfoo.Spotify.Manager do
  @moduledoc """
  GenServer for managing Spotify integration state and orchestrating
  authentication, API calls, and data management.
  """

  use GenServer
  require Logger

  alias Droodotfoo.Spotify.{Auth, API}

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

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Initiates the Spotify OAuth flow.
  Returns the authorization URL that users should visit.
  """
  def start_auth do
    GenServer.call(__MODULE__, :start_auth)
  end

  @doc """
  Completes the OAuth flow with the authorization code.
  """
  def complete_auth(code) do
    GenServer.call(__MODULE__, {:complete_auth, code})
  end

  @doc """
  Gets the current authentication status.
  """
  def auth_status do
    GenServer.call(__MODULE__, :auth_status)
  end

  @doc """
  Gets the current user information.
  """
  def current_user do
    GenServer.call(__MODULE__, :current_user)
  end

  @doc """
  Gets the currently playing track.
  """
  def current_track do
    GenServer.call(__MODULE__, :current_track)
  end

  @doc """
  Gets the current playback state.
  """
  def playback_state do
    GenServer.call(__MODULE__, :playback_state)
  end

  @doc """
  Gets user playlists.
  """
  def playlists do
    GenServer.call(__MODULE__, :playlists)
  end

  @doc """
  Refreshes current playing information.
  """
  def refresh_now_playing do
    GenServer.cast(__MODULE__, :refresh_now_playing)
  end

  @doc """
  Controls playback (play, pause, next, previous).
  """
  def control_playback(action) when action in [:play, :pause, :next, :previous] do
    GenServer.call(__MODULE__, {:control_playback, action})
  end

  @doc """
  Toggles play/pause based on current playback state.
  """
  def play_pause do
    playback = playback_state()
    action = case playback do
      %{is_playing: true} -> :pause
      _ -> :play
    end
    control_playback(action)
  end

  @doc """
  Skips to the next track.
  """
  def next_track do
    control_playback(:next)
  end

  @doc """
  Skips to the previous track.
  """
  def previous_track do
    control_playback(:previous)
  end

  @doc """
  Adjusts volume up or down.
  """
  def adjust_volume(direction) when direction in [:up, :down] do
    GenServer.call(__MODULE__, {:adjust_volume, direction})
  end

  @doc """
  Gets loading state.
  """
  def loading? do
    GenServer.call(__MODULE__, :loading)
  end

  @doc """
  Gets last error if any.
  """
  def last_error do
    GenServer.call(__MODULE__, :last_error)
  end

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
        # Fetch initial user data
        spawn(fn -> fetch_initial_data() end)

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
      case API.control_playback(action) do
        :ok ->
          # Refresh playback state after control
          spawn(fn -> refresh_playback_data() end)
          {:reply, :ok, state}

        {:error, reason} ->
          Logger.error("Failed to control playback: #{inspect(reason)}")
          {:reply, {:error, reason}, state}
      end
    else
      {:reply, {:error, :not_authenticated}, state}
    end
  end

  @impl true
  def handle_call({:adjust_volume, direction}, _from, state) do
    if state.auth_state == :authenticated do
      # Get current volume from playback state
      current_volume = case state.playback_state do
        %{device: %{"volume_percent" => vol}} -> vol
        _ -> 50  # Default if unknown
      end

      # Adjust by 10%
      new_volume = case direction do
        :up -> min(current_volume + 10, 100)
        :down -> max(current_volume - 10, 0)
      end

      case API.set_volume(new_volume) do
        :ok ->
          # Refresh playback state after volume change
          spawn(fn -> refresh_playback_data() end)
          {:reply, :ok, state}

        {:error, reason} ->
          Logger.error("Failed to adjust volume: #{inspect(reason)}")
          {:reply, {:error, reason}, state}
      end
    else
      {:reply, {:error, :not_authenticated}, state}
    end
  end

  @impl true
  def handle_cast(:refresh_now_playing, state) do
    if state.auth_state == :authenticated do
      spawn(fn -> refresh_playback_data() end)
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
      spawn(fn -> refresh_playback_data() end)
    end

    schedule_periodic_update()
    {:noreply, state}
  end

  # Private Functions

  defp schedule_periodic_update do
    # Update every 5 seconds when authenticated
    Process.send_after(self(), :periodic_update, 5_000)
  end

  defp fetch_initial_data do
    # Fetch user info
    case API.get_current_user() do
      {:ok, user} ->
        GenServer.cast(__MODULE__, {:update_user, user})

      {:error, reason} ->
        Logger.error("Failed to fetch user data: #{inspect(reason)}")
    end

    # Fetch playlists
    case API.get_user_playlists() do
      {:ok, playlists} ->
        GenServer.cast(__MODULE__, {:update_playlists, playlists})

      {:error, reason} ->
        Logger.error("Failed to fetch playlists: #{inspect(reason)}")
    end

    # Fetch current playback
    refresh_playback_data()
  end

  defp refresh_playback_data do
    # Get currently playing track
    case API.get_currently_playing() do
      {:ok, track} ->
        GenServer.cast(__MODULE__, {:update_current_track, track})

      {:error, reason} ->
        Logger.debug("No currently playing track: #{inspect(reason)}")
        GenServer.cast(__MODULE__, {:update_current_track, nil})
    end

    # Get playback state
    case API.get_playback_state() do
      {:ok, playback} ->
        GenServer.cast(__MODULE__, {:update_playback_state, playback})

      {:error, reason} ->
        Logger.debug("No playback state: #{inspect(reason)}")
        GenServer.cast(__MODULE__, {:update_playback_state, nil})
    end
  end
end
