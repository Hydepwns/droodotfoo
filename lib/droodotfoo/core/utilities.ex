defmodule Droodotfoo.Core.Utilities do
  @moduledoc """
  Shared utility functions used across the application.
  Provides common helper functions to reduce duplication.
  """

  @doc """
  Formats a timestamp as a relative time string.

  ## Examples

      iex> format_relative_time(~U[2023-01-01 12:00:00Z])
      "2h ago"
      
      iex> format_relative_time(~U[2023-01-01 10:00:00Z])
      "4h ago"
  """
  def format_relative_time(timestamp) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, timestamp, :second)

    cond do
      diff_seconds < 60 -> "#{diff_seconds}s ago"
      diff_seconds < 3600 -> "#{div(diff_seconds, 60)}m ago"
      diff_seconds < 86_400 -> "#{div(diff_seconds, 3600)}h ago"
      diff_seconds < 604_800 -> "#{div(diff_seconds, 86_400)}d ago"
      true -> "#{div(diff_seconds, 604_800)}w ago"
    end
  end

  @doc """
  Abbreviates an Ethereum address to the format 0x1234...5678.

  ## Examples

      iex> abbreviate_address("0x1234567890abcdef1234567890abcdef12345678")
      "0x1234...5678"
  """
  def abbreviate_address(address) when is_binary(address) do
    if String.length(address) >= 10 do
      prefix = String.slice(address, 0, 6)
      suffix = String.slice(address, -4, 4)
      "#{prefix}...#{suffix}"
    else
      address
    end
  end

  @doc """
  Validates an Ethereum address format.

  ## Examples

      iex> valid_ethereum_address?("0x1234567890abcdef1234567890abcdef12345678")
      true
      
      iex> valid_ethereum_address?("invalid")
      false
  """
  def valid_ethereum_address?(address) when is_binary(address) do
    String.match?(address, ~r/^0x[a-fA-F0-9]{40}$/)
  end

  def valid_ethereum_address?(_), do: false

  @doc """
  Formats file size in human-readable format.

  ## Examples

      iex> format_file_size(1024)
      "1.0 KB"
      
      iex> format_file_size(1048576)
      "1.0 MB"
  """
  def format_file_size(bytes) when is_integer(bytes) and bytes >= 0 do
    cond do
      bytes < 1024 -> "#{bytes} B"
      bytes < 1_048_576 -> "#{Float.round(bytes / 1024, 1)} KB"
      bytes < 1_073_741_824 -> "#{Float.round(bytes / 1_048_576, 1)} MB"
      true -> "#{Float.round(bytes / 1_073_741_824, 1)} GB"
    end
  end

  @doc """
  Truncates text to a specified length with ellipsis.

  ## Examples

      iex> truncate_text("This is a very long text", 10)
      "This is..."
      
      iex> truncate_text("Short", 10)
      "Short"
  """
  def truncate_text(text, max_length) when is_binary(text) and is_integer(max_length) do
    if String.length(text) <= max_length do
      text
    else
      String.slice(text, 0, max_length - 3) <> "..."
    end
  end

  @doc """
  Generates a random string of specified length.

  ## Examples

      iex> random_string(8)
      "aB3dEf9h"
  """
  def random_string(length) when is_integer(length) and length > 0 do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64(padding: false)
    |> String.slice(0, length)
  end

  @doc """
  Safely parses JSON with error handling.

  ## Examples

      iex> safe_json_parse(~s({"key": "value"}))
      {:ok, %{"key" => "value"}}
      
      iex> safe_json_parse("invalid json")
      {:error, :invalid_json}
  """
  def safe_json_parse(json_string) when is_binary(json_string) do
    case Jason.decode(json_string) do
      {:ok, data} -> {:ok, data}
      {:error, _} -> {:error, :invalid_json}
    end
  end

  @doc """
  Creates a map with only the specified keys.

  ## Examples

      iex> pick_keys(%{a: 1, b: 2, c: 3}, [:a, :c])
      %{a: 1, c: 3}
  """
  def pick_keys(map, keys) when is_map(map) and is_list(keys) do
    keys
    |> Enum.filter(&Map.has_key?(map, &1))
    |> Enum.into(%{}, fn key -> {key, Map.get(map, key)} end)
  end

  @doc """
  Deep merges two maps, with the second map taking precedence.

  ## Examples

      iex> deep_merge(%{a: 1, b: %{c: 2}}, %{b: %{d: 3}})
      %{a: 1, b: %{c: 2, d: 3}}
  """
  def deep_merge(left, right) when is_map(left) and is_map(right) do
    Map.merge(left, right, fn
      _key, left_val, right_val when is_map(left_val) and is_map(right_val) ->
        deep_merge(left_val, right_val)

      _key, _left_val, right_val ->
        right_val
    end)
  end

  @doc """
  Converts a map to a list of key-value tuples, sorted by key.

  ## Examples

      iex> map_to_sorted_tuples(%{c: 3, a: 1, b: 2})
      [a: 1, b: 2, c: 3]
  """
  def map_to_sorted_tuples(map) when is_map(map) do
    map
    |> Enum.to_list()
    |> Enum.sort_by(fn {key, _value} -> key end)
  end

  @doc """
  Groups a list by a key function.

  ## Examples

      iex> group_by([%{type: "a", val: 1}, %{type: "b", val: 2}, %{type: "a", val: 3}], :type)
      %{"a" => [%{type: "a", val: 1}, %{type: "a", val: 3}], "b" => [%{type: "b", val: 2}]}
  """
  def group_by(list, key) when is_list(list) and is_atom(key) do
    Enum.group_by(list, &Map.get(&1, key))
  end

  @doc """
  Creates a progress bar string.

  ## Examples

      iex> progress_bar(0.5, 10)
      "█████░░░░░"
      
      iex> progress_bar(0.8, 5)
      "████░"
  """
  def progress_bar(percentage, width) when is_float(percentage) and is_integer(width) do
    filled = round(percentage * width)
    empty = width - filled

    String.duplicate("█", filled) <> String.duplicate("░", empty)
  end

  @doc """
  Generates a UUID v4 string.

  ## Examples

      iex> generate_uuid()
      "550e8400-e29b-41d4-a716-446655440000"
  """
  def generate_uuid do
    UUID.uuid4()
  end

  @doc """
  Converts a string to a slug format.

  ## Examples

      iex> slugify("Hello World!")
      "hello-world"
      
      iex> slugify("My Awesome Project")
      "my-awesome-project"
  """
  def slugify(text) when is_binary(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.replace(~r/-+/, "-")
    |> String.trim("-")
  end

  @doc """
  Checks if a string is a valid email address.

  ## Examples

      iex> valid_email?("user@example.com")
      true
      
      iex> valid_email?("invalid-email")
      false
  """
  def valid_email?(email) when is_binary(email) do
    String.match?(email, ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/)
  end

  def valid_email?(_), do: false
end
