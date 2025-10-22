defmodule Droodotfoo.Web3.NetworksTest do
  use ExUnit.Case, async: true
  alias Droodotfoo.Web3.Networks

  describe "get_network_name/1" do
    test "returns Ethereum Mainnet for chain ID 1" do
      assert Networks.get_network_name(1) == "Ethereum Mainnet"
    end

    test "returns Hoodi Testnet for chain ID 5" do
      assert Networks.get_network_name(5) == "Hoodi Testnet"
    end

    test "returns Sepolia Testnet for chain ID 11155111" do
      assert Networks.get_network_name(11_155_111) == "Sepolia Testnet"
    end

    test "returns Polygon Mainnet for chain ID 137" do
      assert Networks.get_network_name(137) == "Polygon Mainnet"
    end

    test "returns Mumbai Testnet for chain ID 80001" do
      assert Networks.get_network_name(80_001) == "Mumbai Testnet"
    end

    test "returns Arbitrum One for chain ID 42161" do
      assert Networks.get_network_name(42_161) == "Arbitrum One"
    end

    test "returns Optimism for chain ID 10" do
      assert Networks.get_network_name(10) == "Optimism"
    end

    test "returns Base for chain ID 8453" do
      assert Networks.get_network_name(8453) == "Base"
    end

    test "returns generic name for unsupported chain ID" do
      assert Networks.get_network_name(99_999) == "Chain ID: 99999"
      assert Networks.get_network_name(12_345) == "Chain ID: 12345"
    end

    test "handles edge cases" do
      assert Networks.get_network_name(0) == "Chain ID: 0"
      assert Networks.get_network_name(-1) == "Chain ID: -1"
    end
  end

  describe "supported_chains/0" do
    test "returns list of supported chain IDs" do
      chains = Networks.supported_chains()

      assert is_list(chains)
      assert length(chains) == 8
      assert 1 in chains
      assert 137 in chains
      assert 42_161 in chains
    end

    test "includes all major networks" do
      chains = Networks.supported_chains()

      # Ethereum networks
      assert 1 in chains
      assert 5 in chains
      assert 11_155_111 in chains

      # L2 networks
      assert 137 in chains
      assert 42_161 in chains
      assert 10 in chains
      assert 8453 in chains
    end
  end

  describe "supported_chain?/1" do
    test "returns true for supported mainnet chains" do
      assert Networks.supported_chain?(1) == true
      assert Networks.supported_chain?(137) == true
      assert Networks.supported_chain?(42_161) == true
      assert Networks.supported_chain?(10) == true
      assert Networks.supported_chain?(8453) == true
    end

    test "returns true for supported testnet chains" do
      assert Networks.supported_chain?(5) == true
      assert Networks.supported_chain?(11_155_111) == true
      assert Networks.supported_chain?(80_001) == true
    end

    test "returns false for unsupported chains" do
      assert Networks.supported_chain?(99_999) == false
      assert Networks.supported_chain?(12_345) == false
      assert Networks.supported_chain?(0) == false
      assert Networks.supported_chain?(-1) == false
    end
  end
end
