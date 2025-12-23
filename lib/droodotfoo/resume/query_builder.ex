defmodule Droodotfoo.Resume.QueryBuilder do
  @moduledoc """
  Builds and validates filter queries for resume data.

  Provides a fluent API for constructing complex filter combinations:
  - Chainable filter operations
  - AND/OR logic composition
  - Query validation and normalization
  - Human-readable query strings

  ## Examples

      iex> QueryBuilder.new()
      ...> |> QueryBuilder.add_technology("Elixir")
      ...> |> QueryBuilder.add_company("axol.io")
      ...> |> QueryBuilder.build()
      %{technologies: ["Elixir"], companies: ["axol.io"], logic: :and}

      iex> QueryBuilder.parse_query("tech:Elixir OR tech:Rust company:LidoDAO")
      %{technologies: ["Elixir", "Rust"], companies: ["LidoDAO"], logic: :or}

  """

  defstruct technologies: [],
            companies: [],
            positions: [],
            date_range: nil,
            text_search: nil,
            logic: :and,
            include_sections: [
              :experience,
              :education,
              :defense_projects,
              :portfolio,
              :certifications
            ],
            errors: []

  @type t :: %__MODULE__{
          technologies: list(String.t()),
          companies: list(String.t()),
          positions: list(String.t()),
          date_range: %{from: String.t(), to: String.t()} | nil,
          text_search: String.t() | nil,
          logic: :and | :or,
          include_sections: list(atom()),
          errors: list(String.t())
        }

  @doc """
  Creates a new query builder instance.
  """
  @spec new() :: t()
  def new do
    %__MODULE__{}
  end

  @doc """
  Adds a technology filter to the query.

  ## Examples

      iex> QueryBuilder.new() |> QueryBuilder.add_technology("Elixir")
      %QueryBuilder{technologies: ["Elixir"]}

  """
  @spec add_technology(t(), String.t()) :: t()
  def add_technology(%__MODULE__{} = builder, technology) when is_binary(technology) do
    %{builder | technologies: [technology | builder.technologies]}
  end

  @doc """
  Adds multiple technologies to the query.
  """
  @spec add_technologies(t(), list(String.t())) :: t()
  def add_technologies(%__MODULE__{} = builder, technologies) when is_list(technologies) do
    %{builder | technologies: technologies ++ builder.technologies}
  end

  @doc """
  Adds a company filter to the query.
  """
  @spec add_company(t(), String.t()) :: t()
  def add_company(%__MODULE__{} = builder, company) when is_binary(company) do
    %{builder | companies: [company | builder.companies]}
  end

  @doc """
  Adds multiple companies to the query.
  """
  @spec add_companies(t(), list(String.t())) :: t()
  def add_companies(%__MODULE__{} = builder, companies) when is_list(companies) do
    %{builder | companies: companies ++ builder.companies}
  end

  @doc """
  Adds a position filter to the query.
  """
  @spec add_position(t(), String.t()) :: t()
  def add_position(%__MODULE__{} = builder, position) when is_binary(position) do
    %{builder | positions: [position | builder.positions]}
  end

  @doc """
  Adds multiple positions to the query.
  """
  @spec add_positions(t(), list(String.t())) :: t()
  def add_positions(%__MODULE__{} = builder, positions) when is_list(positions) do
    %{builder | positions: positions ++ builder.positions}
  end

  @doc """
  Sets a date range filter.

  ## Examples

      iex> QueryBuilder.new()
      ...> |> QueryBuilder.set_date_range("2022-01", "2024-12")
      %QueryBuilder{date_range: %{from: "2022-01", to: "2024-12"}}

  """
  @spec set_date_range(t(), String.t(), String.t()) :: t()
  def set_date_range(%__MODULE__{} = builder, from_date, to_date) do
    case validate_date_range(from_date, to_date) do
      :ok ->
        %{builder | date_range: %{from: from_date, to: to_date}}

      {:error, reason} ->
        add_error(builder, "Invalid date range: #{reason}")
    end
  end

  @doc """
  Sets a text search query.
  """
  @spec set_text_search(t(), String.t()) :: t()
  def set_text_search(%__MODULE__{} = builder, query) when is_binary(query) do
    %{builder | text_search: String.trim(query)}
  end

  @doc """
  Sets the logic operator (AND or OR).
  """
  @spec set_logic(t(), :and | :or) :: t()
  def set_logic(%__MODULE__{} = builder, logic) when logic in [:and, :or] do
    %{builder | logic: logic}
  end

  def set_logic(%__MODULE__{} = builder, invalid) do
    add_error(builder, "Invalid logic operator: #{inspect(invalid)}. Must be :and or :or")
  end

  @doc """
  Sets which sections to include in the results.
  """
  @spec set_sections(t(), list(atom())) :: t()
  def set_sections(%__MODULE__{} = builder, sections) when is_list(sections) do
    valid_sections = [:experience, :education, :defense_projects, :portfolio, :certifications]

    case validate_sections(sections, valid_sections) do
      :ok ->
        %{builder | include_sections: sections}

      {:error, invalid} ->
        add_error(builder, "Invalid sections: #{inspect(invalid)}")
    end
  end

  @doc """
  Clears all filters from the query.
  """
  @spec clear(t()) :: t()
  def clear(%__MODULE__{}) do
    new()
  end

  @doc """
  Clears technology filters only.
  """
  @spec clear_technologies(t()) :: t()
  def clear_technologies(%__MODULE__{} = builder) do
    %{builder | technologies: []}
  end

  @doc """
  Clears company filters only.
  """
  @spec clear_companies(t()) :: t()
  def clear_companies(%__MODULE__{} = builder) do
    %{builder | companies: []}
  end

  @doc """
  Builds the final filter options map for FilterEngine.
  """
  @spec build(t()) :: {:ok, map()} | {:error, list(String.t())}
  def build(%__MODULE__{errors: []} = builder) do
    options =
      %{}
      |> maybe_add(:technologies, builder.technologies)
      |> maybe_add(:companies, builder.companies)
      |> maybe_add(:positions, builder.positions)
      |> maybe_add(:date_range, builder.date_range)
      |> maybe_add(:text_search, builder.text_search)
      |> Map.put(:logic, builder.logic)
      |> Map.put(:include_sections, builder.include_sections)

    {:ok, options}
  end

  def build(%__MODULE__{errors: errors}) do
    {:error, Enum.reverse(errors)}
  end

  @doc """
  Validates a query and returns errors if any.
  """
  @spec validate(t()) :: :ok | {:error, list(String.t())}
  def validate(%__MODULE__{errors: []}) do
    :ok
  end

  def validate(%__MODULE__{errors: errors}) do
    {:error, Enum.reverse(errors)}
  end

  @doc """
  Parses a human-readable query string into a QueryBuilder.

  ## Supported Syntax

    * `tech:Elixir` - Technology filter
    * `company:axol.io` - Company filter
    * `position:CEO` - Position filter
    * `text:"blockchain infrastructure"` - Text search (quotes optional)
    * `from:2022-01 to:2024-12` - Date range
    * `OR` / `AND` - Logic operators
    * `sections:experience,education` - Limit sections

  ## Examples

      iex> QueryBuilder.parse_query("tech:Elixir tech:Rust OR company:LidoDAO")
      {:ok, %QueryBuilder{technologies: ["Rust", "Elixir"], companies: ["LidoDAO"], logic: :or}}

      iex> QueryBuilder.parse_query("text:blockchain from:2022-01 to:2024-12")
      {:ok, %QueryBuilder{text_search: "blockchain", date_range: %{...}}}

  """
  @spec parse_query(String.t()) :: {:ok, t()} | {:error, String.t()}
  def parse_query(query_string) when is_binary(query_string) do
    builder = new()

    tokens = tokenize_query(query_string)
    result = parse_tokens(tokens, builder)

    case validate(result) do
      :ok -> {:ok, result}
      {:error, errors} -> {:error, Enum.join(errors, "; ")}
    end
  end

  @doc """
  Converts a QueryBuilder to a human-readable string.

  ## Examples

      iex> builder = QueryBuilder.new()
      ...>   |> QueryBuilder.add_technology("Elixir")
      ...>   |> QueryBuilder.add_company("axol.io")
      iex> QueryBuilder.to_query_string(builder)
      "tech:Elixir company:axol.io"

  """
  @spec to_query_string(t()) :: String.t()
  def to_query_string(%__MODULE__{} = builder) do
    parts = []

    parts = parts ++ Enum.map(builder.technologies, &"tech:#{&1}")
    parts = parts ++ Enum.map(builder.companies, &"company:#{&1}")
    parts = parts ++ Enum.map(builder.positions, &"position:#{&1}")

    parts =
      if builder.text_search do
        parts ++ ["text:\"#{builder.text_search}\""]
      else
        parts
      end

    parts =
      if builder.date_range do
        parts ++ ["from:#{builder.date_range.from}", "to:#{builder.date_range.to}"]
      else
        parts
      end

    parts =
      if builder.logic == :or do
        Enum.intersperse(parts, "OR")
      else
        parts
      end

    Enum.join(parts, " ")
  end

  # Private helper functions

  defp add_error(%__MODULE__{} = builder, error) do
    %{builder | errors: [error | builder.errors]}
  end

  defp maybe_add(map, _key, []), do: map
  defp maybe_add(map, _key, nil), do: map
  defp maybe_add(map, _key, ""), do: map
  defp maybe_add(map, key, value), do: Map.put(map, key, value)

  defp validate_date_range(from_date, to_date) do
    with {:ok, _from} <- parse_date_format(from_date),
         {:ok, _to} <- parse_date_format(to_date) do
      :ok
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_date_format(date_string) when is_binary(date_string) do
    case String.split(date_string, "-") do
      [year, month] when byte_size(year) == 4 and byte_size(month) in [1, 2] ->
        {:ok, date_string}

      _ ->
        {:error, "Date must be in YYYY-MM format"}
    end
  end

  defp validate_sections(sections, valid_sections) do
    invalid = Enum.filter(sections, &(&1 not in valid_sections))

    if Enum.empty?(invalid) do
      :ok
    else
      {:error, invalid}
    end
  end

  # Query parsing

  defp tokenize_query(query_string) do
    # Split by spaces but preserve quoted strings
    query_string
    |> String.split(~r/\s+(?=(?:[^"]*"[^"]*")*[^"]*$)/)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp parse_tokens([], builder), do: builder

  defp parse_tokens(["OR" | rest], builder) do
    parse_tokens(rest, set_logic(builder, :or))
  end

  defp parse_tokens(["AND" | rest], builder) do
    parse_tokens(rest, set_logic(builder, :and))
  end

  defp parse_tokens([token | rest], builder) do
    updated_builder = apply_token(parse_token(token), builder, token)
    parse_tokens(rest, updated_builder)
  end

  defp apply_token({:tech, value}, builder, _original), do: add_technology(builder, value)
  defp apply_token({:company, value}, builder, _original), do: add_company(builder, value)
  defp apply_token({:position, value}, builder, _original), do: add_position(builder, value)
  defp apply_token({:text, value}, builder, _original), do: set_text_search(builder, value)

  defp apply_token({:from, value}, builder, _original) do
    %{builder | date_range: %{from: value, to: nil}}
  end

  defp apply_token({:to, value}, builder, _original) do
    from = get_in(builder.date_range, [:from]) || "1900-01"
    set_date_range(builder, from, value)
  end

  # Valid section names for safe atom conversion (prevents atom DoS)
  @valid_section_strings ~w(experience education defense_projects portfolio certifications)

  defp apply_token({:sections, value}, builder, _original) do
    sections =
      value
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.filter(&(&1 in @valid_section_strings))
      |> Enum.map(&String.to_existing_atom/1)

    set_sections(builder, sections)
  end

  defp apply_token({:unknown, _value}, builder, original_token) do
    set_text_search(builder, original_token)
  end

  defp parse_token(token) do
    case String.split(token, ":", parts: 2) do
      ["tech", value] -> {:tech, strip_quotes(value)}
      ["company", value] -> {:company, strip_quotes(value)}
      ["position", value] -> {:position, strip_quotes(value)}
      ["text", value] -> {:text, strip_quotes(value)}
      ["from", value] -> {:from, strip_quotes(value)}
      ["to", value] -> {:to, strip_quotes(value)}
      ["sections", value] -> {:sections, strip_quotes(value)}
      _ -> {:unknown, token}
    end
  end

  defp strip_quotes(string) do
    string
    |> String.trim()
    |> String.trim("\"")
    |> String.trim("'")
  end
end
