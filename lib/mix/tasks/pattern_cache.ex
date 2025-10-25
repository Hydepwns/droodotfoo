defmodule Mix.Tasks.PatternCache do
  @moduledoc """
  Pattern cache management and benchmarking tasks.

  ## Usage

      mix pattern_cache.stats      # Show cache statistics
      mix pattern_cache.clear      # Clear all cached patterns
      mix pattern_cache.benchmark  # Benchmark cache vs no-cache performance
      mix pattern_cache.warmup     # Pre-generate patterns for all blog posts

  ## Examples

      # Check cache usage
      $ mix pattern_cache.stats

      # Clear the cache (useful after pattern generator updates)
      $ mix pattern_cache.clear

      # Warm up the cache for production
      $ mix pattern_cache.warmup
  """

  use Mix.Task

  @shortdoc "Manage and benchmark the pattern cache"

  def run(["stats"]) do
    Mix.Task.run("app.start")
    show_stats()
  end

  def run(["clear"]) do
    Mix.Task.run("app.start")
    clear_cache()
  end

  def run(["benchmark"]) do
    Mix.Task.run("app.start")
    benchmark()
  end

  def run(["warmup"]) do
    Mix.Task.run("app.start")
    warmup()
  end

  def run(_) do
    Mix.shell().info("""
    Pattern Cache Management

    Available commands:
      mix pattern_cache.stats      - Show cache statistics
      mix pattern_cache.clear      - Clear all cached patterns
      mix pattern_cache.benchmark  - Benchmark performance
      mix pattern_cache.warmup     - Pre-warm cache for all posts
    """)
  end

  defp show_stats do
    stats = Droodotfoo.Content.PatternCache.stats()

    Mix.shell().info("""
    Pattern Cache Statistics
    ========================
    Cached patterns: #{stats.size}
    Memory usage:    #{format_bytes(stats.memory_bytes)}
    TTL:             #{stats.ttl_hours} hours
    """)
  end

  defp clear_cache do
    Mix.shell().info("Clearing pattern cache...")
    Droodotfoo.Content.PatternCache.clear()
    Mix.shell().info("Cache cleared successfully!")
  end

  defp benchmark do
    Mix.shell().info("Benchmarking pattern generation...\n")

    slug = "benchmark-test"
    opts = [style: :waves]

    # Clear cache first
    Droodotfoo.Content.PatternCache.clear()

    # Benchmark first generation (no cache)
    {time_no_cache, _svg} =
      :timer.tc(fn ->
        Droodotfoo.Content.PatternCache.get_or_generate(slug, opts)
      end)

    # Benchmark second generation (cached)
    {time_cached, _svg} =
      :timer.tc(fn ->
        Droodotfoo.Content.PatternCache.get_or_generate(slug, opts)
      end)

    speedup = time_no_cache / time_cached

    Mix.shell().info("""
    Benchmark Results
    =================
    First generation (cache miss):  #{format_time(time_no_cache)}
    Second generation (cache hit):  #{format_time(time_cached)}
    Speedup:                         #{Float.round(speedup, 1)}x faster

    For a page with 5 patterns (like the homepage):
    - Without cache: ~#{format_time(time_no_cache * 5)}
    - With cache:    ~#{format_time(time_cached * 5)}
    - Savings:       ~#{format_time((time_no_cache - time_cached) * 5)} per request
    """)
  end

  defp warmup do
    Mix.shell().info("Warming up pattern cache for all blog posts...\n")

    posts = Droodotfoo.Content.Posts.list_posts()
    total = length(posts)

    Mix.shell().info("Found #{total} posts\n")

    posts
    |> Enum.with_index(1)
    |> Enum.each(fn {post, index} ->
      # Generate default pattern
      Droodotfoo.Content.PatternCache.get_or_generate(post.slug, [])

      # Generate with animation variant
      Droodotfoo.Content.PatternCache.get_or_generate(post.slug, animate: true)

      Mix.shell().info("#{index}/#{total}: #{post.slug}")
    end)

    stats = Droodotfoo.Content.PatternCache.stats()

    Mix.shell().info("""

    Cache warmup complete!
    ======================
    Cached patterns: #{stats.size}
    Memory usage:    #{format_bytes(stats.memory_bytes)}
    """)
  end

  defp format_time(microseconds) do
    cond do
      microseconds < 1_000 ->
        "#{microseconds}µs"

      microseconds < 1_000_000 ->
        "#{Float.round(microseconds / 1_000, 2)}ms"

      true ->
        "#{Float.round(microseconds / 1_000_000, 2)}s"
    end
  end

  defp format_bytes(bytes) do
    cond do
      bytes < 1024 ->
        "#{bytes} bytes"

      bytes < 1024 * 1024 ->
        "#{Float.round(bytes / 1024, 2)} KB"

      true ->
        "#{Float.round(bytes / (1024 * 1024), 2)} MB"
    end
  end
end
