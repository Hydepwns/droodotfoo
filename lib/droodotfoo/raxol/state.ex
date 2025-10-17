defmodule Droodotfoo.Raxol.State do
  @moduledoc """
  State management and reducer pattern for the terminal UI.

  This module implements the TEA (The Elm Architecture) pattern for managing
  terminal UI state. All state changes flow through the `reduce/2` function,
  making state transitions predictable and testable.

  ## State Structure

  The state struct contains all information needed to render the terminal:
  - Buffer and cursor position
  - Current navigation section
  - Command mode and history
  - Feature flags (vim_mode, crt_mode, etc.)
  - Integration state (Spotify, Web3, Portal)
  """

  alias Droodotfoo.{AdvancedSearch, CursorTrail}
  alias Droodotfoo.Raxol.{Command, Navigation}
  alias Droodotfoo.Terminal.FileSystem

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
    :web3_connecting,
    :privacy_mode,
    :encryption_keys,
    :encryption_sessions,
    :portal_active,
    :portal_connection,
    :portal_transfers,
    :portal_activity,
    :portal_notifications,
    :current_portal_id
  ]

  # Type definitions

  @type section ::
          :home | :experience | :contact | :spotify | :stl_viewer | :tools | :projects | :web3
  @type t :: %__MODULE__{
          buffer: [[map()]],
          current_section: section(),
          cursor_y: integer(),
          cursor_x: integer(),
          navigation_items: [section()],
          command_mode: boolean(),
          command_buffer: String.t(),
          command_history: [String.t()],
          history_index: integer(),
          terminal_state: map(),
          terminal_output: String.t(),
          prompt: String.t(),
          cursor_trail: map(),
          trail_enabled: boolean(),
          search_state: map(),
          vim_mode: boolean(),
          help_modal_open: boolean(),
          crt_mode: boolean(),
          autocomplete_suggestions: [String.t()],
          autocomplete_index: integer(),
          high_contrast_mode: boolean(),
          selected_project_index: integer(),
          project_detail_view: boolean(),
          spotify_mode: atom(),
          spotify_selected_button: integer(),
          spotify_is_playing: boolean(),
          spotify_compact_mode: boolean(),
          web3_wallet_connected: boolean(),
          web3_wallet_address: String.t() | nil,
          web3_chain_id: integer() | nil,
          web3_connecting: boolean(),
          privacy_mode: boolean(),
          encryption_keys: map() | nil,
          encryption_sessions: map(),
          portal_active: boolean(),
          portal_connection: map(),
          portal_transfers: [map()],
          portal_activity: [map()],
          portal_notifications: [map()],
          current_portal_id: String.t() | nil
        }

  @type input_action :: {:input, String.t()}
  @type command_result :: map()

  @doc """
  Checks if vim mode is enabled.

  ## Examples

      iex> state = %Droodotfoo.Raxol.State{vim_mode: true}
      iex> Droodotfoo.Raxol.State.vim_mode?(state)
      true

  """
  @spec vim_mode?(t()) :: boolean()
  def vim_mode?(state), do: Map.get(state, :vim_mode, false)

  @doc """
  Changes the current section with validation.

  ## Parameters

  - `state`: Current terminal state
  - `new_section`: Section atom (`:home`, `:experience`, etc.)

  ## Examples

      iex> state = Droodotfoo.Raxol.State.initial(80, 24)
      iex> new_state = Droodotfoo.Raxol.State.change_section(state, :spotify)
      iex> new_state.current_section
      :spotify

  """
  @spec change_section(t(), section()) :: t()
  def change_section(state, new_section) when is_atom(new_section) do
    %{state | current_section: new_section}
  end

  @doc """
  Creates initial state for the application.

  ## Parameters

  - `width`: Terminal width in characters (typically 80)
  - `height`: Terminal height in rows (typically 24)

  ## Examples

      iex> state = Droodotfoo.Raxol.State.initial(80, 24)
      iex> state.current_section
      :home
      iex> state.command_mode
      false

  """
  @spec initial(integer(), integer()) :: t()
  def initial(width, height) do
    %__MODULE__{
      buffer: Droodotfoo.TerminalBridge.create_blank_buffer(width, height),
      current_section: :home,
      cursor_y: 2,
      cursor_x: 0,
      navigation_items: [
        :home,
        :experience,
        :contact,
        :spotify,
        :stl_viewer,
        :web3
      ],
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
      web3_connecting: false,
      privacy_mode: false,
      encryption_keys: nil,
      encryption_sessions: %{},
      portal_active: false,
      portal_connection: %{status: :disconnected, peer_count: 0},
      portal_transfers: [],
      portal_activity: [],
      portal_notifications: [],
      current_portal_id: nil
    }
  end

  @doc """
  Main reducer function that handles state updates based on input.

  Acts as the central dispatch for all state changes, following the
  TEA (The Elm Architecture) pattern. All keyboard input flows through
  this function, which routes it to appropriate handlers based on current mode.

  ## Flow

  1. Check for help modal toggle (`?` key)
  2. Check for mode changes (`:` for command, `/` for search, Escape to exit)
  3. Handle command mode input if active
  4. Otherwise delegate to navigation handler

  ## Examples

      iex> state = Droodotfoo.Raxol.State.initial(80, 24)
      iex> new_state = Droodotfoo.Raxol.State.reduce(state, {:input, "1"})
      iex> is_map(new_state)
      true

  """
  @spec reduce(t(), input_action()) :: t()
  def reduce(state, {:input, key}) do
    cond do
      # Help modal takes priority - can be opened from anywhere except command mode
      help_toggle?(state, key) ->
        handle_help_toggle(state, key)

      # Help modal is open - only Escape and ? close it, ignore other keys
      state.help_modal_open ->
        state

      # Mode changes take priority
      mode_change?(state, key) ->
        handle_mode_change(state, key)

      # Then handle input based on current mode
      state.command_mode ->
        handle_command_mode(state, key)

      true ->
        Navigation.handle_input(key, state)
    end
  end

  # Check if input triggers help modal toggle
  defp help_toggle?(%{command_mode: false, help_modal_open: false}, "?"), do: true
  defp help_toggle?(%{help_modal_open: true}, "?"), do: true
  defp help_toggle?(%{help_modal_open: true}, "Escape"), do: true
  defp help_toggle?(_, _), do: false

  # Handle help modal toggle
  defp handle_help_toggle(state, _key) do
    %{state | help_modal_open: !state.help_modal_open}
  end

  # Check if input triggers a mode change
  defp mode_change?(%{command_mode: false}, "/"), do: true
  defp mode_change?(%{command_mode: false}, ":"), do: true
  defp mode_change?(%{command_mode: true}, "Escape"), do: true
  defp mode_change?(_, _), do: false

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
  Updates state after command execution.

  Merges command results into state, exits command mode, and updates history.
  This function is called after every successful command execution to clean up
  command mode state and persist the command to history.

  ## Parameters

  - `state`: Current terminal state
  - `command_result`: Map of state updates from command execution

  ## Examples

      iex> state = %Droodotfoo.Raxol.State{command_mode: true, command_buffer: "help", command_history: []}
      iex> result = %{terminal_output: "Help text..."}
      iex> new_state = Droodotfoo.Raxol.State.after_command_execution(state, result)
      iex> new_state.command_mode
      false
      iex> List.first(new_state.command_history)
      "help"

  """
  @spec after_command_execution(t(), command_result()) :: t()
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
