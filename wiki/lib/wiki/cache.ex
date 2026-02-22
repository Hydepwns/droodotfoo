defmodule Wiki.Cache do
  @moduledoc """
  Read-through cache backed by Cachex.

  `Cachex.fetch/3` ensures that concurrent requests for the same key
  only trigger one load - all others wait on the result.

  Three cache layers:
  1. Cloudflare edge - respects Cache-Control headers
  2. Cachex - 15 min TTL, 10K entry limit, read-through
  3. MinIO + Postgres - source of truth
  """

  @cache :wiki_cache

  @type source :: :osrs | :nlab | :wikipedia | :vintage_machinery | :wikiart

  @doc """
  Fetch rendered HTML for an article.

  On hit: returns from ETS.
  On miss: loads from MinIO, caches, returns.
  """
  @spec fetch_html(map()) :: String.t()
  def fetch_html(%{source: source, slug: slug, rendered_html_key: key}) do
    fetch_html_by_key(source, slug, key)
  end

  def fetch_html(%{source: source, slug: slug}) do
    fetch_html_by_key(source, slug, nil)
  end

  defp fetch_html_by_key(source, slug, storage_key) do
    cache_key = {:html, source, slug}

    case Cachex.fetch(@cache, cache_key, fn _key ->
           load_html(source, slug, storage_key)
         end) do
      {:ok, html} -> html
      {:commit, html} -> html
      {:ignore, fallback} -> fallback
      {:error, _} -> ""
    end
  end

  defp load_html(_source, _slug, nil), do: {:ignore, ""}

  defp load_html(source, slug, _key) do
    case Wiki.Storage.get_html(Wiki.Storage.html_key(source, slug)) do
      {:ok, html} -> {:commit, html}
      {:error, _} -> {:ignore, ""}
    end
  end

  @doc """
  Fetch raw wikitext/markdown for an article.
  """
  @spec fetch_raw(map()) :: String.t()
  def fetch_raw(%{source: source, slug: slug, raw_content_key: key}) when not is_nil(key) do
    cache_key = {:raw, source, slug}

    case Cachex.fetch(@cache, cache_key, fn _key ->
           case Wiki.Storage.get_raw(key) do
             {:ok, content} -> {:commit, content}
             {:error, _} -> {:ignore, ""}
           end
         end) do
      {:ok, content} -> content
      {:commit, content} -> content
      {:ignore, fallback} -> fallback
      {:error, _} -> ""
    end
  end

  def fetch_raw(_), do: ""

  @doc """
  Invalidate a single article's cached HTML and raw content.
  """
  @spec invalidate(source(), String.t()) :: :ok
  def invalidate(source, slug) do
    Cachex.del(@cache, {:html, source, slug})
    Cachex.del(@cache, {:raw, source, slug})
    :ok
  end

  @doc """
  Bulk-invalidate all cached HTML for a source.
  """
  @spec invalidate_source(source()) :: :ok
  def invalidate_source(source) do
    case Cachex.stream(@cache) do
      {:ok, stream} ->
        stream
        |> Stream.filter(fn {:entry, key, _, _, _} ->
          match?({:html, ^source, _}, key) or match?({:raw, ^source, _}, key)
        end)
        |> Enum.each(fn {:entry, key, _, _, _} -> Cachex.del(@cache, key) end)

      {:error, _} ->
        :ok
    end

    :ok
  end

  @doc """
  Get cache statistics.
  """
  @spec stats() :: map()
  def stats do
    case Cachex.stats(@cache) do
      {:ok, stats} -> stats
      {:error, _} -> %{}
    end
  end

  @doc """
  Clear entire cache. Use sparingly.
  """
  @spec clear() :: :ok
  def clear do
    Cachex.clear(@cache)
    :ok
  end
end
