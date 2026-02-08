defmodule Droodotfoo.Content.SVG.FiltersTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Content.SVG.Filters

  describe "blur/2" do
    test "creates blur filter with correct id" do
      result = Filters.blur("blur1", 5)
      assert result =~ ~s(id="blur1")
    end

    test "creates blur filter with correct stdDeviation" do
      result = Filters.blur("blur", 3.5)
      assert result =~ ~s(stdDeviation="3.5")
    end

    test "includes filter and feGaussianBlur elements" do
      result = Filters.blur("test", 1)
      assert result =~ "<filter"
      assert result =~ "</filter>"
      assert result =~ "feGaussianBlur"
    end
  end

  describe "glow/3" do
    test "creates glow filter with correct id" do
      result = Filters.glow("glow1", "#ffffff", 2)
      assert result =~ ~s(id="glow1")
    end

    test "includes blur and color matrix" do
      result = Filters.glow("glow", "#00ff00", 3)
      assert result =~ "feGaussianBlur"
      assert result =~ "feColorMatrix"
    end

    test "includes blend mode" do
      result = Filters.glow("glow", "#fff", 1)
      assert result =~ "feBlend"
    end
  end

  describe "shadow/4" do
    test "creates shadow with correct offsets" do
      result = Filters.shadow("shadow1", 2, 4, 3)
      assert result =~ ~s(dx="2")
      assert result =~ ~s(dy="4")
    end

    test "includes merge nodes for compositing" do
      result = Filters.shadow("shd", 1, 1, 2)
      assert result =~ "feMerge"
      assert result =~ "feMergeNode"
    end
  end

  describe "noise/2" do
    test "creates noise filter with turbulence" do
      result = Filters.noise("noise1", 0.05)
      assert result =~ ~s(id="noise1")
      assert result =~ "feTurbulence"
      assert result =~ ~s(baseFrequency="0.05")
    end

    test "uses fractalNoise type" do
      result = Filters.noise("n", 0.1)
      assert result =~ ~s(type="fractalNoise")
    end
  end

  describe "displacement/2" do
    test "creates displacement map filter" do
      result = Filters.displacement("disp1", 20)
      assert result =~ ~s(id="disp1")
      assert result =~ "feDisplacementMap"
      assert result =~ ~s(scale="20")
    end
  end

  describe "lighting/2" do
    test "creates lighting filter with color" do
      result = Filters.lighting("lit1", "#ffcc00")
      assert result =~ ~s(id="lit1")
      assert result =~ ~s(lighting-color="#ffcc00")
    end

    test "includes point light source" do
      result = Filters.lighting("lit", "#fff")
      assert result =~ "fePointLight"
    end
  end
end
