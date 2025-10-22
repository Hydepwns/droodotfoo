defmodule Droodotfoo.Performance.CacheTest do
  use ExUnit.Case, async: false
  alias Droodotfoo.Performance.Cache

  setup do
    # Clear cache before each test (process already running from supervision tree)
    Cache.clear(:all)
    :ok
  end

  describe "put/4 and get/2" do
    test "stores and retrieves values" do
      Cache.put(:test, "key1", "value1")
      assert {:ok, "value1"} = Cache.get(:test, "key1")
    end

    test "returns error for non-existent keys" do
      assert :error = Cache.get(:test, "nonexistent")
    end

    test "stores values with different namespaces" do
      Cache.put(:ns1, "key", "value1")
      Cache.put(:ns2, "key", "value2")

      assert {:ok, "value1"} = Cache.get(:ns1, "key")
      assert {:ok, "value2"} = Cache.get(:ns2, "key")
    end

    test "stores values with custom TTL" do
      Cache.put(:test, "key", "value", ttl: 100)
      assert {:ok, "value"} = Cache.get(:test, "key")

      # Wait for expiration
      Process.sleep(150)
      assert :error = Cache.get(:test, "key")
    end

    test "stores values with infinite TTL" do
      Cache.put(:test, "key", "value", ttl: :infinity)
      assert {:ok, "value"} = Cache.get(:test, "key")
    end
  end

  describe "fetch/4" do
    test "returns cached value if available" do
      Cache.put(:test, "key", "cached")

      result =
        Cache.fetch(:test, "key", fn ->
          "computed"
        end)

      assert result == "cached"
    end

    test "executes function and caches result on miss" do
      result =
        Cache.fetch(:test, "key", fn ->
          "computed"
        end)

      assert result == "computed"
      assert {:ok, "computed"} = Cache.get(:test, "key")
    end
  end

  describe "delete/2" do
    test "removes specific entries" do
      Cache.put(:test, "key1", "value1")
      Cache.put(:test, "key2", "value2")

      Cache.delete(:test, "key1")

      assert :error = Cache.get(:test, "key1")
      assert {:ok, "value2"} = Cache.get(:test, "key2")
    end
  end

  describe "clear/1" do
    test "clears all entries in a namespace" do
      Cache.put(:test, "key1", "value1")
      Cache.put(:test, "key2", "value2")
      Cache.put(:other, "key3", "value3")

      Cache.clear(:test)

      assert :error = Cache.get(:test, "key1")
      assert :error = Cache.get(:test, "key2")
      assert {:ok, "value3"} = Cache.get(:other, "key3")
    end

    test "clears entire cache" do
      Cache.put(:test, "key1", "value1")
      Cache.put(:other, "key2", "value2")

      Cache.clear(:all)

      assert :error = Cache.get(:test, "key1")
      assert :error = Cache.get(:other, "key2")
    end
  end

  describe "prune_expired/0" do
    test "removes only expired entries" do
      Cache.put(:test, "expired", "value", ttl: 50)
      Cache.put(:test, "valid", "value", ttl: 10_000)

      Process.sleep(100)
      deleted = Cache.prune_expired()

      assert deleted >= 1
      assert :error = Cache.get(:test, "expired")
      assert {:ok, "value"} = Cache.get(:test, "valid")
    end
  end

  describe "stats/1" do
    test "returns overall statistics" do
      Cache.put(:test, "key1", "value1")
      Cache.get(:test, "key1")
      # hit
      Cache.get(:test, "nonexistent")
      # miss

      stats = Cache.stats(:all)

      assert stats.hits >= 1
      assert stats.misses >= 1
      assert stats.size >= 1
      assert is_integer(stats.memory_bytes)
    end

    test "returns namespace-specific statistics" do
      Cache.put(:test, "key", "value")
      Cache.get(:test, "key")

      stats = Cache.stats(:test)

      assert stats.hits >= 1
      assert is_integer(stats.size)
    end
  end
end
