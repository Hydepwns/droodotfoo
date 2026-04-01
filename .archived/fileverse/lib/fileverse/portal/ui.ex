defmodule Droodotfoo.Fileverse.Portal.UI do
  @moduledoc """
  Portal UI integration functions.
  Handles enhanced status, notifications, activity feed, and display formatting.
  """

  alias Droodotfoo.Fileverse.Portal.{
    ActivityTracker,
    Helpers,
    Lifecycle,
    Notifications,
    TransferProgress
  }

  @doc """
  Get enhanced connection status for Portal UI.

  ## Parameters

  - `portal_id`: Portal identifier
  - `opts`: Keyword list of options
    - `:include_stats` - Include detailed statistics (default: true)
    - `:include_transfers` - Include active transfers (default: true)

  ## Examples

      iex> UI.get_enhanced_status("portal_abc")
      {:ok, %{connection: %{status: :connected, ...}, transfers: [...], activity: [...]}}

  """
  @spec get_enhanced_status(String.t(), keyword()) :: {:ok, map()} | {:error, atom()}
  def get_enhanced_status(portal_id, opts \\ []) do
    include_stats = Keyword.get(opts, :include_stats, true)
    include_transfers = Keyword.get(opts, :include_transfers, true)

    # Get basic portal info
    case Lifecycle.get(portal_id) do
      {:ok, portal} ->
        build_enhanced_status(portal, portal_id, include_stats, include_transfers)

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get real-time notifications for Portal UI.

  ## Parameters

  - `portal_id`: Portal identifier
  - `opts`: Keyword list of options
    - `:limit` - Maximum number of notifications (default: 5)
    - `:unread_only` - Only return unread notifications (default: false)

  ## Examples

      iex> UI.get_notifications("portal_abc", limit: 3)
      {:ok, [%{id: "notif_123", type: :peer_joined, ...}, ...]}

  """
  @spec get_notifications(String.t(), keyword()) :: {:ok, [map()]} | {:error, atom()}
  def get_notifications(portal_id, opts \\ []) do
    Notifications.get_recent(portal_id, opts)
  end

  @doc """
  Get real-time activity feed for Portal UI.

  ## Parameters

  - `portal_id`: Portal identifier
  - `opts`: Keyword list of options
    - `:limit` - Maximum number of events (default: 10)
    - `:since` - Only events since this timestamp

  ## Examples

      iex> UI.get_activity_feed("portal_abc", limit: 5)
      {:ok, %{events: [...], total_events: 25, ...}}

  """
  @spec get_activity_feed(String.t(), keyword()) :: {:ok, map()} | {:error, atom()}
  def get_activity_feed(portal_id, opts \\ []) do
    ActivityTracker.get_feed(portal_id, opts)
  end

  @doc """
  Get transfer progress for Portal UI.

  ## Parameters

  - `portal_id`: Portal identifier
  - `opts`: Keyword list of options
    - `:active_only` - Only return active transfers (default: true)

  ## Examples

      iex> UI.get_transfer_progress("portal_abc")
      {:ok, [%{transfer_id: "transfer_123", progress_percentage: 75.5, ...}, ...]}

  """
  @spec get_transfer_progress(String.t(), keyword()) :: {:ok, [map()]} | {:error, atom()}
  def get_transfer_progress(portal_id, opts \\ []) do
    active_only = Keyword.get(opts, :active_only, true)

    case TransferProgress.get_active_transfers(portal_id) do
      {:ok, transfers} ->
        filtered_transfers =
          if active_only do
            Enum.filter(transfers, fn transfer ->
              transfer.status in [:pending, :transferring]
            end)
          else
            transfers
          end

        {:ok, filtered_transfers}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Create a notification for Portal events.

  ## Parameters

  - `type`: Type of notification
  - `title`: Notification title
  - `message`: Notification message
  - `portal_id`: Portal identifier
  - `opts`: Keyword list of options
    - `:peer_id` - Peer ID involved
    - `:priority` - Notification priority

  ## Examples

      iex> UI.create_notification(:peer_joined, "Peer Joined", "0x1234...5678 joined", "portal_abc")
      {:ok, %{id: "notif_123", type: :peer_joined, ...}}

  """
  @spec create_notification(atom(), String.t(), String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, atom()}
  def create_notification(type, title, message, portal_id, opts \\ []) do
    Notifications.create(type, title, message, [portal_id: portal_id] ++ opts)
  end

  @doc """
  Track activity for Portal events.

  ## Parameters

  - `type`: Type of activity
  - `peer_id`: Peer ID performing the activity
  - `portal_id`: Portal identifier
  - `opts`: Keyword list of options
    - `:metadata` - Additional metadata
    - `:severity` - Activity severity

  ## Examples

      iex> UI.track_activity(:file_shared, "peer_123", "portal_abc", metadata: %{filename: "doc.pdf"})
      {:ok, %{id: "activity_123", type: :file_shared, ...}}

  """
  @spec track_activity(atom(), String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, atom()}
  def track_activity(type, peer_id, portal_id, opts \\ []) do
    ActivityTracker.track(type, peer_id, portal_id, opts)
  end

  @doc """
  Format portal list for terminal display.

  ## Examples

      iex> UI.format_portal_list(portals)
      "portal_abc123  Team Collaboration  2 members  12 files  2d ago"

  """
  @spec format_portal_list([map()]) :: String.t()
  def format_portal_list(portals) do
    if Enum.empty?(portals) do
      "No portals found.\n\nCreate one with: :portal create <name>"
    else
      Enum.map_join(portals, "\n", &format_portal_entry/1)
    end
  end

  # Private helper functions

  defp build_enhanced_status(portal, portal_id, include_stats, include_transfers) do
    connection_status = Helpers.get_connection_status(portal_id)
    transfers = get_transfers_if_requested(portal_id, include_transfers)

    case ActivityTracker.get_feed(portal_id, limit: 10) do
      {:ok, activity_feed} ->
        enhanced_status = %{
          portal: portal,
          connection: connection_status,
          transfers: transfers,
          activity: activity_feed.events,
          stats: if(include_stats, do: Helpers.get_portal_stats(portal_id), else: %{})
        }

        {:ok, enhanced_status}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_transfers_if_requested(portal_id, true) do
    case TransferProgress.get_active_transfers(portal_id) do
      {:ok, active_transfers} -> active_transfers
      _ -> []
    end
  end

  defp get_transfers_if_requested(_portal_id, false), do: []

  defp format_portal_entry(portal) do
    peer_count = length(portal.peers)
    time_ago = Helpers.format_relative_time(portal.created_at)
    encrypted_badge = if portal.encrypted, do: " [E2E]", else: ""
    public_badge = if portal.public, do: " [PUBLIC]", else: ""

    """
    Portal: #{portal.name}#{encrypted_badge}#{public_badge}
      ID:      #{portal.id}
      Members: #{peer_count}
      Files:   #{portal.files_shared} shared
      Created: #{time_ago}
    """
  end
end
