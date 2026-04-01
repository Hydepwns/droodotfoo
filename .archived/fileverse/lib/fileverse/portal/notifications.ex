defmodule Droodotfoo.Fileverse.Portal.Notifications do
  @moduledoc """
  Real-time notification system for Portal P2P collaboration.

  Handles:
  - Peer join/leave notifications
  - File transfer progress updates
  - Connection status changes
  - Activity feed management
  - Notification persistence and cleanup
  - Real-time UI updates

  Uses Phoenix.PubSub for distributed notifications
  and GenServer for state management.
  """

  require Logger

  @type notification_type ::
          :peer_joined
          | :peer_left
          | :file_shared
          | :transfer_started
          | :transfer_progress
          | :transfer_completed
          | :transfer_failed
          | :connection_established
          | :connection_lost
          | :encryption_enabled

  @type notification :: %{
          id: String.t(),
          type: notification_type(),
          title: String.t(),
          message: String.t(),
          peer_id: String.t() | nil,
          portal_id: String.t(),
          timestamp: DateTime.t(),
          read: boolean(),
          priority: :low | :normal | :high | :urgent
        }

  @type notification_state :: %{
          notifications: [notification()],
          max_notifications: integer(),
          auto_cleanup_interval: integer(),
          last_cleanup: DateTime.t()
        }

  @doc """
  Create a new notification.

  ## Parameters

  - `type`: Type of notification
  - `title`: Short title for the notification
  - `message`: Detailed message
  - `opts`: Keyword list of options
    - `:peer_id` - ID of the peer involved
    - `:portal_id` - Portal ID (required)
    - `:priority` - Notification priority (default: :normal)
    - `:read` - Whether notification is read (default: false)

  ## Examples

      iex> Notifications.create(:peer_joined, "Peer Joined", "0x1234...5678 joined the portal", portal_id: "portal_abc")
      {:ok, %{id: "notif_123", type: :peer_joined, ...}}

  """
  @spec create(notification_type(), String.t(), String.t(), keyword()) ::
          {:ok, notification()} | {:error, atom()}
  def create(type, title, message, opts \\ []) do
    portal_id = Keyword.get(opts, :portal_id)
    peer_id = Keyword.get(opts, :peer_id)
    priority = Keyword.get(opts, :priority, :normal)
    read = Keyword.get(opts, :read, false)

    if portal_id do
      notification = %{
        id: generate_notification_id(),
        type: type,
        title: title,
        message: message,
        peer_id: peer_id,
        portal_id: portal_id,
        timestamp: DateTime.utc_now(),
        read: read,
        priority: priority
      }

      # Broadcast notification via PubSub
      Phoenix.PubSub.broadcast(
        Droodotfoo.PubSub,
        "portal:#{portal_id}:notifications",
        {:notification, notification}
      )

      # Also broadcast to global portal notifications
      Phoenix.PubSub.broadcast(
        Droodotfoo.PubSub,
        "portal:notifications",
        {:notification, notification}
      )

      {:ok, notification}
    else
      {:error, :portal_id_required}
    end
  end

  @doc """
  Get recent notifications for a portal.

  ## Parameters

  - `portal_id`: Portal identifier
  - `opts`: Keyword list of options
    - `:limit` - Maximum number of notifications (default: 10)
    - `:unread_only` - Only return unread notifications (default: false)
    - `:priority` - Filter by priority level

  ## Examples

      iex> Notifications.get_recent("portal_abc", limit: 5, unread_only: true)
      {:ok, [%{id: "notif_123", ...}, ...]}

  """
  @spec get_recent(String.t(), keyword()) :: {:ok, [notification()]} | {:error, atom()}
  def get_recent(portal_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)
    unread_only = Keyword.get(opts, :unread_only, false)
    priority = Keyword.get(opts, :priority)

    # Mock implementation - in production would query from database/cache
    notifications = get_mock_notifications(portal_id, limit, unread_only, priority)
    {:ok, notifications}
  end

  @doc """
  Mark notification as read.

  ## Parameters

  - `notification_id`: ID of the notification to mark as read

  ## Examples

      iex> Notifications.mark_read("notif_123")
      :ok

  """
  @spec mark_read(String.t()) :: :ok | {:error, atom()}
  def mark_read(notification_id) do
    # Mock implementation - in production would update database
    Logger.info("Marking notification #{notification_id} as read")
    :ok
  end

  @doc """
  Mark all notifications as read for a portal.

  ## Parameters

  - `portal_id`: Portal identifier

  ## Examples

      iex> Notifications.mark_all_read("portal_abc")
      :ok

  """
  @spec mark_all_read(String.t()) :: :ok | {:error, atom()}
  def mark_all_read(portal_id) do
    # Mock implementation - in production would update database
    Logger.info("Marking all notifications as read for portal #{portal_id}")
    :ok
  end

  @doc """
  Get notification statistics for a portal.

  ## Parameters

  - `portal_id`: Portal identifier

  ## Examples

      iex> Notifications.get_stats("portal_abc")
      {:ok, %{total: 25, unread: 3, by_type: %{peer_joined: 5, ...}}}

  """
  @spec get_stats(String.t()) :: {:ok, map()} | {:error, atom()}
  def get_stats(_portal_id) do
    # Mock implementation
    stats = %{
      total: 25,
      unread: 3,
      by_type: %{
        peer_joined: 5,
        file_shared: 8,
        transfer_completed: 10,
        connection_lost: 2
      },
      by_priority: %{
        low: 15,
        normal: 8,
        high: 2,
        urgent: 0
      }
    }

    {:ok, stats}
  end

  @doc """
  Clean up old notifications.

  ## Parameters

  - `portal_id`: Portal identifier (optional, cleans all if nil)
  - `opts`: Keyword list of options
    - `:older_than` - Delete notifications older than this duration (default: 7 days)
    - `:keep_unread` - Keep unread notifications (default: true)

  ## Examples

      iex> Notifications.cleanup("portal_abc", older_than: 3 * 24 * 3600)
      {:ok, 15}  # Number of notifications cleaned up

  """
  @spec cleanup(String.t() | nil, keyword()) :: {:ok, integer()} | {:error, atom()}
  def cleanup(portal_id \\ nil, opts \\ []) do
    # 7 days in seconds
    older_than = Keyword.get(opts, :older_than, 7 * 24 * 3600)
    _keep_unread = Keyword.get(opts, :keep_unread, true)

    # Mock implementation
    cleaned_count =
      if portal_id do
        Logger.info("Cleaning up notifications for portal #{portal_id} older than #{older_than}s")
        5
      else
        Logger.info("Cleaning up all notifications older than #{older_than}s")
        15
      end

    {:ok, cleaned_count}
  end

  # Helper functions

  defp generate_notification_id do
    ("notif_" <> :crypto.strong_rand_bytes(8)) |> Base.encode64(padding: false)
  end

  defp get_mock_notifications(portal_id, limit, unread_only, priority) do
    base_notifications = [
      %{
        id: "notif_1",
        type: :peer_joined,
        title: "Peer Joined",
        message: "0x1234...5678 joined the portal",
        peer_id: "peer_123",
        portal_id: portal_id,
        timestamp: DateTime.add(DateTime.utc_now(), -300, :second),
        read: false,
        priority: :normal
      },
      %{
        id: "notif_2",
        type: :file_shared,
        title: "File Shared",
        message: "document.pdf shared by 0xabcd...efgh",
        peer_id: "peer_456",
        portal_id: portal_id,
        timestamp: DateTime.add(DateTime.utc_now(), -600, :second),
        read: true,
        priority: :normal
      },
      %{
        id: "notif_3",
        type: :transfer_completed,
        title: "Transfer Completed",
        message: "image.jpg transfer completed successfully",
        peer_id: "peer_123",
        portal_id: portal_id,
        timestamp: DateTime.add(DateTime.utc_now(), -900, :second),
        read: false,
        priority: :low
      },
      %{
        id: "notif_4",
        type: :connection_lost,
        title: "Connection Lost",
        message: "Lost connection to 0x9876...5432",
        peer_id: "peer_789",
        portal_id: portal_id,
        timestamp: DateTime.add(DateTime.utc_now(), -1200, :second),
        read: false,
        priority: :high
      }
    ]

    # Apply filters
    filtered =
      base_notifications
      |> filter_by_read_status(unread_only)
      |> filter_by_priority(priority)
      |> Enum.take(limit)

    filtered
  end

  defp filter_by_read_status(notifications, true) do
    Enum.filter(notifications, fn n -> not n.read end)
  end

  defp filter_by_read_status(notifications, false) do
    notifications
  end

  defp filter_by_priority(notifications, nil) do
    notifications
  end

  defp filter_by_priority(notifications, priority) do
    Enum.filter(notifications, fn n -> n.priority == priority end)
  end
end
