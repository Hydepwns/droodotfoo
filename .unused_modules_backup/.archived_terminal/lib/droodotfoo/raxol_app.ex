defmodule Droodotfoo.RaxolApp do
  @moduledoc """
  Main Raxol application GenServer that manages the terminal UI.

  Responsibilities:
  - Manage terminal state and buffer
  - Process keyboard input
  - Coordinate section navigation
  - Handle theme and mode changes
  - Integrate with Web3 wallet state
  - Manage cursor trail animations

  This module acts as the orchestrator, delegating to specialized modules
  for state management (`Droodotfoo.Raxol.State`), input handling
  (`Droodotfoo.Raxol.Navigation`), and rendering (`Droodotfoo.Raxol.Renderer`).
  """

  use GenServer
  alias Droodotfoo.CursorTrail
  alias Droodotfoo.Raxol.{Config, Renderer, State}

  @width Config.width()
  @height Config.height()

  # Type definitions

  @type cell :: %{char: String.t(), style: map()}
  @type buffer :: [[cell()]]
  @type section ::
          :home | :experience | :contact | :stl_viewer | :tools | :projects | :web3
  @type action :: map() | nil
  @type theme_change :: String.t() | nil
  @type pid_or_name :: pid() | atom()

  ## Client API

  @doc """
  Start the RaxolApp GenServer.

  ## Options

  - Accepts standard GenServer options

  ## Examples

      iex> {:ok, pid} = Droodotfoo.RaxolApp.start_link()
      iex> Process.alive?(pid)
      true

  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Get the current terminal buffer for rendering.

  Returns a 2D grid of cells (110x45 or larger for scrollable sections) representing the terminal display.
  Each cell contains a character and styling information.

  Falls back to an empty buffer if the GenServer is unavailable or times out.

  ## Examples

      iex> buffer = Droodotfoo.RaxolApp.get_buffer()
      iex> is_list(buffer)
      true

  """
  @spec get_buffer(pid_or_name()) :: buffer()
  def get_buffer(pid \\ __MODULE__) do
    GenServer.call(pid, :get_buffer, 5000)
  catch
    :exit, {:noproc, _} ->
      # Process is dead, return empty buffer
      create_empty_buffer()

    :exit, {:timeout, _} ->
      # Timeout, return last known or empty buffer
      create_empty_buffer()
  end

  @doc """
  Get the current clickable regions metadata.

  Returns clickable region definitions for accurate click handling in the UI.
  This metadata includes semantic region IDs, bounds, and action identifiers.

  Falls back to an empty regions collection if the GenServer is unavailable.

  ## Examples

      iex> regions = Droodotfoo.RaxolApp.get_clickable_regions()
      iex> is_struct(regions, Droodotfoo.Raxol.ClickableRegions)
      true

  """
  @spec get_clickable_regions(pid_or_name()) :: Droodotfoo.Raxol.ClickableRegions.t()
  def get_clickable_regions(pid \\ __MODULE__) do
    GenServer.call(pid, :get_clickable_regions, 1000)
  catch
    :exit, _ ->
      # Process unavailable, return empty regions
      Droodotfoo.Raxol.ClickableRegions.new()
  end

  @doc """
  Get the current navigation section.

  Returns the currently active section (`:home`, `:experience`, `:web3`, etc.).
  Falls back to `:home` if unavailable.

  ## Examples

      iex> Droodotfoo.RaxolApp.get_current_section()
      :home

  """
  @spec get_current_section(pid_or_name()) :: section()
  def get_current_section(pid \\ __MODULE__) do
    GenServer.call(pid, :get_current_section, 1000)
  catch
    :exit, _ ->
      :home
  end

  @doc """
  Get and clear the pending theme change action.

  Returns the theme name if a theme change was requested, then clears it.
  Subsequent calls return `nil` until a new theme change occurs.

  ## Examples

      iex> Droodotfoo.RaxolApp.get_theme_change()
      "nord"

      iex> Droodotfoo.RaxolApp.get_theme_change()
      nil

  """
  @spec get_theme_change(pid_or_name()) :: theme_change()
  def get_theme_change(pid \\ __MODULE__) do
    GenServer.call(pid, :get_theme_change, 1000)
  catch
    :exit, _ ->
      nil
  end

  @doc """
  Get and clear the pending STL viewer action.

  Returns an action map if the STL viewer was triggered, then clears it.
  Used to coordinate between terminal and LiveView components.
  """
  @spec get_stl_viewer_action(pid_or_name()) :: action()
  def get_stl_viewer_action(pid \\ __MODULE__) do
    GenServer.call(pid, :get_stl_viewer_action, 1000)
  catch
    :exit, _ ->
      nil
  end

  @doc """
  Get the current CRT mode status.

  Returns `true` if CRT (retro terminal) effect is enabled, `false` otherwise.
  This is a persistent setting that doesn't clear after reading.
  """
  @spec get_crt_mode(pid_or_name()) :: boolean()
  def get_crt_mode(pid \\ __MODULE__) do
    GenServer.call(pid, :get_crt_mode, 1000)
  catch
    :exit, _ ->
      false
  end

  @doc """
  Get the current high contrast mode status.

  Returns `true` if high contrast accessibility mode is enabled, `false` otherwise.
  This is a persistent setting that doesn't clear after reading.
  """
  @spec get_high_contrast_mode(pid_or_name()) :: boolean()
  def get_high_contrast_mode(pid \\ __MODULE__) do
    GenServer.call(pid, :get_high_contrast_mode, 1000)
  catch
    :exit, _ ->
      false
  end

  @doc """
  Get and clear the pending Web3 action.

  Returns an action map for Web3 operations (connect wallet, etc.), then clears it.
  Used to coordinate between terminal and Web3 integration.
  """
  @spec get_web3_action(pid_or_name()) :: action()
  def get_web3_action(pid \\ __MODULE__) do
    GenServer.call(pid, :get_web3_action, 1000)
  catch
    :exit, _ ->
      nil
  end

  @doc """
  Update the Web3 wallet connection state.

  ## Parameters

  - `address`: Wallet address (0x-prefixed) or `nil` to disconnect
  - `chain_id`: Blockchain network ID (1 for mainnet, etc.)

  ## Examples

      iex> Droodotfoo.RaxolApp.set_web3_wallet("0x1234...5678", 1)
      :ok

  """
  @spec set_web3_wallet(pid_or_name(), String.t() | nil, integer()) :: :ok | :error
  def set_web3_wallet(pid \\ __MODULE__, address, chain_id) do
    GenServer.call(pid, {:set_web3_wallet, address, chain_id}, 1000)
  catch
    :exit, _ ->
      :error
  end

  @doc """
  Update the viewport height from frontend.

  ## Parameters

  - `height`: Viewport height in rows (calculated from window.innerHeight / cellHeight)

  ## Examples

      iex> Droodotfoo.RaxolApp.set_viewport_height(35)
      :ok

  """
  @spec set_viewport_height(pid_or_name(), integer()) :: :ok | :error
  def set_viewport_height(pid \\ __MODULE__, height) when is_integer(height) do
    GenServer.cast(pid, {:set_viewport_height, height})
    :ok
  catch
    :exit, _ ->
      :error
  end

  @doc """
  Send keyboard input to the terminal.

  Asynchronously sends a key press to the terminal for processing.
  Input is handled by the state reducer which may trigger navigation,
  command execution, or other state changes.

  ## Parameters

  - `key`: Keyboard key string (e.g., "Enter", "ArrowUp", "a", "1")

  ## Examples

      iex> Droodotfoo.RaxolApp.send_input("1")
      :ok

      iex> Droodotfoo.RaxolApp.send_input("Enter")
      :ok

  """
  @spec send_input(pid_or_name(), String.t()) :: :ok
  def send_input(pid \\ __MODULE__, key) do
    GenServer.cast(pid, {:input, key})
  end

  @doc """
  Reset the terminal state to initial conditions.

  Clears all state and returns the terminal to its default home screen.
  Useful for testing or recovering from error states.

  ## Examples

      iex> Droodotfoo.RaxolApp.reset_state()
      :ok

  """
  @spec reset_state(pid_or_name()) :: :ok
  def reset_state(pid \\ __MODULE__) do
    GenServer.call(pid, :reset_state)
  end

  ## Server Callbacks

  defp create_empty_buffer do
    # Create a fallback empty buffer
    for _ <- 1..@height do
      for _ <- 1..@width do
        %{char: " ", style: %{}}
      end
    end
  end

  @impl true
  def init(_opts) do
    state = State.initial(@width, @height)
    # Schedule trail fade animation
    Process.send_after(self(), :fade_trail, 150)
    {:ok, render(state)}
  end

  @impl true
  def handle_call(:get_buffer, _from, state) do
    {:reply, state.buffer, state}
  end

  def handle_call(:get_clickable_regions, _from, state) do
    # Return the raw struct for TerminalBridge to use
    regions = state.clickable_regions || Droodotfoo.Raxol.ClickableRegions.new()
    {:reply, regions, state}
  end

  def handle_call(:get_current_section, _from, state) do
    {:reply, state.current_section, state}
  end

  def handle_call(:get_theme_change, _from, state) do
    theme_change = Map.get(state, :theme_change)
    # Clear the theme_change after reading it
    new_state = Map.delete(state, :theme_change)
    {:reply, theme_change, new_state}
  end

  def handle_call(:get_crt_mode, _from, state) do
    # Get CRT mode from terminal_state (doesn't clear it, it's persistent)
    crt_mode = Map.get(state.terminal_state || %{}, :crt_mode, false)
    {:reply, crt_mode, state}
  end

  def handle_call(:get_high_contrast_mode, _from, state) do
    # Get high contrast mode from terminal_state (doesn't clear it, it's persistent)
    high_contrast_mode = Map.get(state.terminal_state || %{}, :high_contrast_mode, false)
    {:reply, high_contrast_mode, state}
  end

  def handle_call(:get_stl_viewer_action, _from, state) do
    action = Map.get(state, :stl_viewer_action)
    # Clear the action after reading it
    new_state = Map.delete(state, :stl_viewer_action)
    {:reply, action, new_state}
  end

  def handle_call(:get_web3_action, _from, state) do
    action = Map.get(state, :web3_action)
    # Clear the action after reading it
    new_state = Map.delete(state, :web3_action)
    {:reply, action, new_state}
  end

  def handle_call({:set_web3_wallet, address, chain_id}, _from, state) do
    # Update the internal Raxol state with wallet info
    new_raxol_state = %{
      state.raxol_state
      | web3_wallet_connected: address != nil,
        web3_wallet_address: address,
        web3_chain_id: chain_id
    }

    new_state = %{state | raxol_state: new_raxol_state}
    {:reply, :ok, new_state}
  end

  def handle_call(:ping, _from, state) do
    {:reply, :pong, state}
  end

  def handle_call(:reset_state, _from, _state) do
    new_state = State.initial(@width, @height) |> render()
    {:reply, :ok, new_state}
  end

  @impl true
  def handle_cast({:input, key}, state) do
    new_state = State.reduce(state, {:input, key})
    {:noreply, render(new_state)}
  end

  def handle_cast({:set_viewport_height, height}, state) do
    new_raxol_state = State.set_viewport_height(state.raxol_state, height)
    new_state = %{state | raxol_state: new_raxol_state}
    {:noreply, new_state}
  end

  @impl true
  def handle_info(:fade_trail, state) do
    # Fade the cursor trail animation
    new_trail = CursorTrail.fade_trail(state.cursor_trail)
    new_state = %{state | cursor_trail: new_trail}

    # Schedule next fade
    Process.send_after(self(), :fade_trail, 150)

    {:noreply, render(new_state)}
  end

  defp render(state) do
    {buffer, clickable_regions, content_height} = Renderer.render(state)

    %{
      state
      | buffer: buffer,
        clickable_regions: clickable_regions,
        content_height: content_height
    }
  end
end
