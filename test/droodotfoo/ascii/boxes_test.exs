defmodule Droodotfoo.Ascii.BoxesTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Ascii.Boxes

  describe "message_box/3" do
    test "creates box with error severity" do
      result = Boxes.message_box("Test error", :error)
      box_text = Enum.join(result, "\n")
      assert box_text =~ "ERROR"
      assert box_text =~ "!"
    end

    test "creates box with warning severity" do
      result = Boxes.message_box("Test warning", :warning)
      box_text = Enum.join(result, "\n")
      assert box_text =~ "WARNING"
      assert box_text =~ "*"
    end

    test "creates box with info severity" do
      result = Boxes.message_box("Test info", :info)
      box_text = Enum.join(result, "\n")
      assert box_text =~ "INFO"
    end

    test "creates box with success severity" do
      result = Boxes.message_box("Test success", :success)
      box_text = Enum.join(result, "\n")
      assert box_text =~ "SUCCESS"
      assert box_text =~ "+"
    end

    test "wraps long messages" do
      long_message = String.duplicate("word ", 30)
      result = Boxes.message_box(long_message, :info, width: 40)
      # Should have multiple content lines
      assert length(result) > 3
    end

    test "returns list of strings" do
      result = Boxes.message_box("Test", :info)
      assert is_list(result)
      assert Enum.all?(result, &is_binary/1)
    end

    test "respects width option" do
      result = Boxes.message_box("Short", :info, width: 30)
      # Top and bottom borders should be consistent width
      [top | _] = result
      assert String.contains?(top, "+")
    end
  end

  describe "meter/3" do
    test "creates meter with title" do
      result = Boxes.meter("CPU", 50)
      box_text = Enum.join(result, "\n")
      assert box_text =~ "CPU"
    end

    test "returns 3 lines" do
      result = Boxes.meter("Test", 75)
      assert length(result) == 3
    end

    test "includes percentage" do
      result = Boxes.meter("Usage", 42)
      bottom = List.last(result)
      assert bottom =~ "%"
    end
  end

  describe "progress/3" do
    test "calculates percentage from current and total" do
      result = Boxes.progress(50, 100)
      bottom = List.last(result)
      assert bottom =~ "50%"
    end

    test "handles zero total" do
      result = Boxes.progress(10, 0)
      bottom = List.last(result)
      assert bottom =~ "0%"
    end

    test "uses custom label" do
      result = Boxes.progress(25, 100, label: "Loading")
      top = hd(result)
      assert top =~ "Loading"
    end

    test "respects width option" do
      result = Boxes.progress(50, 100, width: 40)
      assert length(result) == 3
    end
  end

  describe "suggestion_box/2" do
    test "creates hint box with default icon" do
      result = Boxes.suggestion_box("Try this")
      box_text = Enum.join(result, "\n")
      assert box_text =~ "Hint"
      assert box_text =~ "+"
    end

    test "uses custom icon" do
      result = Boxes.suggestion_box("Info", icon: "?")
      top = hd(result)
      assert top =~ "?"
    end

    test "wraps long suggestions" do
      long_suggestion = String.duplicate("suggestion ", 20)
      result = Boxes.suggestion_box(long_suggestion, width: 40)
      # Should have multiple content lines
      assert length(result) > 3
    end
  end
end
