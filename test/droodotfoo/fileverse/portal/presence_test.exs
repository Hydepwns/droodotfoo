defmodule Droodotfoo.Fileverse.Portal.PresenceTest do
  use ExUnit.Case, async: false

  alias Droodotfoo.Fileverse.Portal.Presence

  setup do
    # Clean up ETS table before each test
    :ets.delete_all_objects(:portal_presence)
    :ok
  end

  describe "track_peer/3" do
    test "tracks a peer with valid parameters" do
      portal_id = "portal_abc"
      peer_id = "peer_123"
      opts = [wallet_address: "0x1234567890abcdef1234567890abcdef12345678"]

      assert {:ok, presence} = Presence.track_peer(portal_id, peer_id, opts)

      assert presence.peer_id == peer_id
      assert presence.wallet_address == "0x1234567890abcdef1234567890abcdef12345678"
      assert presence.portal_id == portal_id
      assert presence.connection_state == :connecting
      assert presence.activity_status == :active
      assert presence.connection_quality == :good
      assert is_struct(presence.last_seen, DateTime)
      assert is_list(presence.data_channels)
      assert is_map(presence.metadata)
    end

    test "returns error when wallet_address is missing" do
      portal_id = "portal_abc"
      peer_id = "peer_123"
      opts = []

      assert {:error, :wallet_required} = Presence.track_peer(portal_id, peer_id, opts)
    end

    test "tracks peer with custom options" do
      portal_id = "portal_abc"
      peer_id = "peer_123"

      opts = [
        wallet_address: "0x1234567890abcdef1234567890abcdef12345678",
        ens_name: "alice.eth",
        connection_state: :connected,
        metadata: %{is_host: true}
      ]

      assert {:ok, presence} = Presence.track_peer(portal_id, peer_id, opts)

      assert presence.ens_name == "alice.eth"
      assert presence.connection_state == :connected
      assert presence.metadata.is_host == true
    end
  end

  describe "update_peer/3" do
    test "updates peer presence" do
      portal_id = "portal_abc"
      peer_id = "peer_123"

      # First track the peer
      {:ok, _presence} =
        Presence.track_peer(portal_id, peer_id,
          wallet_address: "0x1234567890abcdef1234567890abcdef12345678"
        )

      # Update the peer
      updates = %{connection_state: :connected, activity_status: :idle}
      assert {:ok, updated_presence} = Presence.update_peer(portal_id, peer_id, updates)

      assert updated_presence.connection_state == :connected
      assert updated_presence.activity_status == :idle
    end

    test "returns error for non-existent peer" do
      portal_id = "portal_abc"
      peer_id = "nonexistent"
      updates = %{connection_state: :connected}

      assert {:error, :peer_not_found} = Presence.update_peer(portal_id, peer_id, updates)
    end
  end

  describe "untrack_peer/2" do
    test "removes peer from presence" do
      portal_id = "portal_abc"
      peer_id = "peer_123"

      # First track the peer
      {:ok, _presence} =
        Presence.track_peer(portal_id, peer_id,
          wallet_address: "0x1234567890abcdef1234567890abcdef12345678"
        )

      # Remove the peer
      assert :ok = Presence.untrack_peer(portal_id, peer_id)

      # Verify peer is gone
      assert {:error, :peer_not_found} = Presence.get_peer(portal_id, peer_id)
    end

    test "returns error for non-existent peer" do
      portal_id = "portal_abc"
      peer_id = "nonexistent"

      assert {:error, :peer_not_found} = Presence.untrack_peer(portal_id, peer_id)
    end
  end

  describe "get_portal_peers/1" do
    test "returns all peers in a portal" do
      portal_id = "portal_abc"

      # Track multiple peers
      {:ok, _presence1} =
        Presence.track_peer(portal_id, "peer_1",
          wallet_address: "0x1111111111111111111111111111111111111111"
        )

      {:ok, _presence2} =
        Presence.track_peer(portal_id, "peer_2",
          wallet_address: "0x2222222222222222222222222222222222222222"
        )

      assert {:ok, peers} = Presence.get_portal_peers(portal_id)
      assert length(peers) == 2
      assert Enum.any?(peers, &(&1.peer_id == "peer_1"))
      assert Enum.any?(peers, &(&1.peer_id == "peer_2"))
    end

    test "returns empty list for portal with no peers" do
      portal_id = "empty_portal"

      assert {:ok, peers} = Presence.get_portal_peers(portal_id)
      assert peers == []
    end
  end

  describe "get_peer/2" do
    test "returns specific peer presence" do
      portal_id = "portal_abc"
      peer_id = "peer_123"

      {:ok, _presence} =
        Presence.track_peer(portal_id, peer_id,
          wallet_address: "0x1234567890abcdef1234567890abcdef12345678"
        )

      assert {:ok, presence} = Presence.get_peer(portal_id, peer_id)
      assert presence.peer_id == peer_id
    end

    test "returns error for non-existent peer" do
      portal_id = "portal_abc"
      peer_id = "nonexistent"

      assert {:error, :peer_not_found} = Presence.get_peer(portal_id, peer_id)
    end
  end

  describe "get_portal_presence/1" do
    test "returns portal presence summary" do
      portal_id = "portal_abc"

      # Track multiple peers
      {:ok, _presence1} =
        Presence.track_peer(portal_id, "peer_1",
          wallet_address: "0x1111111111111111111111111111111111111111"
        )

      {:ok, _presence2} =
        Presence.track_peer(portal_id, "peer_2",
          wallet_address: "0x2222222222222222222222222222222222222222"
        )

      assert {:ok, presence} = Presence.get_portal_presence(portal_id)
      assert presence.portal_id == portal_id
      assert presence.peer_count == 2
      assert length(presence.active_peers) == 2
      assert is_struct(presence.last_activity, DateTime)
      assert is_map(presence.connection_stats)
      assert presence.connection_stats.total_peers == 2
    end
  end

  describe "update_activity/3" do
    test "updates peer activity status" do
      portal_id = "portal_abc"
      peer_id = "peer_123"

      {:ok, _presence} =
        Presence.track_peer(portal_id, peer_id,
          wallet_address: "0x1234567890abcdef1234567890abcdef12345678"
        )

      assert {:ok, presence} = Presence.update_activity(portal_id, peer_id, :idle)
      assert presence.activity_status == :idle
    end
  end

  describe "update_connection_quality/3" do
    test "updates peer connection quality" do
      portal_id = "portal_abc"
      peer_id = "peer_123"

      {:ok, _presence} =
        Presence.track_peer(portal_id, peer_id,
          wallet_address: "0x1234567890abcdef1234567890abcdef12345678"
        )

      assert {:ok, presence} = Presence.update_connection_quality(portal_id, peer_id, :excellent)
      assert presence.connection_quality == :excellent
    end
  end

  describe "add_data_channel/3" do
    test "adds data channel to peer" do
      portal_id = "portal_abc"
      peer_id = "peer_123"

      {:ok, _presence} =
        Presence.track_peer(portal_id, peer_id,
          wallet_address: "0x1234567890abcdef1234567890abcdef12345678"
        )

      assert {:ok, presence} = Presence.add_data_channel(portal_id, peer_id, "file-transfer")
      assert "file-transfer" in presence.data_channels
    end

    test "prevents duplicate data channels" do
      portal_id = "portal_abc"
      peer_id = "peer_123"

      {:ok, _presence} =
        Presence.track_peer(portal_id, peer_id,
          wallet_address: "0x1234567890abcdef1234567890abcdef12345678"
        )

      # Add same channel twice
      {:ok, _presence1} = Presence.add_data_channel(portal_id, peer_id, "file-transfer")
      {:ok, presence2} = Presence.add_data_channel(portal_id, peer_id, "file-transfer")

      # Should only appear once
      assert Enum.count(presence2.data_channels, &(&1 == "file-transfer")) == 1
    end
  end

  describe "remove_data_channel/3" do
    test "removes data channel from peer" do
      portal_id = "portal_abc"
      peer_id = "peer_123"

      {:ok, _presence} =
        Presence.track_peer(portal_id, peer_id,
          wallet_address: "0x1234567890abcdef1234567890abcdef12345678"
        )

      # Add channel first
      {:ok, _presence} = Presence.add_data_channel(portal_id, peer_id, "file-transfer")

      # Remove channel
      assert {:ok, presence} = Presence.remove_data_channel(portal_id, peer_id, "file-transfer")
      assert "file-transfer" not in presence.data_channels
    end
  end

  describe "get_peers_by_state/2" do
    test "filters peers by connection state" do
      portal_id = "portal_abc"

      # Track peers with different states
      {:ok, _presence1} =
        Presence.track_peer(portal_id, "peer_1",
          wallet_address: "0x1111111111111111111111111111111111111111"
        )

      {:ok, _presence2} =
        Presence.track_peer(portal_id, "peer_2",
          wallet_address: "0x2222222222222222222222222222222222222222"
        )

      # Update one to connected
      Presence.update_peer(portal_id, "peer_1", %{connection_state: :connected})

      # Get connected peers
      assert {:ok, connected_peers} = Presence.get_peers_by_state(portal_id, :connected)
      assert length(connected_peers) == 1
      assert hd(connected_peers).peer_id == "peer_1"
    end
  end

  describe "get_active_peers/1" do
    test "returns only active peers" do
      portal_id = "portal_abc"

      # Track peers with different activity
      {:ok, _presence1} =
        Presence.track_peer(portal_id, "peer_1",
          wallet_address: "0x1111111111111111111111111111111111111111"
        )

      {:ok, _presence2} =
        Presence.track_peer(portal_id, "peer_2",
          wallet_address: "0x2222222222222222222222222222222222222222"
        )

      # Update one to idle
      Presence.update_peer(portal_id, "peer_1", %{activity_status: :idle})

      # Get active peers
      assert {:ok, active_peers} = Presence.get_active_peers(portal_id)
      assert length(active_peers) == 1
      assert hd(active_peers).peer_id == "peer_2"
    end
  end
end
