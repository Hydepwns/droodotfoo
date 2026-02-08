defmodule Droodotfoo.Content.SVG.StylesTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Content.SVG.Styles

  describe "stroke/3" do
    test "creates stroke attributes map" do
      result = Styles.stroke("#ff0000", 2, 0.8)

      assert result.stroke == "#ff0000"
      assert result[:"stroke-width"] == 2
      assert result.opacity == 0.8
      assert result.fill == "none"
    end

    test "handles decimal stroke width" do
      result = Styles.stroke("#000", 1.5, 1)
      assert result[:"stroke-width"] == 1.5
    end
  end

  describe "fill/2" do
    test "creates fill attributes map" do
      result = Styles.fill("#00ff00", 0.5)

      assert result.fill == "#00ff00"
      assert result.opacity == 0.5
    end

    test "handles full opacity" do
      result = Styles.fill("#blue", 1)
      assert result.opacity == 1
    end
  end
end
