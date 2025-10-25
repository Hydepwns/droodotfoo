defmodule Droodotfoo.Content.RandomGenerator do
  @moduledoc """
  Encapsulates random number generation for deterministic pattern generation.

  Uses an explicit random state instead of global :rand state, making
  pattern generation testable and predictable.
  """

  @type t :: :rand.state()
  @type range :: %{min: number, max: number}

  @doc """
  Creates a new random generator with a deterministic seed.

  ## Examples

      iex> rng = RandomGenerator.new("my-slug")
      iex> {value, _rng} = RandomGenerator.uniform(rng)
      iex> value >= 0 and value <= 1
      true
  """
  @spec new(String.t() | integer) :: t
  def new(seed) when is_binary(seed) do
    hash = :erlang.phash2(seed)
    new(hash)
  end

  def new(seed) when is_integer(seed) do
    :rand.seed(:exsplus, {seed, seed, seed})
  end

  @doc """
  Generates a random float between 0 and 1.
  Returns {value, new_state}.

  ## Examples

      iex> rng = RandomGenerator.new(12345)
      iex> {value, _rng} = RandomGenerator.uniform(rng)
      iex> is_float(value)
      true
  """
  @spec uniform(t) :: {float, t}
  def uniform(rng) do
    :rand.uniform_s(rng)
  end

  @doc """
  Generates a random integer between 1 and n (inclusive).
  Returns {value, new_state}.

  ## Examples

      iex> rng = RandomGenerator.new(12345)
      iex> {value, _rng} = RandomGenerator.uniform_int(rng, 10)
      iex> value >= 1 and value <= 10
      true
  """
  @spec uniform_int(t, pos_integer) :: {pos_integer, t}
  def uniform_int(rng, n) when is_integer(n) and n > 0 do
    :rand.uniform_s(n, rng)
  end

  @doc """
  Generates a random number within a range.
  Returns {value, new_state}.

  ## Examples

      iex> rng = RandomGenerator.new(12345)
      iex> {value, _rng} = RandomGenerator.uniform_range(rng, {10, 20})
      iex> value >= 10 and value <= 20
      true

      iex> rng = RandomGenerator.new(12345)
      iex> {value, _rng} = RandomGenerator.uniform_range(rng, {5.0, 10.0})
      iex> value >= 5.0 and value <= 10.0
      true
  """
  @spec uniform_range(t, range) :: {number, t}
  def uniform_range(rng, %{min: min, max: max}) when is_integer(min) and is_integer(max) do
    {rand_val, new_rng} = uniform_int(rng, max - min + 1)
    {min + rand_val - 1, new_rng}
  end

  def uniform_range(rng, %{min: min, max: max}) when is_number(min) and is_number(max) do
    {rand_val, new_rng} = uniform(rng)
    {min + rand_val * (max - min), new_rng}
  end

  @doc """
  Generates a random float in a specific range.
  Returns {value, new_state}.

  ## Examples

      iex> rng = RandomGenerator.new(12345)
      iex> {value, _rng} = RandomGenerator.uniform_float(rng, 5.0, 10.0)
      iex> value >= 5.0 and value <= 10.0
      true
  """
  @spec uniform_float(t, float, float) :: {float, t}
  def uniform_float(rng, min, max) when is_number(min) and is_number(max) do
    {rand_val, new_rng} = uniform(rng)
    {min + rand_val * (max - min), new_rng}
  end

  @doc """
  Generates a random integer in a specific range.
  Returns {value, new_state}.

  ## Examples

      iex> rng = RandomGenerator.new(12345)
      iex> {value, _rng} = RandomGenerator.uniform_int_range(rng, 5, 10)
      iex> value >= 5 and value <= 10
      true
  """
  @spec uniform_int_range(t, integer, integer) :: {integer, t}
  def uniform_int_range(rng, min, max) when is_integer(min) and is_integer(max) do
    {rand_val, new_rng} = uniform_int(rng, max - min + 1)
    {min + rand_val - 1, new_rng}
  end

  @doc """
  Returns a random boolean based on probability.
  Returns {true/false, new_state}.

  ## Examples

      iex> rng = RandomGenerator.new(12345)
      iex> {value, _rng} = RandomGenerator.chance(rng, 0.5)
      iex> is_boolean(value)
      true
  """
  @spec chance(t, float) :: {boolean, t}
  def chance(rng, probability) when probability >= 0 and probability <= 1 do
    {rand_val, new_rng} = uniform(rng)
    {rand_val < probability, new_rng}
  end

  @doc """
  Picks a random element from a list.
  Returns {element, new_state}.

  ## Examples

      iex> rng = RandomGenerator.new(12345)
      iex> {value, _rng} = RandomGenerator.choice(rng, [:a, :b, :c])
      iex> value in [:a, :b, :c]
      true
  """
  @spec choice(t, [any]) :: {any, t}
  def choice(rng, list) when is_list(list) and length(list) > 0 do
    {index, new_rng} = uniform_int(rng, length(list))
    {Enum.at(list, index - 1), new_rng}
  end

  @doc """
  Generates multiple random values using a generator function.
  Returns {[values], new_state}.

  This is useful for generating lists of random elements while threading
  the RNG state through each generation.

  ## Examples

      iex> rng = RandomGenerator.new(12345)
      iex> generator = fn rng -> RandomGenerator.uniform_int(rng, 10) end
      iex> {values, _rng} = RandomGenerator.generate_list(rng, 5, generator)
      iex> length(values)
      5
  """
  @spec generate_list(t, non_neg_integer, (t -> {any, t})) :: {[any], t}
  def generate_list(rng, count, generator_fn) do
    Enum.map_reduce(1..count, rng, fn _, acc_rng ->
      generator_fn.(acc_rng)
    end)
  end

  @doc """
  Generates a random offset value (can be negative or positive).
  Returns {value, new_state}.

  ## Examples

      iex> rng = RandomGenerator.new(12345)
      iex> {value, _rng} = RandomGenerator.offset(rng, -10, 10)
      iex> value >= -10 and value <= 10
      true
  """
  @spec offset(t, number, number) :: {number, t}
  def offset(rng, min, max) when is_number(min) and is_number(max) do
    {rand_val, new_rng} = uniform(rng)
    {min + rand_val * (max - min), new_rng}
  end
end
