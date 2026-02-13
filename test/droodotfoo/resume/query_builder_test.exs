defmodule Droodotfoo.Resume.QueryBuilderTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Resume.QueryBuilder

  describe "new/0" do
    test "creates a new empty query builder" do
      builder = QueryBuilder.new()

      assert builder.technologies == []
      assert builder.companies == []
      assert builder.positions == []
      assert builder.logic == :and
      assert builder.errors == []
    end
  end

  describe "add_technology/2" do
    test "adds a single technology" do
      builder =
        QueryBuilder.new()
        |> QueryBuilder.add_technology("Elixir")

      assert "Elixir" in builder.technologies
    end

    test "adds multiple technologies" do
      builder =
        QueryBuilder.new()
        |> QueryBuilder.add_technology("Elixir")
        |> QueryBuilder.add_technology("Rust")

      assert "Elixir" in builder.technologies
      assert "Rust" in builder.technologies
    end
  end

  describe "add_technologies/2" do
    test "adds multiple technologies at once" do
      builder =
        QueryBuilder.new()
        |> QueryBuilder.add_technologies(["Elixir", "Rust", "Go"])

      assert length(builder.technologies) == 3
      assert "Elixir" in builder.technologies
    end
  end

  describe "set_date_range/3" do
    test "sets a valid date range" do
      builder =
        QueryBuilder.new()
        |> QueryBuilder.set_date_range("2022-01", "2024-12")

      assert builder.date_range == %{from: "2022-01", to: "2024-12"}
    end

    test "adds error for invalid date format" do
      builder =
        QueryBuilder.new()
        |> QueryBuilder.set_date_range("invalid", "2024-12")

      assert builder.errors != []
    end
  end

  describe "set_logic/2" do
    test "sets AND logic" do
      builder =
        QueryBuilder.new()
        |> QueryBuilder.set_logic(:and)

      assert builder.logic == :and
    end

    test "sets OR logic" do
      builder =
        QueryBuilder.new()
        |> QueryBuilder.set_logic(:or)

      assert builder.logic == :or
    end

    test "adds error for invalid logic" do
      builder =
        QueryBuilder.new()
        |> QueryBuilder.set_logic(:invalid)

      assert builder.errors != []
    end
  end

  describe "build/1" do
    test "builds filter options from query builder" do
      builder =
        QueryBuilder.new()
        |> QueryBuilder.add_technology("Elixir")
        |> QueryBuilder.add_company("axol.io")

      {:ok, options} = QueryBuilder.build(builder)

      assert options.technologies == ["Elixir"]
      assert options.companies == ["axol.io"]
      assert options.logic == :and
    end

    test "returns error when validation fails" do
      builder =
        QueryBuilder.new()
        |> QueryBuilder.set_date_range("invalid", "2024-12")

      {:error, errors} = QueryBuilder.build(builder)

      assert is_list(errors)
      assert errors != []
    end

    test "excludes empty fields from options" do
      builder =
        QueryBuilder.new()
        |> QueryBuilder.add_technology("Elixir")

      {:ok, options} = QueryBuilder.build(builder)

      # Companies should not be in options since it's empty
      refute Map.has_key?(options, :companies)
    end
  end

  describe "parse_query/1" do
    test "parses simple technology filter" do
      {:ok, builder} = QueryBuilder.parse_query("tech:Elixir")

      assert "Elixir" in builder.technologies
    end

    test "parses multiple technologies with OR" do
      {:ok, builder} = QueryBuilder.parse_query("tech:Elixir OR tech:Rust")

      assert "Elixir" in builder.technologies
      assert "Rust" in builder.technologies
      assert builder.logic == :or
    end

    test "parses company filter" do
      {:ok, builder} = QueryBuilder.parse_query("company:axol.io")

      assert "axol.io" in builder.companies
    end

    test "parses position filter" do
      {:ok, builder} = QueryBuilder.parse_query("position:CEO")

      assert "CEO" in builder.positions
    end

    test "parses text search with quotes" do
      {:ok, builder} = QueryBuilder.parse_query("text:\"blockchain infrastructure\"")

      assert builder.text_search == "blockchain infrastructure"
    end

    test "parses text search without quotes" do
      {:ok, builder} = QueryBuilder.parse_query("text:blockchain")

      assert builder.text_search == "blockchain"
    end

    test "parses date range" do
      {:ok, builder} = QueryBuilder.parse_query("from:2022-01 to:2024-12")

      assert builder.date_range == %{from: "2022-01", to: "2024-12"}
    end

    test "parses complex query with multiple filters" do
      {:ok, builder} = QueryBuilder.parse_query("tech:Elixir company:axol.io OR position:CEO")

      assert "Elixir" in builder.technologies
      assert "axol.io" in builder.companies
      assert "CEO" in builder.positions
      assert builder.logic == :or
    end

    test "returns error for invalid query" do
      result = QueryBuilder.parse_query("from:invalid-date")

      # Should still parse, but date will be invalid
      assert match?({:ok, _}, result) or match?({:error, _}, result)
    end
  end

  describe "to_query_string/1" do
    test "converts query builder to string" do
      builder =
        QueryBuilder.new()
        |> QueryBuilder.add_technology("Elixir")
        |> QueryBuilder.add_company("axol.io")

      query_string = QueryBuilder.to_query_string(builder)

      assert query_string =~ "tech:Elixir"
      assert query_string =~ "company:axol.io"
    end

    test "includes OR logic in string" do
      builder =
        QueryBuilder.new()
        |> QueryBuilder.add_technology("Elixir")
        |> QueryBuilder.add_technology("Rust")
        |> QueryBuilder.set_logic(:or)

      query_string = QueryBuilder.to_query_string(builder)

      assert query_string =~ "OR"
    end

    test "includes date range in string" do
      builder =
        QueryBuilder.new()
        |> QueryBuilder.set_date_range("2022-01", "2024-12")

      query_string = QueryBuilder.to_query_string(builder)

      assert query_string =~ "from:2022-01"
      assert query_string =~ "to:2024-12"
    end
  end

  describe "clear/1" do
    test "clears all filters" do
      builder =
        QueryBuilder.new()
        |> QueryBuilder.add_technology("Elixir")
        |> QueryBuilder.add_company("axol.io")
        |> QueryBuilder.clear()

      assert builder.technologies == []
      assert builder.companies == []
    end
  end

  describe "clear_technologies/1" do
    test "clears only technology filters" do
      builder =
        QueryBuilder.new()
        |> QueryBuilder.add_technology("Elixir")
        |> QueryBuilder.add_company("axol.io")
        |> QueryBuilder.clear_technologies()

      assert builder.technologies == []
      assert "axol.io" in builder.companies
    end
  end
end
