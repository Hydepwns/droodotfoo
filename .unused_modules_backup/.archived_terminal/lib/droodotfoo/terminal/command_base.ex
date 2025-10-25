defmodule Droodotfoo.Terminal.CommandBase do
  @moduledoc """
  Behavior for terminal command modules providing common patterns.

  This module standardizes command execution, error handling, and argument validation
  across all terminal command modules.

  **IMPORTANT**: Command metadata (names, aliases, descriptions, categories) is defined
  in `Droodotfoo.Terminal.CommandRegistry` as the single source of truth. Command modules
  using this behavior only implement execution logic via the `execute/3` callback.

  ## Quick Start

  Add `use Droodotfoo.Terminal.CommandBase` to your command module and implement
  the `execute/3` callback:

      defmodule Droodotfoo.Terminal.Commands.MyCommands do
        use Droodotfoo.Terminal.CommandBase

        @impl true
        def execute("mycommand", args, state) do
          # Your command logic here
          {:ok, "Result: \#{inspect(args)}", state}
        end

        def execute(command, _args, state) do
          {:error, "Unknown command: \#{command}", state}
        end
      end

  Command metadata is registered in `CommandRegistry`:

      # In lib/droodotfoo/terminal/command_registry.ex
      %{
        name: "mycommand",
        aliases: ["mc", "my"],
        description: "Does something useful",
        category: :utility
      }

  ## Real-World Examples

  See these modules for complete working examples:
  - `Droodotfoo.Terminal.Commands.Web3` - 8 commands with complex subcommands
  - `Droodotfoo.Terminal.Commands.System` - 7 simple system info commands
  - `Droodotfoo.Terminal.Commands.Git` - 10 development tool commands
  - `Droodotfoo.Terminal.Commands.Fileverse` - 11 integration commands

  ## Return Values

  Command execution should return one of:

  - `{:ok, output}` - Success with output string
  - `{:ok, output, new_state}` - Success with output and updated state
  - `{:error, message}` - Error with message string
  - `{:error, message, new_state}` - Error with message and updated state

  ## Provided Helper Functions

  When you `use CommandBase`, you get these helper functions for free:

  - `run/3` - Execute command with automatic result normalization
  - `handle_command_error/2` - Format error messages
  - `validate_args/2` - Validate exact argument count
  - `validate_min_args/2` - Validate minimum arguments
  - `validate_max_args/2` - Validate maximum arguments

  ## Argument Validation Examples

      def execute("copy", args, state) do
        with {:ok, [source, dest]} <- validate_args(args, 2) do
          # Command logic with exactly 2 args
          {:ok, "Copied \#{source} to \#{dest}", state}
        end
      end

      def execute("delete", args, state) do
        with {:ok, files} <- validate_min_args(args, 1) do
          # Command logic with 1 or more args
          {:ok, "Deleted \#{length(files)} files", state}
        end
      end
  """

  @type command_result ::
          {:ok, String.t()}
          | {:ok, String.t(), map()}
          | {:error, String.t()}
          | {:error, String.t(), map()}

  @doc """
  Callback for command execution.
  Returns {:ok, output, state} or {:error, reason, state}
  """
  @callback execute(command :: String.t(), args :: [String.t()], state :: map()) ::
              command_result()

  defmacro __using__(_opts) do
    quote do
      @behaviour Droodotfoo.Terminal.CommandBase

      import Droodotfoo.Terminal.CommandBase,
        only: [validate_args: 2, validate_min_args: 2, validate_max_args: 2]

      @doc """
      Execute a command by name with arguments and state.
      Delegates to the command-specific execute/3 callback.
      """
      def run(command, args, state) do
        execute(command, args, state)
        |> Droodotfoo.Terminal.CommandBase.normalize_result()
      end

      @doc """
      Handles errors with consistent formatting.
      """
      def handle_command_error(error, command) do
        message = """
        Error executing '#{command}': #{error}
        Use 'help #{command}' for usage information
        """

        {:error, String.trim(message)}
      end
    end
  end

  @doc """
  Validates that exactly the expected number of arguments are provided.
  Returns {:ok, args} or {:error, message}.
  """
  def validate_args(args, expected_count) when length(args) == expected_count do
    {:ok, args}
  end

  def validate_args(args, expected_count) do
    {:error, "Expected #{expected_count} arguments, got #{length(args)}"}
  end

  @doc """
  Validates that at least the minimum number of arguments are provided.
  """
  def validate_min_args(args, min_count) when length(args) >= min_count do
    {:ok, args}
  end

  def validate_min_args(args, min_count) do
    {:error, "Expected at least #{min_count} arguments, got #{length(args)}"}
  end

  @doc """
  Validates that no more than the maximum number of arguments are provided.
  """
  def validate_max_args(args, max_count) when length(args) <= max_count do
    {:ok, args}
  end

  def validate_max_args(args, max_count) do
    {:error, "Expected at most #{max_count} arguments, got #{length(args)}"}
  end

  @doc """
  Normalizes command results to ensure consistent format.

  Handles various return formats and ensures all results include state.
  """
  def normalize_result({:ok, output}), do: {:ok, output, %{}}
  def normalize_result({:ok, output, state}), do: {:ok, output, state}
  def normalize_result({:error, message}), do: {:error, message, %{}}
  def normalize_result({:error, message, state}), do: {:error, message, state}
  def normalize_result(other), do: {:error, "Invalid command result: #{inspect(other)}", %{}}
end
