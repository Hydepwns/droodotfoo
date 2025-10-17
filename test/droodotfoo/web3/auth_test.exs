defmodule Droodotfoo.Web3.AuthTest do
  use ExUnit.Case, async: true
  alias Droodotfoo.Web3.Auth

  describe "generate_nonce/0" do
    test "generates a 32-character hex string" do
      nonce = Auth.generate_nonce()
      assert String.length(nonce) == 32
      assert String.match?(nonce, ~r/^[0-9a-f]{32}$/)
    end

    test "generates unique nonces" do
      nonce1 = Auth.generate_nonce()
      nonce2 = Auth.generate_nonce()
      assert nonce1 != nonce2
    end
  end

  describe "format_auth_message/2" do
    test "includes wallet address and nonce" do
      address = "0x1234567890abcdef1234567890abcdef12345678"
      nonce = "abc123"

      message = Auth.format_auth_message(address, nonce)

      assert String.contains?(message, address)
      assert String.contains?(message, "Nonce: #{nonce}")
      assert String.contains?(message, "droo.foo")
    end

    test "includes no-fee disclaimer" do
      message = Auth.format_auth_message("0x123", "abc")
      assert String.contains?(message, "gas fees")
    end
  end

  describe "normalize_address/1" do
    test "removes 0x prefix and lowercases" do
      assert Auth.normalize_address("0xABCD1234") == "abcd1234"
    end

    test "handles address without 0x prefix" do
      assert Auth.normalize_address("ABCD1234") == "abcd1234"
    end

    test "handles already normalized address" do
      assert Auth.normalize_address("abcd1234") == "abcd1234"
    end
  end

  describe "validate_address/1" do
    test "accepts valid 40-character hex address with 0x prefix" do
      valid_address = "0x1234567890abcdef1234567890abcdef12345678"
      assert {:ok, normalized} = Auth.validate_address(valid_address)
      assert normalized == String.downcase(valid_address)
    end

    test "accepts valid 40-character hex address without 0x prefix" do
      address = "1234567890abcdef1234567890abcdef12345678"
      assert {:ok, normalized} = Auth.validate_address(address)
      assert normalized == "0x" <> address
    end

    test "accepts uppercase addresses" do
      address = "0xABCDEF1234567890ABCDEF1234567890ABCDEF12"
      assert {:ok, _} = Auth.validate_address(address)
    end

    test "rejects address with invalid length" do
      assert {:error, :invalid_length} = Auth.validate_address("0x123")

      assert {:error, :invalid_length} =
               Auth.validate_address("0x123456789012345678901234567890123456789012")
    end

    test "rejects address with invalid characters" do
      assert {:error, :invalid_format} =
               Auth.validate_address("0x123456789012345678901234567890123456zzzz")
    end

    test "rejects non-binary input" do
      assert {:error, :invalid_type} = Auth.validate_address(123)
      assert {:error, :invalid_type} = Auth.validate_address(nil)
    end
  end

  describe "ethereum_message_hash/1" do
    test "hashes message using Ethereum personal_sign format" do
      message = "test message"
      hash = Auth.ethereum_message_hash(message)

      assert is_binary(hash)
      assert byte_size(hash) == 32
    end

    test "produces consistent hashes for same message" do
      message = "test message"
      hash1 = Auth.ethereum_message_hash(message)
      hash2 = Auth.ethereum_message_hash(message)

      assert hash1 == hash2
    end

    test "produces different hashes for different messages" do
      hash1 = Auth.ethereum_message_hash("message1")
      hash2 = Auth.ethereum_message_hash("message2")

      assert hash1 != hash2
    end
  end

  describe "recover_address/2" do
    @tag :skip
    test "recovers address from valid signature" do
      # This test requires a real signature from MetaMask or ethers.js
      # Skip for now - will be tested in integration tests
      # Example implementation:
      # message = "test message"
      # signature = "0x..." # Real signature from wallet
      # assert {:ok, address} = Auth.recover_address(message, signature)
      # assert String.starts_with?(address, "0x")
    end

    test "returns error for invalid signature format" do
      message = "test message"
      invalid_signature = "not-a-signature"

      assert {:error, _} = Auth.recover_address(message, invalid_signature)
    end

    test "returns error for signature with wrong length" do
      message = "test message"
      short_signature = "0x1234"

      assert {:error, :invalid_signature_length} = Auth.recover_address(message, short_signature)
    end
  end

  describe "verify_signature/3" do
    @tag :skip
    test "verifies valid signature matches claimed address" do
      # Requires real wallet signature - skip for unit test
      # Will be tested in integration tests
    end

    @tag :skip
    test "returns error when signature does not match address" do
      # Requires real wallet signature - skip for unit test
    end

    test "returns error for invalid signature" do
      address = "0x1234567890abcdef1234567890abcdef12345678"
      nonce = "abc123"
      invalid_signature = "0xinvalid"

      assert {:error, _} = Auth.verify_signature(address, nonce, invalid_signature)
    end
  end
end
