defmodule Droodotfoo.Raxol.Command do
  @moduledoc """
  Handles command mode input and command execution.
  """

  alias Droodotfoo.Terminal.CommandParser

  @doc """
  Handles input when in command mode
  """
  def handle_input("Backspace", state) do
    # Remove last character from command
    %{state | command_buffer: String.slice(state.command_buffer, 0..-2//1)}
  end

  def handle_input("ArrowUp", state) do
    # Navigate command history up
    if state.history_index < length(state.command_history) - 1 do
      new_index = state.history_index + 1
      new_buffer = Enum.at(state.command_history, new_index, "")
      %{state | history_index: new_index, command_buffer: new_buffer}
    else
      state
    end
  end

  def handle_input("ArrowDown", state) do
    # Navigate command history down
    if state.history_index > -1 do
      new_index = state.history_index - 1
      new_buffer = if new_index == -1, do: "", else: Enum.at(state.command_history, new_index, "")
      %{state | history_index: new_index, command_buffer: new_buffer}
    else
      state
    end
  end

  def handle_input("Tab", state) do
    # Tab completion using our new system
    completions = CommandParser.get_completions(state.command_buffer, state.terminal_state)

    case completions do
      [single_completion] -> %{state | command_buffer: single_completion}
      _ -> state
    end
  end

  def handle_input(key, state) when byte_size(key) == 1 do
    # Add character to command buffer
    %{state | command_buffer: state.command_buffer <> key}
  end

  def handle_input(_key, state), do: state

  @doc """
  Executes a terminal command using the new command system
  """
  def execute_terminal_command(command, state) do
    # Execute through our new terminal command system
    case CommandParser.parse_and_execute(command, state.terminal_state) do
      {:ok, output} ->
        # Update terminal output and potentially terminal state
        new_output = append_to_output(state.terminal_output, output)
        %{state | terminal_output: new_output, current_section: :terminal}

      {:ok, output, new_terminal_state} ->
        # Command changed the terminal state (like cd)
        new_output = append_to_output(state.terminal_output, output)

        %{
          state
          | terminal_output: new_output,
            terminal_state: new_terminal_state,
            current_section: :terminal
        }

      {:error, error_msg} ->
        new_output = append_to_output(state.terminal_output, error_msg)
        %{state | terminal_output: new_output, current_section: :terminal}

      {:exit, msg} ->
        # Handle exit command
        new_output = append_to_output(state.terminal_output, msg)
        %{state | terminal_output: new_output, current_section: :home}
    end
  end

  defp append_to_output(current_output, new_content) do
    # Keep last N lines of output to prevent unbounded growth
    lines = String.split(current_output <> "\n" <> new_content, "\n")

    lines
    # Keep last 1000 lines
    |> Enum.take(-1000)
    |> Enum.join("\n")
  end

  @doc """
  Executes a command and returns the updated state (legacy for simple navigation)
  """
  def execute_command(command, state) do
    command
    |> parse_command()
    |> run_command(state)
  end

  defp parse_command(command) do
    case String.split(command, " ", parts: 2) do
      [cmd] -> {cmd, nil}
      [cmd, args] -> {cmd, args}
      _ -> {"", nil}
    end
  end

  defp run_command({"help", _}, state), do: %{state | current_section: :help}
  defp run_command({"ls", _}, state), do: %{state | current_section: :ls}
  defp run_command({"clear", _}, state), do: %{state | current_section: :home}
  defp run_command({"perf", _}, state), do: %{state | current_section: :performance}
  defp run_command({"metrics", _}, state), do: %{state | current_section: :performance}
  defp run_command({"matrix", _}, state), do: %{state | current_section: :matrix}
  defp run_command({"ssh", _}, state), do: %{state | current_section: :ssh}
  defp run_command({"analytics", _}, state), do: %{state | current_section: :analytics}
  defp run_command({"split", _}, state), do: %{state | current_section: :multiplexer}

  defp run_command({"cat", section}, state) when not is_nil(section) do
    atom_section =
      try do
        String.to_existing_atom(section)
      rescue
        _ -> nil
      end

    if atom_section in state.navigation_items do
      %{state | current_section: atom_section}
    else
      state
    end
  end

  defp run_command({"search", query}, state) when not is_nil(query) do
    # Parse search command for mode switches
    {mode, clean_query} = parse_search_mode(query)

    # Get content to search through
    content_map = get_searchable_content(state)

    # Update search state with mode if specified
    search_state =
      if mode do
        Droodotfoo.AdvancedSearch.set_mode(state.search_state, mode)
      else
        state.search_state
      end

    # Perform the search
    updated_search = Droodotfoo.AdvancedSearch.search(search_state, clean_query, content_map)

    %{state |
      current_section: :search_results,
      search_state: updated_search,
      command_buffer: query
    }
  end

  defp run_command({"export", format}, state) when not is_nil(format) do
    section =
      case format do
        "markdown" -> :export_markdown
        "json" -> :export_json
        "text" -> :export_text
        _ -> :export_help
      end

    %{state | current_section: section}
  end

  defp run_command(_, state), do: state

  # Helper functions for advanced search

  defp parse_search_mode(query) do
    cond do
      String.starts_with?(query, "--fuzzy ") ->
        {:fuzzy, String.replace_prefix(query, "--fuzzy ", "")}
      String.starts_with?(query, "--exact ") ->
        {:exact, String.replace_prefix(query, "--exact ", "")}
      String.starts_with?(query, "--regex ") ->
        {:regex, String.replace_prefix(query, "--regex ", "")}
      true ->
        {nil, query}
    end
  end

  defp get_searchable_content(_state) do
    # Return a map of section => content for searching
    # This would normally pull from your actual content sources
    %{
      home: """
      Drew Olsen - Software Engineer
      Welcome to droo.foo
      Interactive terminal portfolio
      Navigate with vim keys or use commands
      """,
      projects: """
      Terminal UI Framework - Elixir/Phoenix LiveView
      Real-time collaborative editor
      Distributed systems monitoring
      Open source contributions
      """,
      skills: """
      Languages: Elixir, Ruby, JavaScript, Python, Go
      Frameworks: Phoenix, Rails, React, Vue
      Databases: PostgreSQL, Redis, MongoDB
      Tools: Docker, Kubernetes, Terraform, AWS
      """,
      experience: """
      Senior Software Engineer at TechCorp
      Full-stack development and architecture
      Team lead for distributed systems
      Open source maintainer
      """,
      contact: """
      Email: drew@droo.foo
      GitHub: github.com/droo
      LinkedIn: linkedin.com/in/drewolsen
      Twitter: @droo
      """
    }
  end
end
