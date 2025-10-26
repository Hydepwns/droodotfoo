defmodule Droodotfoo.Terminal.CommandBaseTest do
  use ExUnit.Case, async: true

  # doctest Droodotfoo.Terminal.CommandBase  # Module archived - tests retained for potential reactivation
  # Terminal features archived - tests skipped until reactivation
  @moduletag :skip

  # Test module that uses CommandBase
  # Note: Command metadata is now in CommandRegistry, modules only implement execute/3
  defmodule TestCommands do
    # use Droodotfoo.Terminal.CommandBase  # Module archived

    # @impl true  # Commented out since behavior is not loaded
    def execute("test", args, state) do
      {:ok, "Test executed with #{length(args)} args", state}
    end

    def execute("simple", _args, state) do
      {:ok, "Simple command executed", state}
    end

    def execute("multi", args, state) do
      {:ok, "Multi executed: #{Enum.join(args, " ")}", state}
    end

    def execute(command, _args, state) do
      {:error, "Unknown command: #{command}", state}
    end
  end

  describe "run/3" do
    test "executes command successfully" do
      {:ok, output, state} = TestCommands.run("test", ["arg1"], %{})

      assert output == "Test executed with 1 args"
      assert is_map(state)
    end

    test "executes command" do
      {:ok, output, _state} = TestCommands.run("simple", [], %{})

      assert output == "Simple command executed"
    end

    test "returns error for unknown command" do
      {:error, message, _state} = TestCommands.run("unknown", [], %{})

      assert message =~ "Unknown command"
    end

    test "normalizes result without state" do
      # This would test if a command returns {:ok, output} without state
      # The normalize_result/1 function handles this
      assert {:ok, "output", %{}} ==
               Droodotfoo.Terminal.CommandBase.normalize_result({:ok, "output"})
    end
  end

  describe "handle_command_error/2" do
    test "formats error message with command context" do
      {:error, message} = TestCommands.handle_command_error("Something went wrong", "test")

      assert message =~ "Error executing 'test'"
      assert message =~ "Something went wrong"
      assert message =~ "Use 'help test' for usage information"
    end
  end

  describe "validate_args/2" do
    test "returns ok when arg count matches" do
      assert {:ok, ["a", "b"]} = Droodotfoo.Terminal.CommandBase.validate_args(["a", "b"], 2)
    end

    test "returns error when arg count doesn't match" do
      {:error, message} = Droodotfoo.Terminal.CommandBase.validate_args(["a"], 2)

      assert message =~ "Expected 2 arguments, got 1"
    end
  end

  describe "validate_min_args/2" do
    test "returns ok when args meet minimum" do
      assert {:ok, ["a", "b", "c"]} =
               Droodotfoo.Terminal.CommandBase.validate_min_args(["a", "b", "c"], 2)
    end

    test "returns ok when args exactly meet minimum" do
      assert {:ok, ["a", "b"]} =
               Droodotfoo.Terminal.CommandBase.validate_min_args(["a", "b"], 2)
    end

    test "returns error when args below minimum" do
      {:error, message} = Droodotfoo.Terminal.CommandBase.validate_min_args(["a"], 2)

      assert message =~ "Expected at least 2 arguments, got 1"
    end
  end

  describe "validate_max_args/2" do
    test "returns ok when args under maximum" do
      assert {:ok, ["a"]} = Droodotfoo.Terminal.CommandBase.validate_max_args(["a"], 3)
    end

    test "returns ok when args exactly at maximum" do
      assert {:ok, ["a", "b"]} = Droodotfoo.Terminal.CommandBase.validate_max_args(["a", "b"], 2)
    end

    test "returns error when args exceed maximum" do
      {:error, message} =
        Droodotfoo.Terminal.CommandBase.validate_max_args(["a", "b", "c"], 2)

      assert message =~ "Expected at most 2 arguments, got 3"
    end
  end

  describe "normalize_result/1" do
    test "normalizes {:ok, output} to include empty state" do
      assert {:ok, "output", %{}} ==
               Droodotfoo.Terminal.CommandBase.normalize_result({:ok, "output"})
    end

    test "preserves {:ok, output, state}" do
      state = %{key: "value"}

      assert {:ok, "output", ^state} =
               Droodotfoo.Terminal.CommandBase.normalize_result({:ok, "output", state})
    end

    test "normalizes {:error, message} to include empty state" do
      assert {:error, "error", %{}} ==
               Droodotfoo.Terminal.CommandBase.normalize_result({:error, "error"})
    end

    test "preserves {:error, message, state}" do
      state = %{key: "value"}

      assert {:error, "error", ^state} =
               Droodotfoo.Terminal.CommandBase.normalize_result({:error, "error", state})
    end

    test "handles invalid result format" do
      {:error, message, %{}} =
        Droodotfoo.Terminal.CommandBase.normalize_result(:invalid)

      assert message =~ "Invalid command result"
    end
  end

  describe "integration with execute/3" do
    test "executes multiple commands with state passing" do
      state = %{counter: 0}

      {:ok, _output1, state1} = TestCommands.run("test", ["arg1"], state)
      {:ok, _output2, state2} = TestCommands.run("simple", [], state1)
      {:ok, output3, _state3} = TestCommands.run("multi", ["start", "server"], state2)

      assert output3 =~ "Multi executed: start server"
    end

    test "handles command with arguments correctly" do
      {:ok, output, _state} = TestCommands.run("multi", ["deploy", "production"], %{})

      assert output == "Multi executed: deploy production"
    end
  end
end
