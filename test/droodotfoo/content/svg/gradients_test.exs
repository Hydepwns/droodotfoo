defmodule Droodotfoo.Content.SVG.GradientsTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Content.SVG.Gradients

  describe "linear/3" do
    test "creates linear gradient with id" do
      stops = [{0, "#000", 1}, {100, "#fff", 1}]
      result = Gradients.linear("grad1", stops)
      assert result =~ ~s(id="grad1")
      assert result =~ "linearGradient"
    end

    test "uses default coordinates" do
      stops = [{0, "#000", 1}]
      result = Gradients.linear("grad", stops)
      assert result =~ ~s(x1="0%")
      assert result =~ ~s(y1="0%")
      assert result =~ ~s(x2="100%")
      assert result =~ ~s(y2="0%")
    end

    test "accepts custom coordinates" do
      stops = [{0, "#000", 1}]
      result = Gradients.linear("grad", stops, x1: "50%", y1: "0%", x2: "50%", y2: "100%")
      assert result =~ ~s(x1="50%")
      assert result =~ ~s(y2="100%")
    end

    test "renders stops with offset, color, and opacity" do
      stops = [{0, "#ff0000", 0.5}, {100, "#0000ff", 1}]
      result = Gradients.linear("grad", stops)
      assert result =~ ~s(offset="0%")
      assert result =~ ~s(stop-color="#ff0000")
      assert result =~ ~s(stop-opacity="0.5")
      assert result =~ ~s(offset="100%")
    end
  end

  describe "radial/3" do
    test "creates radial gradient with id" do
      stops = [{0, "#fff", 1}, {100, "#000", 1}]
      result = Gradients.radial("rad1", stops)
      assert result =~ ~s(id="rad1")
      assert result =~ "radialGradient"
    end

    test "uses default center and radius" do
      stops = [{0, "#fff", 1}]
      result = Gradients.radial("rad", stops)
      assert result =~ ~s(cx="50%")
      assert result =~ ~s(cy="50%")
      assert result =~ ~s(r="50%")
    end

    test "accepts custom center, radius, and focal point" do
      stops = [{0, "#fff", 1}]

      result =
        Gradients.radial("rad", stops, cx: "25%", cy: "25%", r: "75%", fx: "30%", fy: "30%")

      assert result =~ ~s(cx="25%")
      assert result =~ ~s(cy="25%")
      assert result =~ ~s(r="75%")
      assert result =~ ~s(fx="30%")
      assert result =~ ~s(fy="30%")
    end

    test "renders multiple stops" do
      stops = [{0, "#red", 1}, {50, "#green", 0.8}, {100, "#blue", 1}]
      result = Gradients.radial("multi", stops)
      assert result =~ ~s(offset="0%")
      assert result =~ ~s(offset="50%")
      assert result =~ ~s(offset="100%")
    end
  end
end
