defmodule DroodotfooWeb.DroodotfooLive.ActionHandlers do
  @moduledoc """
  Action handlers for STL viewer and Web3 integrations.
  Processes specific actions from keyboard commands and updates the LiveView socket.
  """

  alias Droodotfoo.RaxolApp
  import Phoenix.LiveView, only: [push_event: 3]

  @doc """
  Handle STL viewer keyboard actions (rotate, zoom, reset, cycle mode).
  """
  def handle_stl_viewer_action(socket, {:rotate, direction}) do
    angle =
      case direction do
        :up -> -0.1
        :down -> 0.1
        _ -> 0.1
      end

    push_event(socket, "stl_rotate", %{axis: "y", angle: angle})
  end

  def handle_stl_viewer_action(socket, {:zoom, direction}) do
    # Simulate zoom by moving camera
    distance =
      case direction do
        :in -> -0.5
        :out -> 0.5
        _ -> 0.5
      end

    push_event(socket, "stl_zoom", %{distance: distance})
  end

  def handle_stl_viewer_action(socket, {:reset, _}) do
    push_event(socket, "stl_reset", %{})
  end

  def handle_stl_viewer_action(socket, {:cycle_mode, _}) do
    push_event(socket, "stl_cycle_mode", %{})
  end

  def handle_stl_viewer_action(socket, _), do: socket

  @doc """
  Handle Web3 wallet actions (connect, disconnect).
  """
  def handle_web3_action(socket, :connect) do
    # Generate a temporary nonce (will be replaced by one from the backend)
    # For now, we'll generate it client-side in the JavaScript hook
    # Just push the event to trigger MetaMask
    push_event(socket, "web3_connect_request", %{})
  end

  def handle_web3_action(socket, :disconnect) do
    # Clear wallet session (get session ID from RaxolApp state)
    # For now, just update the RaxolApp state
    RaxolApp.set_web3_wallet(socket.assigns.raxol_pid, nil, nil)

    socket
  end

  def handle_web3_action(socket, _), do: socket
end
