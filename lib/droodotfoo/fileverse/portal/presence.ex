defmodule Droodotfoo.Fileverse.Portal.Presence do
  @moduledoc """
  Real-time peer presence tracking for Portal P2P collaboration.

  Handles:
  - Peer join/leave events
  - Connection state tracking
  - Activity monitoring
  - Presence synchronization
  - Portal state management
  - Real-time notifications

  Uses Phoenix.PubSub for distributed presence tracking
  and GenServer for state management.
  """

  require Logger

  alias Droodotfoo.Fileverse.Portal.PresenceServer

  @type peer_presence :: %{
          peer_id: String.t(),
          wallet_address: String.t(),
          ens_name: String.t() | nil,
          connection_state: :connected | :connecting | :disconnected,
          last_seen: DateTime.t(),
          portal_id: String.t(),
          data_channels: [String.t()],
          connection_quality: :excellent | :good | :fair | :poor,
          activity_status: :active | :idle | :away,
          metadata: map()
        }

  @type portal_presence :: %{
          portal_id: String.t(),
          peer_count: integer(),
          active_peers: [peer_presence()],
          last_activity: DateTime.t(),
          connection_stats: map()
        }

  @doc """
  Track peer presence in a portal.

  ## Parameters

  - `portal_id`: Portal identifier
  - `peer_id`: Unique peer identifier
  - `opts`: Keyword list of options
    - `:wallet_address` - Peer's wallet address (required)
    - `:ens_name` - ENS name if available
    - `:connection_state` - Current connection state (default: :connecting)
    - `:metadata` - Additional peer metadata

  ## Examples

      iex> Presence.track_peer("portal_abc", "peer_123", wallet_address: "0x...")
      {:ok, %{peer_id: "peer_123", state: :connecting, ...}}

  """
  @spec track_peer(String.t(), String.t(), keyword()) :: {:ok, peer_presence()} | {:error, atom()}
  def track_peer(portal_id, peer_id, opts \\ []) do
    wallet_address = Keyword.get(opts, :wallet_address)
    ens_name = Keyword.get(opts, :ens_name)
    connection_state = Keyword.get(opts, :connection_state, :connecting)
    metadata = Keyword.get(opts, :metadata, %{})

    if is_nil(wallet_address) do
      {:error, :wallet_required}
    else
      presence = %{
        peer_id: peer_id,
        wallet_address: wallet_address,
        ens_name: ens_name,
        connection_state: connection_state,
        last_seen: DateTime.utc_now(),
        portal_id: portal_id,
        data_channels: [],
        connection_quality: :good,
        activity_status: :active,
        metadata: metadata
      }

      # Store presence in GenServer
      PresenceServer.track_peer(portal_id, presence)

      # Broadcast presence update
      Phoenix.PubSub.broadcast(Droodotfoo.PubSub, "portal:#{portal_id}", {:peer_joined, presence})

      Logger.info("Tracked peer #{peer_id} in portal #{portal_id}")
      {:ok, presence}
    end
  end

  @doc """
  Update peer presence state.

  ## Parameters

  - `portal_id`: Portal identifier
  - `peer_id`: Peer identifier
  - `updates`: Map of updates to apply

  ## Examples

      iex> Presence.update_peer("portal_abc", "peer_123", %{connection_state: :connected})
      {:ok, %{peer_id: "peer_123", state: :connected, ...}}

  """
  @spec update_peer(String.t(), String.t(), map()) :: {:ok, peer_presence()} | {:error, atom()}
  def update_peer(portal_id, peer_id, updates) do
    case PresenceServer.get_peer(portal_id, peer_id) do
      nil ->
        {:error, :peer_not_found}

      presence ->
        # Apply updates
        updated_presence = Map.merge(presence, updates)
        updated_presence = %{updated_presence | last_seen: DateTime.utc_now()}

        # Store updated presence
        PresenceServer.update_peer(portal_id, updated_presence)

        # Broadcast update
        Phoenix.PubSub.broadcast(
          Droodotfoo.PubSub,
          "portal:#{portal_id}",
          {:peer_updated, updated_presence}
        )

        Logger.info("Updated peer #{peer_id} in portal #{portal_id}")
        {:ok, updated_presence}
    end
  end

  @doc """
  Remove peer from portal presence.

  ## Parameters

  - `portal_id`: Portal identifier
  - `peer_id`: Peer identifier

  ## Examples

      iex> Presence.untrack_peer("portal_abc", "peer_123")
      :ok

  """
  @spec untrack_peer(String.t(), String.t()) :: :ok | {:error, atom()}
  def untrack_peer(portal_id, peer_id) do
    case PresenceServer.get_peer(portal_id, peer_id) do
      nil ->
        {:error, :peer_not_found}

      presence ->
        # Remove from GenServer
        PresenceServer.untrack_peer(portal_id, peer_id)

        # Broadcast peer left
        Phoenix.PubSub.broadcast(Droodotfoo.PubSub, "portal:#{portal_id}", {:peer_left, presence})

        Logger.info("Untracked peer #{peer_id} from portal #{portal_id}")
        :ok
    end
  end

  @doc """
  Get all peers in a portal.

  ## Parameters

  - `portal_id`: Portal identifier

  ## Examples

      iex> Presence.get_portal_peers("portal_abc")
      {:ok, [%{peer_id: "peer_123", state: :connected, ...}]}

  """
  @spec get_portal_peers(String.t()) :: {:ok, [peer_presence()]} | {:error, atom()}
  def get_portal_peers(portal_id) do
    peers = PresenceServer.get_portal_peers(portal_id)
    {:ok, peers}
  end

  @doc """
  Get specific peer presence.

  ## Parameters

  - `portal_id`: Portal identifier
  - `peer_id`: Peer identifier

  ## Examples

      iex> Presence.get_peer("portal_abc", "peer_123")
      {:ok, %{peer_id: "peer_123", state: :connected, ...}}

  """
  @spec get_peer(String.t(), String.t()) :: {:ok, peer_presence()} | {:error, atom()}
  def get_peer(portal_id, peer_id) do
    case PresenceServer.get_peer(portal_id, peer_id) do
      nil ->
        {:error, :peer_not_found}

      presence ->
        {:ok, presence}
    end
  end

  @doc """
  Get portal presence summary.

  ## Parameters

  - `portal_id`: Portal identifier

  ## Examples

      iex> Presence.get_portal_presence("portal_abc")
      {:ok, %{portal_id: "portal_abc", peer_count: 3, active_peers: [...], ...}}

  """
  @spec get_portal_presence(String.t()) :: {:ok, portal_presence()} | {:error, atom()}
  def get_portal_presence(portal_id) do
    peers = PresenceServer.get_portal_peers(portal_id)

    presence = %{
      portal_id: portal_id,
      peer_count: length(peers),
      active_peers: peers,
      last_activity: DateTime.utc_now(),
      connection_stats: calculate_connection_stats(peers)
    }

    {:ok, presence}
  end

  @doc """
  Update peer activity status.

  ## Parameters

  - `portal_id`: Portal identifier
  - `peer_id`: Peer identifier
  - `activity_status`: New activity status

  ## Examples

      iex> Presence.update_activity("portal_abc", "peer_123", :idle)
      {:ok, %{peer_id: "peer_123", activity_status: :idle, ...}}

  """
  @spec update_activity(String.t(), String.t(), atom()) ::
          {:ok, peer_presence()} | {:error, atom()}
  def update_activity(portal_id, peer_id, activity_status) do
    update_peer(portal_id, peer_id, %{activity_status: activity_status})
  end

  @doc """
  Update peer connection quality.

  ## Parameters

  - `portal_id`: Portal identifier
  - `peer_id`: Peer identifier
  - `quality`: Connection quality rating

  ## Examples

      iex> Presence.update_connection_quality("portal_abc", "peer_123", :excellent)
      {:ok, %{peer_id: "peer_123", connection_quality: :excellent, ...}}

  """
  @spec update_connection_quality(String.t(), String.t(), atom()) ::
          {:ok, peer_presence()} | {:error, atom()}
  def update_connection_quality(portal_id, peer_id, quality) do
    update_peer(portal_id, peer_id, %{connection_quality: quality})
  end

  @doc """
  Add data channel to peer presence.

  ## Parameters

  - `portal_id`: Portal identifier
  - `peer_id`: Peer identifier
  - `channel_name`: Data channel name

  ## Examples

      iex> Presence.add_data_channel("portal_abc", "peer_123", "file-transfer")
      {:ok, %{peer_id: "peer_123", data_channels: ["file-transfer"], ...}}

  """
  @spec add_data_channel(String.t(), String.t(), String.t()) ::
          {:ok, peer_presence()} | {:error, atom()}
  def add_data_channel(portal_id, peer_id, channel_name) do
    case get_peer(portal_id, peer_id) do
      {:ok, presence} ->
        updated_channels = [channel_name | presence.data_channels] |> Enum.uniq()
        update_peer(portal_id, peer_id, %{data_channels: updated_channels})

      error ->
        error
    end
  end

  @doc """
  Remove data channel from peer presence.

  ## Parameters

  - `portal_id`: Portal identifier
  - `peer_id`: Peer identifier
  - `channel_name`: Data channel name

  ## Examples

      iex> Presence.remove_data_channel("portal_abc", "peer_123", "file-transfer")
      {:ok, %{peer_id: "peer_123", data_channels: [], ...}}

  """
  @spec remove_data_channel(String.t(), String.t(), String.t()) ::
          {:ok, peer_presence()} | {:error, atom()}
  def remove_data_channel(portal_id, peer_id, channel_name) do
    case get_peer(portal_id, peer_id) do
      {:ok, presence} ->
        updated_channels = List.delete(presence.data_channels, channel_name)
        update_peer(portal_id, peer_id, %{data_channels: updated_channels})

      error ->
        error
    end
  end

  @doc """
  Get peers by connection state.

  ## Parameters

  - `portal_id`: Portal identifier
  - `state`: Connection state to filter by

  ## Examples

      iex> Presence.get_peers_by_state("portal_abc", :connected)
      {:ok, [%{peer_id: "peer_123", state: :connected, ...}]}

  """
  @spec get_peers_by_state(String.t(), atom()) :: {:ok, [peer_presence()]}
  def get_peers_by_state(portal_id, state) do
    {:ok, peers} = get_portal_peers(portal_id)
    filtered_peers = Enum.filter(peers, &(&1.connection_state == state))
    {:ok, filtered_peers}
  end

  @doc """
  Get active peers (not idle or away).

  ## Parameters

  - `portal_id`: Portal identifier

  ## Examples

      iex> Presence.get_active_peers("portal_abc")
      {:ok, [%{peer_id: "peer_123", activity_status: :active, ...}]}

  """
  @spec get_active_peers(String.t()) :: {:ok, [peer_presence()]}
  def get_active_peers(portal_id) do
    {:ok, peers} = get_portal_peers(portal_id)
    active_peers = Enum.filter(peers, &(&1.activity_status == :active))
    {:ok, active_peers}
  end

  # Private helper functions

  defp calculate_connection_stats(peers) do
    total_peers = length(peers)
    connected_peers = Enum.count(peers, &(&1.connection_state == :connected))
    active_peers = Enum.count(peers, &(&1.activity_status == :active))

    quality_distribution = Enum.frequencies(Enum.map(peers, & &1.connection_quality))

    %{
      total_peers: total_peers,
      connected_peers: connected_peers,
      active_peers: active_peers,
      connection_rate: if(total_peers > 0, do: connected_peers / total_peers, else: 0.0),
      activity_rate: if(total_peers > 0, do: active_peers / total_peers, else: 0.0),
      quality_distribution: quality_distribution
    }
  end
end
