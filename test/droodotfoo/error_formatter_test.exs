defmodule Droodotfoo.ErrorFormatterTest do
  use ExUnit.Case, async: true
  alias Droodotfoo.ErrorFormatter

  describe "format/2" do
    test "formats a simple error message" do
      result = ErrorFormatter.format("command not found")

      assert result =~ "╔═"
      assert result =~ "ERROR"
      assert result =~ "command not found"
      assert result =~ "╚═"
    end

    test "formats error with custom width" do
      result = ErrorFormatter.format("error", width: 30)

      lines = String.split(result, "\n")
      first_line = List.first(lines)
      assert String.length(first_line) == 30
    end

    test "formats warning message" do
      result = ErrorFormatter.format("this is a warning", type: :warning)

      assert result =~ "WARNING"
      assert result =~ "!"
      assert result =~ "this is a warning"
    end

    test "formats info message" do
      result = ErrorFormatter.format("this is info", type: :info)

      assert result =~ "INFO"
      assert result =~ "i"
      assert result =~ "this is info"
    end

    test "formats success message" do
      result = ErrorFormatter.format("operation successful", type: :success)

      assert result =~ "SUCCESS"
      assert result =~ "*"
      assert result =~ "operation successful"
    end

    test "includes suggestions when provided" do
      result =
        ErrorFormatter.format("error occurred",
          suggestions: ["try this", "or that"]
        )

      assert result =~ "Did you mean:"
      assert result =~ "try this"
      assert result =~ "or that"
    end

    test "includes context when provided" do
      result =
        ErrorFormatter.format("error occurred",
          context: "Type 'help' for more info"
        )

      assert result =~ "Type 'help' for more info"
    end

    test "wraps long messages" do
      long_message = String.duplicate("word ", 50)
      result = ErrorFormatter.format(long_message, width: 45)

      lines = String.split(result, "\n")
      # Check that no line exceeds the width
      Enum.each(lines, fn line ->
        assert String.length(line) <= 45
      end)
    end

    test "handles multiline messages" do
      message = "line one\nline two\nline three"
      result = ErrorFormatter.format(message)

      assert result =~ "line one"
      assert result =~ "line two"
      assert result =~ "line three"
    end
  end

  describe "command_not_found/2" do
    test "formats command not found without suggestions" do
      result = ErrorFormatter.command_not_found("foobar")

      assert result =~ "ERROR"
      assert result =~ "Command 'foobar' not found"
      assert result =~ "Type 'help' to see available commands"
    end

    test "formats command not found with suggestions" do
      result = ErrorFormatter.command_not_found("sl", ["ls", "cd"])

      assert result =~ "Command 'sl' not found"
      assert result =~ "Did you mean:"
      assert result =~ "ls"
      assert result =~ "cd"
    end
  end

  describe "file_error/2" do
    test "formats file system error" do
      result = ErrorFormatter.file_error("cd", "No such file or directory")

      assert result =~ "ERROR"
      assert result =~ "cd: No such file or directory"
    end
  end

  describe "invalid_args/2" do
    test "formats invalid arguments error" do
      result = ErrorFormatter.invalid_args("cat", "missing operand")

      assert result =~ "ERROR"
      assert result =~ "cat: missing operand"
      assert result =~ "Try 'cat --help' for usage information"
    end
  end

  describe "warning/1" do
    test "formats warning message" do
      result = ErrorFormatter.warning("File already exists")

      assert result =~ "WARNING"
      assert result =~ "File already exists"
    end
  end

  describe "info/1" do
    test "formats info message" do
      result = ErrorFormatter.info("Loading configuration")

      assert result =~ "INFO"
      assert result =~ "Loading configuration"
    end
  end

  describe "success/1" do
    test "formats success message" do
      result = ErrorFormatter.success("Operation completed")

      assert result =~ "SUCCESS"
      assert result =~ "Operation completed"
    end
  end

  describe "wrap_text/2" do
    test "wraps text that exceeds max width" do
      text = "This is a very long line that should be wrapped"
      result = ErrorFormatter.wrap_text(text, 20)

      assert length(result) > 1

      Enum.each(result, fn line ->
        assert String.length(line) <= 20
      end)
    end

    test "does not wrap text within max width" do
      text = "Short line"
      result = ErrorFormatter.wrap_text(text, 20)

      assert result == ["Short line"]
    end

    test "preserves existing line breaks" do
      text = "Line 1\nLine 2\nLine 3"
      result = ErrorFormatter.wrap_text(text, 50)

      assert length(result) == 3
      assert "Line 1" in result
      assert "Line 2" in result
      assert "Line 3" in result
    end

    test "handles empty string" do
      result = ErrorFormatter.wrap_text("", 20)
      assert result == [""]
    end
  end
end
