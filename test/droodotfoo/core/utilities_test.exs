defmodule Droodotfoo.Core.UtilitiesTest do
  use ExUnit.Case, async: true
  alias Droodotfoo.Core.Utilities

  describe "abbreviate_address/1" do
    test "abbreviates long Ethereum addresses" do
      address = "0x1234567890abcdef1234567890abcdef12345678"
      assert Utilities.abbreviate_address(address) == "0x1234...5678"
    end

    test "keeps short addresses unchanged" do
      assert Utilities.abbreviate_address("0x12") == "0x12"
      assert Utilities.abbreviate_address("short") == "short"
    end

    test "returns Unknown for invalid input" do
      assert Utilities.abbreviate_address(nil) == "Unknown"
      assert Utilities.abbreviate_address(123) == "Unknown"
    end
  end

  describe "valid_ethereum_address?/1" do
    test "validates correct Ethereum addresses" do
      assert Utilities.valid_ethereum_address?("0x1234567890abcdef1234567890abcdef12345678")
      assert Utilities.valid_ethereum_address?("0xABCDEF1234567890ABCDEF1234567890ABCDEF12")
    end

    test "rejects invalid addresses" do
      # too short
      refute Utilities.valid_ethereum_address?("0x123")
      # no 0x
      refute Utilities.valid_ethereum_address?("1234567890abcdef1234567890abcdef12345678")
      # invalid chars
      refute Utilities.valid_ethereum_address?("0x123456789012345678901234567890123456zzzz")
      refute Utilities.valid_ethereum_address?("invalid")
    end

    test "rejects non-string input" do
      refute Utilities.valid_ethereum_address?(nil)
      refute Utilities.valid_ethereum_address?(123)
    end
  end

  describe "format_file_size/1" do
    test "formats bytes" do
      assert Utilities.format_file_size(0) == "0 B"
      assert Utilities.format_file_size(512) == "512 B"
      assert Utilities.format_file_size(1023) == "1023 B"
    end

    test "formats kilobytes" do
      assert Utilities.format_file_size(1024) == "1.0 KB"
      assert Utilities.format_file_size(2048) == "2.0 KB"
      assert Utilities.format_file_size(1536) == "1.5 KB"
    end

    test "formats megabytes" do
      assert Utilities.format_file_size(1_048_576) == "1.0 MB"
      assert Utilities.format_file_size(2_097_152) == "2.0 MB"
      assert Utilities.format_file_size(1_572_864) == "1.5 MB"
    end

    test "formats gigabytes" do
      assert Utilities.format_file_size(1_073_741_824) == "1.0 GB"
      assert Utilities.format_file_size(2_147_483_648) == "2.0 GB"
    end
  end

  describe "truncate_text/2" do
    test "truncates long text" do
      text = "This is a very long piece of text"
      assert Utilities.truncate_text(text, 10) == "This is..."
      assert Utilities.truncate_text(text, 15) == "This is a ve..."
    end

    test "keeps short text unchanged" do
      assert Utilities.truncate_text("Short", 10) == "Short"
      assert Utilities.truncate_text("Hello", 5) == "Hello"
    end

    test "handles edge cases" do
      assert Utilities.truncate_text("", 10) == ""
      assert Utilities.truncate_text("Hi", 5) == "Hi"
    end
  end

  describe "random_string/1" do
    test "generates string of specified length" do
      str = Utilities.random_string(8)
      assert is_binary(str)
      assert String.length(str) == 8
    end

    test "generates unique strings" do
      str1 = Utilities.random_string(16)
      str2 = Utilities.random_string(16)
      assert str1 != str2
    end

    test "handles different lengths" do
      assert String.length(Utilities.random_string(1)) == 1
      assert String.length(Utilities.random_string(32)) == 32
    end
  end

  describe "safe_json_parse/1" do
    test "parses valid JSON" do
      assert {:ok, %{"key" => "value"}} = Utilities.safe_json_parse(~s({"key": "value"}))
      assert {:ok, %{"num" => 42}} = Utilities.safe_json_parse(~s({"num": 42}))
      assert {:ok, [1, 2, 3]} = Utilities.safe_json_parse(~s([1, 2, 3]))
    end

    test "returns error for invalid JSON" do
      assert {:error, :invalid_json} = Utilities.safe_json_parse("invalid json")
      assert {:error, :invalid_json} = Utilities.safe_json_parse("{incomplete")
      assert {:error, :invalid_json} = Utilities.safe_json_parse("")
    end
  end

  describe "pick_keys/2" do
    test "picks specified keys from map" do
      map = %{a: 1, b: 2, c: 3, d: 4}
      assert Utilities.pick_keys(map, [:a, :c]) == %{a: 1, c: 3}
    end

    test "ignores non-existent keys" do
      map = %{a: 1, b: 2}
      assert Utilities.pick_keys(map, [:a, :z]) == %{a: 1}
    end

    test "returns empty map when no keys match" do
      map = %{a: 1, b: 2}
      assert Utilities.pick_keys(map, [:x, :y]) == %{}
    end
  end

  describe "deep_merge/2" do
    test "merges nested maps" do
      left = %{a: 1, b: %{c: 2}}
      right = %{b: %{d: 3}}
      assert Utilities.deep_merge(left, right) == %{a: 1, b: %{c: 2, d: 3}}
    end

    test "right map takes precedence for conflicts" do
      left = %{a: 1, b: 2}
      right = %{b: 3, c: 4}
      assert Utilities.deep_merge(left, right) == %{a: 1, b: 3, c: 4}
    end

    test "handles deeply nested structures" do
      left = %{a: %{b: %{c: 1}}}
      right = %{a: %{b: %{d: 2}}}
      assert Utilities.deep_merge(left, right) == %{a: %{b: %{c: 1, d: 2}}}
    end
  end

  describe "map_to_sorted_tuples/1" do
    test "converts map to sorted key-value list" do
      map = %{c: 3, a: 1, b: 2}
      assert Utilities.map_to_sorted_tuples(map) == [a: 1, b: 2, c: 3]
    end

    test "handles empty map" do
      assert Utilities.map_to_sorted_tuples(%{}) == []
    end
  end

  describe "group_by/2" do
    test "groups list by key" do
      list = [%{type: "a", val: 1}, %{type: "b", val: 2}, %{type: "a", val: 3}]
      result = Utilities.group_by(list, :type)

      assert result["a"] == [%{type: "a", val: 1}, %{type: "a", val: 3}]
      assert result["b"] == [%{type: "b", val: 2}]
    end

    test "handles empty list" do
      assert Utilities.group_by([], :type) == %{}
    end
  end

  describe "progress_bar/2" do
    test "creates progress bar for percentages" do
      assert Utilities.progress_bar(0.0, 10) == "░░░░░░░░░░"
      assert Utilities.progress_bar(0.5, 10) == "█████░░░░░"
      assert Utilities.progress_bar(1.0, 10) == "██████████"
    end

    test "handles different widths" do
      # 0.5 * 5 = 2.5, rounds to 3
      assert Utilities.progress_bar(0.5, 5) == "███░░"
      assert Utilities.progress_bar(0.8, 5) == "████░"
    end

    test "rounds to nearest block" do
      # 0.55 * 10 = 5.5, rounds to 6
      assert Utilities.progress_bar(0.55, 10) == "██████░░░░"
      # 0.45 * 10 = 4.5, rounds to 5
      assert Utilities.progress_bar(0.45, 10) == "█████░░░░░"
    end
  end

  describe "slugify/1" do
    test "converts text to slug format" do
      assert Utilities.slugify("Hello World!") == "hello-world"
      assert Utilities.slugify("My Awesome Project") == "my-awesome-project"
    end

    test "handles special characters" do
      assert Utilities.slugify("Hello @#$ World") == "hello-world"
      assert Utilities.slugify("Test (123) & More") == "test-123-more"
    end

    test "handles multiple spaces" do
      assert Utilities.slugify("too   many    spaces") == "too-many-spaces"
    end

    test "trims leading and trailing dashes" do
      assert Utilities.slugify("  hello world  ") == "hello-world"
    end
  end

  describe "valid_email?/1" do
    test "validates correct email addresses" do
      assert Utilities.valid_email?("user@example.com")
      assert Utilities.valid_email?("test.user@domain.co.uk")
      assert Utilities.valid_email?("user+tag@example.com")
    end

    test "rejects invalid email addresses" do
      refute Utilities.valid_email?("invalid")
      refute Utilities.valid_email?("@example.com")
      refute Utilities.valid_email?("user@")
      refute Utilities.valid_email?("user @example.com")
    end

    test "rejects non-string input" do
      refute Utilities.valid_email?(nil)
      refute Utilities.valid_email?(123)
    end
  end
end
