defmodule DroodotfooWeb.Wiki.OSRS.V1.Params do
  @moduledoc """
  Shared parameter parsing utilities for OSRS API controllers.

  Used by ItemController and MonsterController to parse query params.
  """

  @doc """
  Conditionally adds a key-value pair to an options keyword list.

  Handles nil values, boolean strings, and integers.

  ## Examples

      iex> [] |> Params.maybe_add(:members, "true")
      [members: true]

      iex> [] |> Params.maybe_add(:name, nil)
      []

      iex> [] |> Params.maybe_add(:limit, 50)
      [limit: 50]

  """
  @spec maybe_add(keyword(), atom(), term()) :: keyword()
  def maybe_add(opts, _key, nil), do: opts
  def maybe_add(opts, key, "true"), do: Keyword.put(opts, key, true)
  def maybe_add(opts, key, "false"), do: Keyword.put(opts, key, false)
  def maybe_add(opts, key, value) when is_binary(value), do: Keyword.put(opts, key, value)
  def maybe_add(opts, key, value) when is_integer(value), do: Keyword.put(opts, key, value)
  def maybe_add(opts, _key, _value), do: opts

  @doc """
  Parses a string to integer, returning nil on invalid input.

  ## Examples

      iex> Params.parse_int("42")
      42

      iex> Params.parse_int("not a number")
      nil

      iex> Params.parse_int(nil)
      nil

  """
  @spec parse_int(String.t() | nil) :: integer() | nil
  def parse_int(nil), do: nil

  def parse_int(str) when is_binary(str) do
    case Integer.parse(str) do
      {n, ""} -> n
      _ -> nil
    end
  end

  @doc """
  Parses a string to a positive integer ID, returning {:ok, id} or :error.

  ## Examples

      iex> Params.parse_id("4151")
      {:ok, 4151}

      iex> Params.parse_id("0")
      :error

      iex> Params.parse_id("abc")
      :error

  """
  @spec parse_id(String.t()) :: {:ok, pos_integer()} | :error
  def parse_id(str) when is_binary(str) do
    case Integer.parse(str) do
      {n, ""} when n > 0 -> {:ok, n}
      _ -> :error
    end
  end

  @doc """
  Builds pagination metadata from options and results.

  ## Examples

      iex> Params.build_meta([limit: 10, offset: 0], 5, 100)
      %{total: 100, limit: 10, offset: 0, has_more: true}

  """
  @spec build_meta(keyword(), non_neg_integer(), non_neg_integer()) :: map()
  def build_meta(opts, result_count, total) do
    limit = Keyword.get(opts, :limit, 100)
    offset = Keyword.get(opts, :offset, 0)

    %{
      total: total,
      limit: limit,
      offset: offset,
      has_more: offset + result_count < total
    }
  end
end
