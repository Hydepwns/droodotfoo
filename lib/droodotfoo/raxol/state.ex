defmodule Droodotfoo.Raxol.State do
  @moduledoc """
  State management and reducer pattern for the terminal UI.
  """

  alias Droodotfoo.Raxol.{Navigation, Command}
  alias Droodotfoo.Terminal.FileSystem
  alias Droodotfoo.CursorTrail
  alias Droodotfoo.AdvancedSearch

  defstruct [
    :buffer,
    :current_section,
    :cursor_y,
    :cursor_x,
    :navigation_items,
    :command_mode,
    :command_buffer,
    :command_history,
    :history_index,
    :terminal_state,
    :terminal_output,
    :prompt,
    :cursor_trail,
    :trail_enabled,
    :search_state,
    :vim_mode,
    :help_modal_open,
    :crt_mode,
    :autocomplete_suggestions,
    :autocomplete_index,
    :high_contrast_mode,
    :selected_project_index,
    :project_detail_view,
    :spotify_mode,
    :spotify_selected_button,
    :spotify_is_playing,
    :spotify_compact_mode,
    :web3_wallet_connected,
    :web3_wallet_address,
    :web3_chain_id,
    :web3_connecting
  ]

  @doc """
  Checks if vim mode is enabled
  """
  def vim_mode?(state), do: Map.get(state, :vim_mode, false)

  @doc """
  Changes the current section with validation
  """
  def change_section(state, new_section) when is_atom(new_section) do
    %{state | current_section: new_section}
  end

  @doc """
  Creates initial state for the application
  """
  def initial(width, height) do
    %__MODULE__{
      buffer: Droodotfoo.TerminalBridge.create_blank_buffer(width, height),
      current_section: :home,
      cursor_y: 2,
      cursor_x: 0,
      navigation_items: [:home, :projects, :skills, :experience, :contact, :spotify, :stl_viewer, :web3],
      command_mode: false,
      command_buffer: "",
      command_history: [],
      history_index: -1,
      terminal_state: FileSystem.init(),
      terminal_output: "Welcome to droo.foo terminal\nType 'help' for available commands\n",
      prompt: "[drew@droo.foo ~]$ ",
      cursor_trail: CursorTrail.new(),
      trail_enabled: false,
      search_state: AdvancedSearch.new(),
      vim_mode: false,
      help_modal_open: false,
      crt_mode: false,
      autocomplete_suggestions: [],
      autocomplete_index: -1,
      high_contrast_mode: false,
      selected_project_index: 0,
      project_detail_view: false,
      spotify_mode: :dashboard,
      spotify_selected_button: 0,
      spotify_is_playing: false,
      spotify_compact_mode: false,
      web3_wallet_connected: false,
      web3_wallet_address: nil,
      web3_chain_id: nil,
      web3_connecting: false
    }
  end

  @doc """
  Main reducer function that handles state updates based on input.
  Acts as the central dispatch for all state changes.
  """
  def reduce(state, {:input, key}) do
    cond do
      # Help modal takes priority - can be opened from anywhere except command mode
      is_help_toggle?(state, key) ->
        handle_help_toggle(state, key)

      # Help modal is open - only Escape and ? close it, ignore other keys
      state.help_modal_open ->
        state

      # Mode changes take priority
      is_mode_change?(state, key) ->
        handle_mode_change(state, key)

      # Then handle input based on current mode
      state.command_mode ->
        handle_command_mode(state, key)

      true ->
        Navigation.handle_input(key, state)
    end
  end

  # Check if input triggers help modal toggle
  defp is_help_toggle?(%{command_mode: false, help_modal_open: false}, "?"), do: true
  defp is_help_toggle?(%{help_modal_open: true}, "?"), do: true
  defp is_help_toggle?(%{help_modal_open: true}, "Escape"), do: true
  defp is_help_toggle?(_, _), do: false

  # Handle help modal toggle
  defp handle_help_toggle(state, _key) do
    %{state | help_modal_open: !state.help_modal_open}
  end

  # Check if input triggers a mode change
  defp is_mode_change?(%{command_mode: false}, "/"), do: true
  defp is_mode_change?(%{command_mode: false}, ":"), do: true
  defp is_mode_change?(%{command_mode: true}, "Escape"), do: true
  defp is_mode_change?(_, _), do: false

  # Handle mode transitions
  defp handle_mode_change(%{command_mode: false} = state, "/") do
    # Enter search mode
    %{state | command_mode: true, command_buffer: "search "}
  end

  defp handle_mode_change(%{command_mode: false} = state, ":") do
    # Enter command mode
    %{state | command_mode: true, command_buffer: "", history_index: -1}
  end

  defp handle_mode_change(%{command_mode: true} = state, "Escape") do
    # Exit command mode
    %{state | command_mode: false, command_buffer: "", history_index: -1}
  end

  defp handle_mode_change(state, _key), do: state

  # Handle command mode input
  defp handle_command_mode(state, "Enter") do
    # Execute command using our new terminal system
    result = Command.execute_terminal_command(state.command_buffer, state)
    after_command_execution(state, result)
  end

  defp handle_command_mode(state, key) do
    # Regular command mode input handling
    Command.handle_input(key, state)
  end

  @doc """
  Updates state after command execution
  """
  def after_command_execution(state, command_result) do
    new_history =
      if state.command_buffer != "",
        do: [state.command_buffer | state.command_history] |> Enum.take(50),
        else: state.command_history

    state
    |> Map.merge(command_result)
    |> Map.put(:command_mode, false)
    |> Map.put(:command_buffer, "")
    |> Map.put(:command_history, new_history)
    |> Map.put(:history_index, -1)
  end
end
