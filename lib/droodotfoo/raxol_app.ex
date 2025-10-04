defmodule Droodotfoo.RaxolApp do
  @moduledoc """
  Main Raxol application that manages the terminal UI.
  This module now acts as the orchestrator, delegating to specialized modules
  for state management, input handling, and rendering.
  """

  use GenServer
  alias Droodotfoo.Raxol.{State, Renderer}
  alias Droodotfoo.CursorTrail

  @width 80
  @height 24

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get_buffer(pid \\ __MODULE__) do
    try do
      GenServer.call(pid, :get_buffer, 5000)
    catch
      :exit, {:noproc, _} ->
        # Process is dead, return empty buffer
        create_empty_buffer()

      :exit, {:timeout, _} ->
        # Timeout, return last known or empty buffer
        create_empty_buffer()
    end
  end

  def get_current_section(pid \\ __MODULE__) do
    try do
      GenServer.call(pid, :get_current_section, 1000)
    catch
      :exit, _ ->
        :home
    end
  end

  def get_theme_change(pid \\ __MODULE__) do
    try do
      GenServer.call(pid, :get_theme_change, 1000)
    catch
      :exit, _ ->
        nil
    end
  end

  def get_stl_viewer_action(pid \\ __MODULE__) do
    try do
      GenServer.call(pid, :get_stl_viewer_action, 1000)
    catch
      :exit, _ ->
        nil
    end
  end

  def get_crt_mode(pid \\ __MODULE__) do
    try do
      GenServer.call(pid, :get_crt_mode, 1000)
    catch
      :exit, _ ->
        false
    end
  end

  def get_high_contrast_mode(pid \\ __MODULE__) do
    try do
      GenServer.call(pid, :get_high_contrast_mode, 1000)
    catch
      :exit, _ ->
        false
    end
  end

  defp create_empty_buffer do
    # Create a fallback empty buffer
    for _ <- 1..@height do
      for _ <- 1..@width do
        %{char: " ", style: %{}}
      end
    end
  end

  def send_input(pid \\ __MODULE__, key) do
    GenServer.cast(pid, {:input, key})
  end

  def reset_state(pid \\ __MODULE__) do
    GenServer.call(pid, :reset_state)
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
    buffer = Renderer.render(state)
    %{state | buffer: buffer}
  end
end
