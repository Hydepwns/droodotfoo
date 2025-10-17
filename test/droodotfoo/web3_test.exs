defmodule Droodotfoo.Web3Test do
  use ExUnit.Case, async: false
  alias Droodotfoo.Web3

  setup do
    # Web3 is already started by the application supervision tree
    # Just ensure it's running
    Process.sleep(10)
    :ok
  end

  describe "nonce management" do
    test "generates and stores a nonce" do
      address = "0x1234567890abcdef1234567890abcdef12345678"

      assert {:ok, nonce} = Web3.generate_nonce(address)
      assert is_binary(nonce)
      assert String.length(nonce) == 32
    end

    test "generates unique nonces for same address" do
      address = "0x1234567890abcdef1234567890abcdef12345678"

      {:ok, nonce1} = Web3.generate_nonce(address)
      {:ok, nonce2} = Web3.generate_nonce(address)

      assert nonce1 != nonce2
    end

    test "verifies unused nonce" do
      address = "0x1234567890abcdef1234567890abcdef12345678"

      {:ok, nonce} = Web3.generate_nonce(address)

      assert {:ok, nonce_entry} = Web3.verify_nonce(nonce, address)
      assert nonce_entry.nonce == nonce
      assert nonce_entry.address == address
      assert nonce_entry.used == false
    end

    test "marks nonce as used after verification" do
      address = "0x1234567890abcdef1234567890abcdef12345678"

      {:ok, nonce} = Web3.generate_nonce(address)

      # First verification should succeed
      assert {:ok, _} = Web3.verify_nonce(nonce, address)

      # Second verification should fail (nonce already used)
      assert {:error, :nonce_already_used} = Web3.verify_nonce(nonce, address)
    end

    test "rejects nonce for wrong address" do
      address1 = "0x1111111111111111111111111111111111111111"
      address2 = "0x2222222222222222222222222222222222222222"

      {:ok, nonce} = Web3.generate_nonce(address1)

      assert {:error, :address_mismatch} = Web3.verify_nonce(nonce, address2)
    end

    test "rejects invalid nonce" do
      address = "0x1234567890abcdef1234567890abcdef12345678"
      invalid_nonce = "invalid_nonce_12345"

      assert {:error, :invalid_nonce} = Web3.verify_nonce(invalid_nonce, address)
    end
  end

  describe "session management" do
    test "starts a new session" do
      address = "0x1234567890abcdef1234567890abcdef12345678"
      chain_id = 1

      assert {:ok, session} = Web3.start_session(address, chain_id)
      assert session.address == address
      assert session.chain_id == chain_id
      assert %DateTime{} = session.connected_at
      assert %DateTime{} = session.last_activity
    end

    test "retrieves an active session" do
      address = "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd"
      chain_id = 1

      {:ok, _session} = Web3.start_session(address, chain_id)

      assert {:ok, retrieved_session} = Web3.get_session(address)
      assert retrieved_session.address == address
      assert retrieved_session.chain_id == chain_id
    end

    test "returns error for non-existent session" do
      address = "0x9999999999999999999999999999999999999999"

      assert {:error, :not_found} = Web3.get_session(address)
    end

    test "updates session activity timestamp" do
      address = "0x5555555555555555555555555555555555555555"
      chain_id = 1

      {:ok, session} = Web3.start_session(address, chain_id)
      initial_activity = session.last_activity

      # Wait a bit to ensure timestamp changes
      Process.sleep(50)

      assert :ok = Web3.touch_session(address)

      {:ok, updated_session} = Web3.get_session(address)
      assert DateTime.compare(updated_session.last_activity, initial_activity) == :gt
    end

    test "ends a session" do
      address = "0x6666666666666666666666666666666666666666"
      chain_id = 1

      {:ok, _session} = Web3.start_session(address, chain_id)
      assert {:ok, _} = Web3.get_session(address)

      assert :ok = Web3.end_session(address)
      assert {:error, :not_found} = Web3.get_session(address)
    end

    test "lists all active sessions" do
      address1 = "0x7777777777777777777777777777777777777777"
      address2 = "0x8888888888888888888888888888888888888888"

      Web3.start_session(address1, 1)
      Web3.start_session(address2, 5)

      sessions = Web3.list_sessions()

      assert is_list(sessions)
      assert length(sessions) >= 2

      addresses = Enum.map(sessions, & &1.address)
      assert address1 in addresses
      assert address2 in addresses
    end
  end

  describe "ENS resolution" do
    test "resolves address (stub implementation)" do
      address = "0x1234567890abcdef1234567890abcdef12345678"

      # Current implementation is a stub that returns the address
      assert {:ok, resolved} = Web3.resolve_ens(address)
      assert resolved == address
    end
  end
end
