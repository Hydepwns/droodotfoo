defmodule Droodotfoo.Content.PatternCacheTest do
  use ExUnit.Case, async: false

  alias Droodotfoo.Content.PatternCache

  setup do
    # Clear cache before each test
    PatternCache.clear()
    :ok
  end

  describe "get_or_generate/2" do
    test "generates pattern on first call (cache miss)" do
      svg = PatternCache.get_or_generate("test-post", style: :waves)
      assert String.contains?(svg, "<?xml")
      assert String.contains?(svg, "<svg")
    end

    test "returns cached pattern on second call (cache hit)" do
      # First call - generates and caches
      svg1 = PatternCache.get_or_generate("test-post", style: :waves)

      # Second call - should return cached version
      svg2 = PatternCache.get_or_generate("test-post", style: :waves)

      # Should be identical
      assert svg1 == svg2
    end

    test "different options create different cache entries" do
      svg_waves = PatternCache.get_or_generate("test-post", style: :waves)
      svg_dots = PatternCache.get_or_generate("test-post", style: :dots)

      # Different styles should produce different SVGs
      refute svg_waves == svg_dots
    end

    test "normalizes cache keys for consistent hits" do
      # Same options in different order should hit same cache entry
      svg1 = PatternCache.get_or_generate("test-post", width: 800, style: :waves)
      svg2 = PatternCache.get_or_generate("test-post", style: :waves, width: 800)

      assert svg1 == svg2
    end
  end

  describe "get/1 and put/2" do
    test "returns :miss for non-existent keys" do
      assert PatternCache.get({"nonexistent", []}) == :miss
    end

    test "stores and retrieves values" do
      key = {"test-slug", [style: :waves]}
      svg = "<svg>test</svg>"

      PatternCache.put(key, svg)
      assert {:ok, ^svg} = PatternCache.get(key)
    end

    test "respects TTL expiration" do
      key = {"test-slug", [style: :waves]}
      svg = "<svg>test</svg>"

      # Put with very short TTL (1ms)
      PatternCache.put(key, svg, ttl: 1)

      # Wait for expiration
      Process.sleep(5)

      # Should be expired
      assert PatternCache.get(key) == :miss
    end
  end

  describe "delete/2" do
    test "removes specific pattern from cache" do
      PatternCache.get_or_generate("test-post", style: :waves)

      # Verify it's cached
      assert {:ok, _} = PatternCache.get({"test-post", [style: :waves]})

      # Delete it
      PatternCache.delete("test-post", style: :waves)

      # Should be gone
      assert PatternCache.get({"test-post", [style: :waves]}) == :miss
    end
  end

  describe "clear/0" do
    test "removes all cached patterns" do
      PatternCache.get_or_generate("post1", style: :waves)
      PatternCache.get_or_generate("post2", style: :dots)

      stats_before = PatternCache.stats()
      assert stats_before.size == 2

      PatternCache.clear()

      stats_after = PatternCache.stats()
      assert stats_after.size == 0
    end
  end

  describe "stats/0" do
    test "returns cache statistics" do
      stats = PatternCache.stats()

      assert is_integer(stats.size)
      assert is_integer(stats.memory_bytes)
      assert is_number(stats.ttl_hours)
    end

    test "size increases with cached patterns" do
      stats_before = PatternCache.stats()

      PatternCache.get_or_generate("post1", style: :waves)
      PatternCache.get_or_generate("post2", style: :dots)

      stats_after = PatternCache.stats()

      assert stats_after.size == stats_before.size + 2
    end

    test "memory usage increases with cached patterns" do
      stats_before = PatternCache.stats()

      # Generate a pattern (creates a large SVG string)
      PatternCache.get_or_generate("test-post", style: :waves)

      stats_after = PatternCache.stats()

      assert stats_after.memory_bytes > stats_before.memory_bytes
    end
  end
end
