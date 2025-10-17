defmodule Droodotfoo.Fileverse.Portal.PresenceServer do
  @moduledoc """
  GenServer for managing Portal presence state.

  Handles:
  - Peer presence storage and retrieval
  - Portal state management
  - Connection state tracking
  - Activity monitoring
  - Cleanup of stale connections
  - State persistence

  Uses ETS tables for fast lookups and state management.
  """

  use GenServer
  require Logger

  @type state :: %{
          portals: %{String.t() => %{peers: %{String.t() => map()}, last_activity: DateTime.t()}},
          cleanup_timer: reference() | nil
        }

  # Client API

  @doc """
  Start the presence server.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Track a peer in a portal.
  """
  def track_peer(portal_id, presence) do
    GenServer.call(__MODULE__, {:track_peer, portal_id, presence})
  end

  @doc """
  Update peer presence.
  """
  def update_peer(portal_id, presence) do
    GenServer.call(__MODULE__, {:update_peer, portal_id, presence})
  end

  @doc """
  Remove peer from portal.
  """
  def untrack_peer(portal_id, peer_id) do
    GenServer.call(__MODULE__, {:untrack_peer, portal_id, peer_id})
  end

  @doc """
  Get peer presence.
  """
  def get_peer(portal_id, peer_id) do
    GenServer.call(__MODULE__, {:get_peer, portal_id, peer_id})
  end

  @doc """
  Get all peers in a portal.
  """
  def get_portal_peers(portal_id) do
    GenServer.call(__MODULE__, {:get_portal_peers, portal_id})
  end

  @doc """
  Get portal state.
  """
  def get_portal_state(portal_id) do
    GenServer.call(__MODULE__, {:get_portal_state, portal_id})
  end

  @doc """
  Clean up stale connections.
  """
  def cleanup_stale_connections do
    GenServer.cast(__MODULE__, :cleanup_stale_connections)
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    # Create ETS table for presence data
    :ets.new(:portal_presence, [:set, :public, :named_table])

    # Start cleanup timer
    cleanup_timer = schedule_cleanup()

    state = %{
      portals: %{},
      cleanup_timer: cleanup_timer
    }

    Logger.info("Portal PresenceServer started")
    {:ok, state}
  end

  @impl true
  def handle_call({:track_peer, portal_id, presence}, _from, state) do
    # Store in ETS for fast lookups
    :ets.insert(:portal_presence, {{portal_id, presence.peer_id}, presence})

    # Update state
    updated_state = update_portal_state(state, portal_id, presence)

    {:reply, presence, updated_state}
  end

  @impl true
  def handle_call({:update_peer, portal_id, presence}, _from, state) do
    # Update in ETS
    :ets.insert(:portal_presence, {{portal_id, presence.peer_id}, presence})

    # Update state
    updated_state = update_portal_state(state, portal_id, presence)

    {:reply, presence, updated_state}
  end

  @impl true
  def handle_call({:untrack_peer, portal_id, peer_id}, _from, state) do
    # Remove from ETS
    :ets.delete(:portal_presence, {portal_id, peer_id})

    # Update state
    updated_state = remove_peer_from_state(state, portal_id, peer_id)

    {:reply, :ok, updated_state}
  end

  @impl true
  def handle_call({:get_peer, portal_id, peer_id}, _from, state) do
    case :ets.lookup(:portal_presence, {portal_id, peer_id}) do
      [{_, presence}] -> {:reply, presence, state}
      [] -> {:reply, nil, state}
    end
  end

  @impl true
  def handle_call({:get_portal_peers, portal_id}, _from, state) do
    # Get all peers for this portal from ETS
    peers =
      :ets.match_object(:portal_presence, {{portal_id, :_}, :_})
      |> Enum.map(fn {_, presence} -> presence end)

    {:reply, peers, state}
  end

  @impl true
  def handle_call({:get_portal_state, portal_id}, _from, state) do
    portal_state =
      Map.get(state.portals, portal_id, %{peers: %{}, last_activity: DateTime.utc_now()})

    {:reply, portal_state, state}
  end

  @impl true
  def handle_cast(:cleanup_stale_connections, state) do
    # Clean up connections older than 5 minutes
    cutoff_time = DateTime.add(DateTime.utc_now(), -300, :second)

    # Get all entries and filter by last_seen timestamp
    all_entries = :ets.tab2list(:portal_presence)

    stale_connections =
      Enum.filter(all_entries, fn {{_portal_id, _peer_id}, presence} ->
        case presence do
          %{last_seen: last_seen} when is_struct(last_seen, DateTime) ->
            DateTime.compare(last_seen, cutoff_time) == :lt

          _ ->
            false
        end
      end)

    # Remove stale connections
    Enum.each(stale_connections, fn {{portal_id, peer_id}, _presence} ->
      :ets.delete(:portal_presence, {portal_id, peer_id})
      Logger.info("Cleaned up stale connection: #{peer_id} in portal #{portal_id}")
    end)

    # Schedule next cleanup
    cleanup_timer = schedule_cleanup()
    updated_state = %{state | cleanup_timer: cleanup_timer}

    {:noreply, updated_state}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_stale_connections()
    {:noreply, state}
  end

  # Private helper functions

  defp update_portal_state(state, portal_id, presence) do
    portal_state =
      Map.get(state.portals, portal_id, %{peers: %{}, last_activity: DateTime.utc_now()})

    updated_peers = Map.put(portal_state.peers, presence.peer_id, presence)

    updated_portal_state = %{
      portal_state
      | peers: updated_peers,
        last_activity: DateTime.utc_now()
    }

    updated_portals = Map.put(state.portals, portal_id, updated_portal_state)
    %{state | portals: updated_portals}
  end

  defp remove_peer_from_state(state, portal_id, peer_id) do
    portal_state =
      Map.get(state.portals, portal_id, %{peers: %{}, last_activity: DateTime.utc_now()})

    updated_peers = Map.delete(portal_state.peers, peer_id)

    updated_portal_state = %{
      portal_state
      | peers: updated_peers,
        last_activity: DateTime.utc_now()
    }

    updated_portals = Map.put(state.portals, portal_id, updated_portal_state)
    %{state | portals: updated_portals}
  end

  defp schedule_cleanup do
    # Schedule cleanup every 2 minutes
    Process.send_after(self(), :cleanup, 120_000)
  end
end
