defmodule Droodotfoo.TerminalBridgeTest do
  use ExUnit.Case, async: false
  # TerminalBridge archived - tests skipped until reactivation
  @moduletag :skip
  alias Droodotfoo.TerminalBridge

  setup do
    # The TerminalBridge is already started by the application
    # Just ensure it's running for tests that need it
    case Process.whereis(TerminalBridge) do
      nil ->
        {:ok, pid} = start_supervised(TerminalBridge)
        {:ok, bridge_pid: pid}

      pid when is_pid(pid) ->
        {:ok, bridge_pid: pid}
    end
  end

  # Helper functions for working with the new buffer structure
  defp get_buffer_line(buffer, n), do: Enum.at(buffer.lines, n)

  defp get_cell(buffer, x, y) do
    buffer.lines
    |> Enum.at(y)
    |> case do
      nil -> nil
      line -> Enum.at(line.cells, x)
    end
  end

  defp default_style do
    %{
      bold: false,
      italic: false,
      underline: false,
      fg_color: nil,
      bg_color: nil,
      reverse: false
    }
  end

  describe "buffer creation" do
    test "creates blank buffer with correct dimensions" do
      buffer = TerminalBridge.create_blank_buffer(80, 24)

      assert buffer.width == 80
      assert buffer.height == 24
      assert length(buffer.lines) == 24

      assert Enum.all?(buffer.lines, fn line ->
               length(line.cells) == 80
             end)
    end

    test "blank buffer contains empty cells" do
      buffer = TerminalBridge.create_blank_buffer(10, 5)

      assert Enum.all?(buffer.lines, fn line ->
               Enum.all?(line.cells, fn cell ->
                 cell.char == " " && cell.style == default_style()
               end)
             end)
    end
  end

  describe "writing to buffer" do
    test "write_at places text at correct position" do
      buffer = TerminalBridge.create_blank_buffer(20, 5)
      buffer = TerminalBridge.write_at(buffer, 5, 2, "Hello")

      line = get_buffer_line(buffer, 2)
      chars = line.cells |> Enum.drop(5) |> Enum.take(5) |> Enum.map_join("", & &1.char)
      assert chars == "Hello"
    end

    test "write_at respects buffer boundaries" do
      buffer = TerminalBridge.create_blank_buffer(10, 5)
      buffer = TerminalBridge.write_at(buffer, 8, 2, "Testing")

      line = get_buffer_line(buffer, 2)
      visible_chars = line.cells |> Enum.drop(8) |> Enum.map_join("", & &1.char)
      # Only "Te" should fit
      assert String.length(visible_chars) == 2
    end
  end

  describe "box drawing" do
    test "draw_box creates single border" do
      buffer = TerminalBridge.create_blank_buffer(20, 10)
      buffer = TerminalBridge.draw_box(buffer, 2, 2, 10, 5, :single)

      # Check top-left corner
      top_left = get_cell(buffer, 2, 2)
      assert top_left.char in ["┌", "╭"]

      # Check top-right corner
      top_right = get_cell(buffer, 11, 2)
      assert top_right.char in ["┐", "╮"]
    end

    test "draw_box creates double border" do
      buffer = TerminalBridge.create_blank_buffer(20, 10)
      buffer = TerminalBridge.draw_box(buffer, 2, 2, 10, 5, :double)

      # Check for double border characters
      top_left = get_cell(buffer, 2, 2)
      assert top_left.char == "╔"
    end
  end

  describe "buffer to HTML conversion" do
    test "converts buffer to HTML grid", %{bridge_pid: _pid} do
      # Clear cache to ensure fresh state
      TerminalBridge.invalidate_cache()

      buffer =
        TerminalBridge.create_blank_buffer(5, 3)
        |> TerminalBridge.write_at(0, 1, "Test")

      html = TerminalBridge.terminal_to_html(buffer)

      assert html =~ "<div"
      assert html =~ "terminal-line"

      # Check that each character appears in the HTML
      "Test"
      |> String.graphemes()
      |> Enum.each(fn char ->
        assert html =~ char
      end)
    end

    test "applies style classes correctly", %{bridge_pid: _pid} do
      # Clear cache to ensure fresh state
      TerminalBridge.invalidate_cache()

      buffer = TerminalBridge.create_blank_buffer(10, 2)

      # Update first cell with bold style using functional approach
      buffer = %{
        buffer
        | lines:
            buffer.lines
            |> List.update_at(0, fn line ->
              %{
                line
                | cells:
                    line.cells
                    |> List.update_at(0, fn _cell ->
                      %{char: "B", style: %{default_style() | bold: true}}
                    end)
              }
            end)
      }

      html = TerminalBridge.terminal_to_html(buffer)

      # Verify bold styling is applied
      assert html =~ "bold" or html =~ "font-weight"
      assert html =~ "B"
    end
  end

  describe "text alignment" do
    test "centers text correctly" do
      buffer = TerminalBridge.create_blank_buffer(20, 5)
      text = "Center"
      x = div(20 - String.length(text), 2)

      buffer = TerminalBridge.write_at(buffer, x, 2, text)

      line = get_buffer_line(buffer, 2)
      # Text should be roughly centered
      before_text = line.cells |> Enum.take(x) |> Enum.filter(&(&1.char != " ")) |> length()
      assert before_text == 0
    end
  end
end
