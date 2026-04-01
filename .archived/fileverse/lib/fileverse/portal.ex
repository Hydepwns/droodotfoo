defmodule Droodotfoo.Fileverse.Portal do
  @moduledoc """
  Fileverse Portal integration for P2P file sharing and real-time collaboration.

  Provides terminal interface for creating/joining Portal spaces (rooms),
  managing peers, and sharing files directly between wallets using WebRTC.

  Note: Full implementation requires Fileverse Portal SDK/API
  and LiveView hooks for WebRTC/P2P communication.

  This module has been refactored into focused submodules:
  - Lifecycle - Portal management (create, join, leave, list, get)
  - Peers - Peer management (presence, activity, state updates)
  - FileSharing - P2P file sharing operations
  - UI - Enhanced UI integration (status, notifications, activity feed, formatting)
  - Helpers - Utility functions (ID generation, time formatting, mock data)
  """

  alias Droodotfoo.Fileverse.Portal.{FileSharing, Lifecycle, Peers, UI}

  @type portal :: %{
          id: String.t(),
          name: String.t(),
          creator: String.t(),
          created_at: DateTime.t(),
          peers: [peer()],
          files_shared: integer(),
          encrypted: boolean(),
          public: boolean()
        }

  @type peer :: %{
          address: String.t(),
          ens_name: String.t() | nil,
          connection_status: :connected | :connecting | :disconnected,
          joined_at: DateTime.t(),
          is_host: boolean()
        }

  @type file_share :: %{
          id: String.t(),
          filename: String.t(),
          size: integer(),
          sender: String.t(),
          recipients: [String.t()],
          transfer_status: :pending | :transferring | :complete | :failed,
          progress: float()
        }

  # Portal Lifecycle Functions

  @doc """
  Create a new Portal space.

  See `Droodotfoo.Fileverse.Portal.Lifecycle.create/2` for details.
  """
  @spec create(String.t(), keyword()) :: {:ok, portal()} | {:error, atom()}
  def create(name, opts \\ []) do
    Lifecycle.create(name, opts)
  end

  @doc """
  Join an existing Portal space.

  See `Droodotfoo.Fileverse.Portal.Lifecycle.join/2` for details.
  """
  @spec join(String.t(), keyword()) :: {:ok, portal()} | {:error, atom()}
  def join(portal_id, opts \\ []) do
    Lifecycle.join(portal_id, opts)
  end

  @doc """
  List available Portal spaces for a wallet.

  See `Droodotfoo.Fileverse.Portal.Lifecycle.list/1` for details.
  """
  @spec list(String.t()) :: {:ok, [portal()]} | {:error, atom()}
  def list(wallet_address) do
    Lifecycle.list(wallet_address)
  end

  @doc """
  Get Portal details by ID.

  See `Droodotfoo.Fileverse.Portal.Lifecycle.get/1` for details.
  """
  @spec get(String.t()) :: {:ok, portal()} | {:error, atom()}
  def get(portal_id) do
    Lifecycle.get(portal_id)
  end

  @doc """
  Leave a Portal space.

  See `Droodotfoo.Fileverse.Portal.Lifecycle.leave/2` for details.
  """
  @spec leave(String.t(), keyword()) :: :ok | {:error, atom()}
  def leave(portal_id, opts \\ []) do
    Lifecycle.leave(portal_id, opts)
  end

  # File Sharing Functions

  @doc """
  Share a file with Portal members via P2P.

  See `Droodotfoo.Fileverse.Portal.FileSharing.share/3` for details.
  """
  @spec share_file(String.t(), String.t(), keyword()) :: {:ok, file_share()} | {:error, atom()}
  def share_file(portal_id, file_path, opts \\ []) do
    FileSharing.share(portal_id, file_path, opts)
  end

  # Peer Management Functions

  @doc """
  Get list of active peers in a Portal.

  See `Droodotfoo.Fileverse.Portal.Peers.list/1` for details.
  """
  @spec peers(String.t()) :: {:ok, [peer()]} | {:error, atom()}
  def peers(portal_id) do
    Peers.list(portal_id)
  end

  @doc """
  Get real-time peer presence for a Portal.

  See `Droodotfoo.Fileverse.Portal.Peers.presence/1` for details.
  """
  @spec presence(String.t()) :: {:ok, map()} | {:error, atom()}
  def presence(portal_id) do
    Peers.presence(portal_id)
  end

  @doc """
  Get active peers in a Portal.

  See `Droodotfoo.Fileverse.Portal.Peers.active/1` for details.
  """
  @spec active_peers(String.t()) :: {:ok, [map()]} | {:error, atom()}
  def active_peers(portal_id) do
    Peers.active(portal_id)
  end

  @doc """
  Update peer connection state.

  See `Droodotfoo.Fileverse.Portal.Peers.update_state/3` for details.
  """
  @spec update_peer_state(String.t(), String.t(), atom()) :: {:ok, map()} | {:error, atom()}
  def update_peer_state(portal_id, peer_id, connection_state) do
    Peers.update_state(portal_id, peer_id, connection_state)
  end

  @doc """
  Update peer activity status.

  See `Droodotfoo.Fileverse.Portal.Peers.update_activity/3` for details.
  """
  @spec update_peer_activity(String.t(), String.t(), atom()) :: {:ok, map()} | {:error, atom()}
  def update_peer_activity(portal_id, peer_id, activity_status) do
    Peers.update_activity(portal_id, peer_id, activity_status)
  end

  # UI Integration Functions

  @doc """
  Format portal list for terminal display.

  See `Droodotfoo.Fileverse.Portal.UI.format_portal_list/1` for details.
  """
  @spec format_portal_list([portal()]) :: String.t()
  def format_portal_list(portals) do
    UI.format_portal_list(portals)
  end

  @doc """
  Get enhanced connection status for Portal UI.

  See `Droodotfoo.Fileverse.Portal.UI.get_enhanced_status/2` for details.
  """
  @spec get_enhanced_status(String.t(), keyword()) :: {:ok, map()} | {:error, atom()}
  def get_enhanced_status(portal_id, opts \\ []) do
    UI.get_enhanced_status(portal_id, opts)
  end

  @doc """
  Get real-time notifications for Portal UI.

  See `Droodotfoo.Fileverse.Portal.UI.get_notifications/2` for details.
  """
  @spec get_notifications(String.t(), keyword()) :: {:ok, [map()]} | {:error, atom()}
  def get_notifications(portal_id, opts \\ []) do
    UI.get_notifications(portal_id, opts)
  end

  @doc """
  Get real-time activity feed for Portal UI.

  See `Droodotfoo.Fileverse.Portal.UI.get_activity_feed/2` for details.
  """
  @spec get_activity_feed(String.t(), keyword()) :: {:ok, map()} | {:error, atom()}
  def get_activity_feed(portal_id, opts \\ []) do
    UI.get_activity_feed(portal_id, opts)
  end

  @doc """
  Get transfer progress for Portal UI.

  See `Droodotfoo.Fileverse.Portal.UI.get_transfer_progress/2` for details.
  """
  @spec get_transfer_progress(String.t(), keyword()) :: {:ok, [map()]} | {:error, atom()}
  def get_transfer_progress(portal_id, opts \\ []) do
    UI.get_transfer_progress(portal_id, opts)
  end

  @doc """
  Create a notification for Portal events.

  See `Droodotfoo.Fileverse.Portal.UI.create_notification/5` for details.
  """
  @spec create_notification(atom(), String.t(), String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, atom()}
  def create_notification(type, title, message, portal_id, opts \\ []) do
    UI.create_notification(type, title, message, portal_id, opts)
  end

  @doc """
  Track activity for Portal events.

  See `Droodotfoo.Fileverse.Portal.UI.track_activity/4` for details.
  """
  @spec track_activity(atom(), String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, atom()}
  def track_activity(type, peer_id, portal_id, opts \\ []) do
    UI.track_activity(type, peer_id, portal_id, opts)
  end
end
