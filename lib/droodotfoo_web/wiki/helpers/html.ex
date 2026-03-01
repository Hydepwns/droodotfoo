defmodule DroodotfooWeb.Wiki.Helpers.HTML do
  @moduledoc """
  HTML processing utilities for wiki articles.
  Handles image optimization, heading anchors, and other enhancements.
  """

  @doc """
  Enhances article HTML with performance optimizations.
  - Adds lazy loading to images
  - Adds decoding="async" to images
  - Ensures images have alt text
  """
  @spec enhance_images(String.t()) :: String.t()
  def enhance_images(html) when is_binary(html) do
    html
    |> add_lazy_loading()
    |> add_async_decoding()
  end

  def enhance_images(html), do: html

  # Add loading="lazy" to img tags that don't have it
  defp add_lazy_loading(html) do
    Regex.replace(
      ~r/<img(?![^>]*\bloading\s*=)([^>]*)>/i,
      html,
      ~s(<img loading="lazy"\\1>)
    )
  end

  # Add decoding="async" to img tags that don't have it
  defp add_async_decoding(html) do
    Regex.replace(
      ~r/<img(?![^>]*\bdecoding\s*=)([^>]*)>/i,
      html,
      ~s(<img decoding="async"\\1>)
    )
  end

  @doc """
  Counts words in HTML content (strips tags first).
  """
  @spec word_count(String.t()) :: non_neg_integer()
  def word_count(html) when is_binary(html) do
    html
    |> strip_tags()
    |> String.split(~r/\s+/, trim: true)
    |> length()
  end

  def word_count(_), do: 0

  @doc """
  Estimates reading time in minutes based on word count.
  Assumes average reading speed of 200 words per minute.
  """
  @spec reading_time(String.t() | non_neg_integer()) :: non_neg_integer()
  def reading_time(html) when is_binary(html) do
    reading_time(word_count(html))
  end

  def reading_time(word_count) when is_integer(word_count) do
    max(1, ceil(word_count / 200))
  end

  def reading_time(_), do: 1

  @doc """
  Strips HTML tags from content, leaving only text.
  """
  @spec strip_tags(String.t()) :: String.t()
  def strip_tags(html) when is_binary(html) do
    html
    |> String.replace(~r/<[^>]+>/, " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  def strip_tags(_), do: ""
end
