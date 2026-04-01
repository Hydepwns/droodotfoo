defmodule Droodotfoo.Fileverse.Portal.WebRTCTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Fileverse.Portal.WebRTC

  describe "create_peer_connection/2" do
    test "creates a peer connection with valid parameters" do
      peer_id = "peer_123"

      opts = [
        portal_id: "portal_abc",
        wallet_address: "0x1234567890abcdef1234567890abcdef12345678"
      ]

      assert {:ok, connection} = WebRTC.create_peer_connection(peer_id, opts)

      assert connection.peer_id == peer_id
      assert connection.state == :new
      assert is_binary(connection.id)
      assert is_nil(connection.offer)
      assert is_nil(connection.answer)
      assert connection.ice_candidates == []
      assert connection.data_channels == []
      assert is_struct(connection.created_at, DateTime)
      assert is_struct(connection.last_activity, DateTime)
    end

    test "returns error when portal_id is missing" do
      peer_id = "peer_123"
      opts = [wallet_address: "0x1234567890abcdef1234567890abcdef12345678"]

      assert {:error, :missing_required_params} = WebRTC.create_peer_connection(peer_id, opts)
    end

    test "returns error when wallet_address is missing" do
      peer_id = "peer_123"
      opts = [portal_id: "portal_abc"]

      assert {:error, :missing_required_params} = WebRTC.create_peer_connection(peer_id, opts)
    end
  end

  describe "create_offer/2" do
    test "creates an SDP offer for existing connection" do
      connection_id = "conn_456"
      data_channels = ["file-transfer", "chat"]

      assert {:ok, offer} = WebRTC.create_offer(connection_id, data_channels: data_channels)

      assert offer.type == :offer
      assert is_binary(offer.sdp)
      assert String.contains?(offer.sdp, "v=0")
      assert String.contains?(offer.sdp, "m=application")
    end

    test "returns error for non-existent connection" do
      connection_id = "nonexistent"

      assert {:error, :connection_not_found} = WebRTC.create_offer(connection_id)
    end
  end

  describe "process_answer/2" do
    test "processes a valid SDP answer" do
      connection_id = "conn_456"
      answer = %{type: :answer, sdp: "v=0\r\no=- 9876543210 2 IN IP4 127.0.0.1\r\ns=-\r\nt=0 0"}

      assert {:ok, connection} = WebRTC.process_answer(connection_id, answer)

      assert connection.answer == answer
      assert connection.state == :connected
    end

    test "returns error for invalid SDP answer" do
      connection_id = "conn_456"
      invalid_answer = %{type: :answer, sdp: "invalid sdp"}

      assert {:error, :invalid_sdp_answer} = WebRTC.process_answer(connection_id, invalid_answer)
    end

    test "returns error for non-existent connection" do
      connection_id = "nonexistent"
      answer = %{type: :answer, sdp: "v=0\r\no=- 9876543210 2 IN IP4 127.0.0.1"}

      assert {:error, :connection_not_found} = WebRTC.process_answer(connection_id, answer)
    end
  end

  describe "add_ice_candidate/2" do
    test "adds a valid ICE candidate" do
      connection_id = "conn_456"

      candidate = %{
        candidate: "candidate:1 1 UDP 2113667326 192.168.1.100 54400 typ host",
        sdp_mid: "0",
        sdp_mline_index: 0
      }

      assert {:ok, connection} = WebRTC.add_ice_candidate(connection_id, candidate)

      assert candidate in connection.ice_candidates
    end

    test "returns error for invalid ICE candidate" do
      connection_id = "conn_456"

      invalid_candidate = %{
        candidate: "invalid candidate",
        sdp_mid: "0",
        sdp_mline_index: 0
      }

      assert {:error, :invalid_ice_candidate} =
               WebRTC.add_ice_candidate(connection_id, invalid_candidate)
    end

    test "returns error for non-existent connection" do
      connection_id = "nonexistent"

      candidate = %{
        candidate: "candidate:1 1 UDP 2113667326 192.168.1.100 54400 typ host",
        sdp_mid: "0",
        sdp_mline_index: 0
      }

      assert {:error, :connection_not_found} = WebRTC.add_ice_candidate(connection_id, candidate)
    end
  end

  describe "create_data_channel/3" do
    test "creates a data channel for connected peer" do
      connection_id = "conn_456"
      channel_name = "file-transfer"
      options = [ordered: true, reliable: true]

      assert {:ok, connection} = WebRTC.create_data_channel(connection_id, channel_name, options)

      assert channel_name in connection.data_channels
    end

    test "returns error for non-existent connection" do
      connection_id = "nonexistent"
      channel_name = "file-transfer"

      assert {:error, :connection_not_found} =
               WebRTC.create_data_channel(connection_id, channel_name)
    end
  end

  describe "get_peer_connection/1" do
    test "returns peer connection for existing connection" do
      connection_id = "conn_456"

      connection = WebRTC.get_peer_connection(connection_id)

      assert connection.id == connection_id
      assert is_binary(connection.peer_id)
      assert connection.state == :connected
      assert is_list(connection.data_channels)
      assert is_list(connection.ice_candidates)
    end

    test "returns nil for non-existent connection" do
      connection_id = "nonexistent"

      assert is_nil(WebRTC.get_peer_connection(connection_id))
    end
  end

  describe "close_peer_connection/1" do
    test "closes existing peer connection" do
      connection_id = "conn_456"

      assert :ok = WebRTC.close_peer_connection(connection_id)
    end

    test "returns error for non-existent connection" do
      connection_id = "nonexistent"

      assert {:error, :connection_not_found} = WebRTC.close_peer_connection(connection_id)
    end
  end

  describe "get_connection_stats/1" do
    test "returns connection statistics for existing connection" do
      connection_id = "conn_456"

      stats = WebRTC.get_connection_stats(connection_id)

      assert stats.connection_id == connection_id
      assert is_atom(stats.state)
      assert is_integer(stats.data_channels)
      assert is_integer(stats.uptime_seconds)
      assert is_struct(stats.last_activity, DateTime)
      assert is_integer(stats.bytes_sent)
      assert is_integer(stats.bytes_received)
      assert is_integer(stats.packets_lost)
      assert is_integer(stats.rtt)
    end

    test "returns error for non-existent connection" do
      connection_id = "nonexistent"

      assert {:error, :connection_not_found} = WebRTC.get_connection_stats(connection_id)
    end
  end
end
