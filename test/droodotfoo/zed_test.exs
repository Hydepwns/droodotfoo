defmodule Droodotfoo.ZedTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Zed

  describe "format_count/1" do
    test "formats millions" do
      assert Zed.format_count(1_000_000) == "1.0M"
      assert Zed.format_count(1_500_000) == "1.5M"
      assert Zed.format_count(10_000_000) == "10.0M"
    end

    test "formats thousands" do
      assert Zed.format_count(1_000) == "1.0k"
      assert Zed.format_count(1_500) == "1.5k"
      assert Zed.format_count(19_600) == "19.6k"
      # 999_999 is just under 1M so it still uses k format
      result = Zed.format_count(999_999)
      assert result =~ "k"
    end

    test "formats small numbers as-is" do
      assert Zed.format_count(0) == "0"
      assert Zed.format_count(1) == "1"
      assert Zed.format_count(999) == "999"
    end

    test "rounds to one decimal place" do
      assert Zed.format_count(1_234) == "1.2k"
      assert Zed.format_count(1_567) == "1.6k"
    end
  end
end
