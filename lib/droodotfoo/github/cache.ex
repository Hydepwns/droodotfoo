defmodule Droodotfoo.GitHub.Cache do
  @moduledoc """
  Cache for GitHub API data.

  Thin wrapper around `Performance.Cache` with GitHub-specific logic.
  Provides `cached_at` metadata for freshness indicators.
  """

  require Logger

  alias Droodotfoo.Performance.Cache

  @namespace :github
  @default_ttl :timer.hours(1)

  @type cache_key :: {String.t(), String.t()}
  @type cache_value :: term()

  @doc """
  Gets a value from the cache.

  Returns `{:ok, value, cached_at}` if found and not expired, `:miss` otherwise.
  The `cached_at` is a monotonic timestamp in milliseconds.
  """
  @spec get(cache_key()) :: {:ok, cache_value(), integer()} | :miss
  def get(key) do
    case Cache.get_with_metadata(@namespace, key) do
      {:ok, value, cached_at} -> {:ok, value, cached_at}
      :error -> :miss
    end
  end

  @doc """
  Puts a value into the cache with optional TTL.

  ## Options

    * `:ttl` - Time to live in milliseconds (default: 1 hour)
  """
  @spec put(cache_key(), cache_value(), keyword()) :: :ok
  def put(key, value, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @default_ttl)
    Cache.put(@namespace, key, value, ttl: ttl)
  end

  @doc """
  Clears the entire GitHub cache.
  """
  @spec clear() :: :ok
  def clear do
    Cache.clear(@namespace)
    Logger.info("GitHub cache cleared")
    :ok
  end

  @doc """
  Clears a specific key from the cache.
  """
  @spec delete(cache_key()) :: :ok
  def delete(key) do
    Cache.delete(@namespace, key)
  end

  @doc """
  Returns cache statistics.
  """
  @spec stats() :: map()
  def stats do
    Cache.stats(@namespace)
  end
end
