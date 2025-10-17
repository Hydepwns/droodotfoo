defmodule Droodotfoo.Fileverse.Portal.ActivityTracker do
  @moduledoc """
  Real-time activity tracking for Portal P2P collaboration.

  Handles:
  - Peer activity monitoring
  - File transfer events
  - Connection events
  - Activity feed generation
  - Real-time updates via PubSub
  - Activity persistence and cleanup

  Integrates with Presence, Transfer, and Notifications modules.
  """

  require Logger

  @type activity_type ::
          :peer_joined
          | :peer_left
          | :file_shared
          | :file_downloaded
          | :transfer_started
          | :transfer_progress
          | :transfer_completed
          | :connection_established
          | :connection_lost
          | :encryption_enabled
          | :portal_created
          | :portal_destroyed

  @type activity_event :: %{
          id: String.t(),
          type: activity_type(),
          peer_id: String.t(),
          portal_id: String.t(),
          timestamp: DateTime.t(),
          metadata: map(),
          severity: :info | :warning | :error
        }

  @type activity_feed :: %{
          portal_id: String.t(),
          events: [activity_event()],
          total_events: integer(),
          last_activity: DateTime.t() | nil,
          active_peers: integer()
        }

  @doc """
  Track a new activity event.

  ## Parameters

  - `type`: Type of activity
  - `peer_id`: ID of the peer performing the activity
  - `portal_id`: Portal ID (required)
  - `opts`: Keyword list of options
    - `:metadata` - Additional event metadata
    - `:severity` - Event severity (default: :info)

  ## Examples

      iex> ActivityTracker.track(:peer_joined, "peer_123", "portal_abc", metadata: %{wallet: "0x..."})
      {:ok, %{id: "activity_123", type: :peer_joined, ...}}

  """
  @spec track(activity_type(), String.t(), String.t(), keyword()) ::
          {:ok, activity_event()} | {:error, atom()}
  def track(type, peer_id, portal_id, opts \\ []) do
    metadata = Keyword.get(opts, :metadata, %{})
    severity = Keyword.get(opts, :severity, :info)

    event = %{
      id: generate_activity_id(),
      type: type,
      peer_id: peer_id,
      portal_id: portal_id,
      timestamp: DateTime.utc_now(),
      metadata: metadata,
      severity: severity
    }

    # Broadcast activity via PubSub
    Phoenix.PubSub.broadcast(
      Droodotfoo.PubSub,
      "portal:#{portal_id}:activity",
      {:activity, event}
    )

    # Also broadcast to global portal activity
    Phoenix.PubSub.broadcast(
      Droodotfoo.PubSub,
      "portal:activity",
      {:activity, event}
    )

    # Log activity
    Logger.info("Portal activity: #{type} by #{peer_id} in #{portal_id}")

    {:ok, event}
  end

  @doc """
  Get activity feed for a portal.

  ## Parameters

  - `portal_id`: Portal identifier
  - `opts`: Keyword list of options
    - `:limit` - Maximum number of events (default: 20)
    - `:since` - Only events since this timestamp
    - `:severity` - Filter by severity level
    - `:peer_id` - Filter by specific peer

  ## Examples

      iex> ActivityTracker.get_feed("portal_abc", limit: 10, severity: :info)
      {:ok, %{portal_id: "portal_abc", events: [...], ...}}

  """
  @spec get_feed(String.t(), keyword()) :: {:ok, activity_feed()} | {:error, atom()}
  def get_feed(portal_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    since = Keyword.get(opts, :since)
    severity = Keyword.get(opts, :severity)
    peer_id = Keyword.get(opts, :peer_id)

    # Mock implementation - in production would query from database/cache
    events = get_mock_activity_events(portal_id, limit, since, severity, peer_id)

    feed = %{
      portal_id: portal_id,
      events: events,
      total_events: length(events),
      last_activity: get_last_activity_timestamp(events),
      active_peers: get_active_peer_count(portal_id)
    }

    {:ok, feed}
  end

  @doc """
  Get recent activity for a specific peer.

  ## Parameters

  - `peer_id`: Peer identifier
  - `portal_id`: Portal identifier (optional)
  - `opts`: Keyword list of options
    - `:limit` - Maximum number of events (default: 10)

  ## Examples

      iex> ActivityTracker.get_peer_activity("peer_123", "portal_abc", limit: 5)
      {:ok, [%{id: "activity_123", type: :file_shared, ...}, ...]}

  """
  @spec get_peer_activity(String.t(), String.t() | nil, keyword()) ::
          {:ok, [activity_event()]} | {:error, atom()}
  def get_peer_activity(peer_id, portal_id \\ nil, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    # Mock implementation
    events = get_mock_peer_activity(peer_id, portal_id, limit)
    {:ok, events}
  end

  @doc """
  Get activity statistics for a portal.

  ## Parameters

  - `portal_id`: Portal identifier
  - `opts`: Keyword list of options
    - `:timeframe` - Timeframe for statistics (default: :last_24h)
    - `:group_by` - Group statistics by field (default: :type)

  ## Examples

      iex> ActivityTracker.get_stats("portal_abc", timeframe: :last_hour)
      {:ok, %{total_events: 15, by_type: %{peer_joined: 3, file_shared: 8, ...}}}

  """
  @spec get_stats(String.t(), keyword()) :: {:ok, map()} | {:error, atom()}
  def get_stats(_portal_id, opts \\ []) do
    timeframe = Keyword.get(opts, :timeframe, :last_24h)
    _group_by = Keyword.get(opts, :group_by, :type)

    # Mock implementation
    stats = %{
      total_events: 25,
      timeframe: timeframe,
      by_type: %{
        peer_joined: 5,
        file_shared: 8,
        transfer_completed: 10,
        connection_lost: 2
      },
      by_severity: %{
        info: 20,
        warning: 4,
        error: 1
      },
      by_peer: %{
        "peer_123" => 10,
        "peer_456" => 8,
        "peer_789" => 7
      }
    }

    {:ok, stats}
  end

  @doc """
  Clean up old activity events.

  ## Parameters

  - `portal_id`: Portal identifier (optional, cleans all if nil)
  - `opts`: Keyword list of options
    - `:older_than` - Delete events older than this duration (default: 30 days)
    - `:keep_errors` - Keep error events (default: true)

  ## Examples

      iex> ActivityTracker.cleanup("portal_abc", older_than: 7 * 24 * 3600)
      {:ok, 50}  # Number of events cleaned up

  """
  @spec cleanup(String.t() | nil, keyword()) :: {:ok, integer()} | {:error, atom()}
  def cleanup(portal_id \\ nil, opts \\ []) do
    # 30 days in seconds
    older_than = Keyword.get(opts, :older_than, 30 * 24 * 3600)
    _keep_errors = Keyword.get(opts, :keep_errors, true)

    # Mock implementation
    cleaned_count =
      if portal_id do
        Logger.info("Cleaning up activity for portal #{portal_id} older than #{older_than}s")
        25
      else
        Logger.info("Cleaning up all activity older than #{older_than}s")
        50
      end

    {:ok, cleaned_count}
  end

  # Helper functions

  defp generate_activity_id do
    ("activity_" <> :crypto.strong_rand_bytes(8)) |> Base.encode64(padding: false)
  end

  defp get_mock_activity_events(portal_id, limit, since, severity, peer_id) do
    base_events = [
      %{
        id: "activity_1",
        type: :peer_joined,
        peer_id: "peer_123",
        portal_id: portal_id,
        timestamp: DateTime.add(DateTime.utc_now(), -300, :second),
        metadata: %{wallet: "0x1234...5678", ens_name: "alice.eth"},
        severity: :info
      },
      %{
        id: "activity_2",
        type: :file_shared,
        peer_id: "peer_456",
        portal_id: portal_id,
        timestamp: DateTime.add(DateTime.utc_now(), -600, :second),
        metadata: %{filename: "document.pdf", size: 1024 * 1024},
        severity: :info
      },
      %{
        id: "activity_3",
        type: :transfer_completed,
        peer_id: "peer_123",
        portal_id: portal_id,
        timestamp: DateTime.add(DateTime.utc_now(), -900, :second),
        metadata: %{filename: "image.jpg", size: 512 * 1024, duration: 30},
        severity: :info
      },
      %{
        id: "activity_4",
        type: :connection_lost,
        peer_id: "peer_789",
        portal_id: portal_id,
        timestamp: DateTime.add(DateTime.utc_now(), -1200, :second),
        metadata: %{reason: "network_timeout", duration: 3600},
        severity: :warning
      }
    ]

    # Apply filters
    filtered =
      base_events
      |> filter_by_timestamp(since)
      |> filter_by_severity(severity)
      |> filter_by_peer(peer_id)
      |> Enum.take(limit)

    filtered
  end

  defp get_mock_peer_activity(peer_id, portal_id, limit) do
    # Mock implementation for peer-specific activity
    [
      %{
        id: "peer_activity_1",
        type: :file_shared,
        peer_id: peer_id,
        portal_id: portal_id || "portal_abc",
        timestamp: DateTime.add(DateTime.utc_now(), -300, :second),
        metadata: %{filename: "document.pdf"},
        severity: :info
      }
    ]
    |> Enum.take(limit)
  end

  defp get_last_activity_timestamp([]) do
    nil
  end

  defp get_last_activity_timestamp(events) do
    events
    |> Enum.map(& &1.timestamp)
    |> Enum.max(DateTime)
  end

  defp get_active_peer_count(_portal_id) do
    # Mock implementation - would get from Presence module
    3
  end

  defp filter_by_timestamp(events, nil) do
    events
  end

  defp filter_by_timestamp(events, since) do
    Enum.filter(events, fn event ->
      DateTime.compare(event.timestamp, since) == :gt
    end)
  end

  defp filter_by_severity(events, nil) do
    events
  end

  defp filter_by_severity(events, severity) do
    Enum.filter(events, fn event -> event.severity == severity end)
  end

  defp filter_by_peer(events, nil) do
    events
  end

  defp filter_by_peer(events, peer_id) do
    Enum.filter(events, fn event -> event.peer_id == peer_id end)
  end
end
