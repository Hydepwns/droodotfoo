defmodule Droodotfoo.Web3.ENSTest do
  use ExUnit.Case, async: true
  alias Droodotfoo.Web3.ENS

  describe "valid_ens_name?/1" do
    test "returns true for valid ENS names" do
      assert ENS.valid_ens_name?("vitalik.eth") == true
      assert ENS.valid_ens_name?("example.eth") == true
      assert ENS.valid_ens_name?("my-name.eth") == true
      assert ENS.valid_ens_name?("test123.eth") == true
    end

    test "returns false for invalid ENS names" do
      # Missing .eth suffix
      assert ENS.valid_ens_name?("vitalik") == false
      assert ENS.valid_ens_name?("test.com") == false

      # Too short (just ".eth")
      assert ENS.valid_ens_name?(".eth") == false

      # Invalid characters
      assert ENS.valid_ens_name?("Test.eth") == false
      assert ENS.valid_ens_name?("test space.eth") == false
      assert ENS.valid_ens_name?("test@.eth") == false
      assert ENS.valid_ens_name?("test_.eth") == false
    end

    test "returns false for empty strings" do
      assert ENS.valid_ens_name?("") == false
    end
  end

  describe "valid_address?/1" do
    test "returns true for valid Ethereum addresses" do
      assert ENS.valid_address?("0x1234567890abcdef1234567890abcdef12345678") == true
      assert ENS.valid_address?("0xABCDEF1234567890ABCDEF1234567890ABCDEF12") == true
      assert ENS.valid_address?("0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045") == true
    end

    test "returns false for invalid addresses" do
      # Missing 0x prefix
      assert ENS.valid_address?("1234567890abcdef1234567890abcdef12345678") == false

      # Wrong length
      assert ENS.valid_address?("0x123") == false
      assert ENS.valid_address?("0x1234567890abcdef1234567890abcdef123456789") == false

      # Invalid characters
      assert ENS.valid_address?("0x1234567890abcdef1234567890abcdef1234567g") == false
      assert ENS.valid_address?("0x1234567890abcdef1234567890abcdef1234567@") == false
    end

    test "returns false for empty strings" do
      assert ENS.valid_address?("") == false
    end
  end

  describe "normalize_name/1" do
    test "converts name to lowercase" do
      assert ENS.normalize_name("Vitalik.eth") == "vitalik.eth"
      assert ENS.normalize_name("EXAMPLE.ETH") == "example.eth"
      assert ENS.normalize_name("MixedCase.eth") == "mixedcase.eth"
    end

    test "trims whitespace" do
      assert ENS.normalize_name("  example.eth  ") == "example.eth"
      assert ENS.normalize_name("\nvitalik.eth\n") == "vitalik.eth"
      assert ENS.normalize_name("\ttest.eth\t") == "test.eth"
    end

    test "handles already normalized names" do
      assert ENS.normalize_name("vitalik.eth") == "vitalik.eth"
      assert ENS.normalize_name("example.eth") == "example.eth"
    end

    test "normalizes combined cases" do
      assert ENS.normalize_name("  EXAMPLE.ETH  ") == "example.eth"
    end
  end

  describe "resolve_name/2" do
    test "returns error for invalid ENS name format" do
      assert ENS.resolve_name("invalid", 1) == {:error, :invalid_ens_name}
      assert ENS.resolve_name("test.com", 1) == {:error, :invalid_ens_name}
      assert ENS.resolve_name("", 1) == {:error, :invalid_ens_name}
    end

    test "returns error for non-mainnet chains" do
      assert ENS.resolve_name("vitalik.eth", 5) == {:error, :ens_only_on_mainnet}
      assert ENS.resolve_name("example.eth", 137) == {:error, :ens_only_on_mainnet}
      assert ENS.resolve_name("test.eth", 42_161) == {:error, :ens_only_on_mainnet}
    end

    test "defaults to mainnet chain ID" do
      # Should not return :ens_only_on_mainnet error when chain_id not specified
      result = ENS.resolve_name("example.eth")
      assert result != {:error, :ens_only_on_mainnet}
    end
  end

  describe "reverse_resolve/2" do
    test "returns error for invalid address format" do
      assert ENS.reverse_resolve("invalid", 1) == {:error, :invalid_address}
      assert ENS.reverse_resolve("0x123", 1) == {:error, :invalid_address}
      assert ENS.reverse_resolve("", 1) == {:error, :invalid_address}
    end

    test "returns error for non-mainnet chains" do
      valid_address = "0x1234567890abcdef1234567890abcdef12345678"
      assert ENS.reverse_resolve(valid_address, 5) == {:error, :ens_only_on_mainnet}
      assert ENS.reverse_resolve(valid_address, 137) == {:error, :ens_only_on_mainnet}
    end

    test "accepts valid address format on mainnet" do
      valid_address = "0x1234567890abcdef1234567890abcdef12345678"
      # Should not return :invalid_address or :ens_only_on_mainnet
      result = ENS.reverse_resolve(valid_address, 1)
      assert result != {:error, :invalid_address}
      assert result != {:error, :ens_only_on_mainnet}
    end

    test "defaults to mainnet chain ID" do
      valid_address = "0x1234567890abcdef1234567890abcdef12345678"
      result = ENS.reverse_resolve(valid_address)
      assert result != {:error, :ens_only_on_mainnet}
    end
  end

  describe "get_avatar/1" do
    test "returns ok tuple with nil for any name" do
      assert ENS.get_avatar("vitalik.eth") == {:ok, nil}
      assert ENS.get_avatar("example.eth") == {:ok, nil}
      assert ENS.get_avatar("test.eth") == {:ok, nil}
    end

    test "handles invalid names gracefully" do
      # Function doesn't validate, just returns nil
      assert ENS.get_avatar("invalid") == {:ok, nil}
      assert ENS.get_avatar("") == {:ok, nil}
    end
  end
end
