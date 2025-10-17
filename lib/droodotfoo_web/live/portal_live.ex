defmodule DroodotfooWeb.PortalLive do
  @moduledoc """
  LiveView for Portal P2P collaboration management.

  Handles:
  - Real-time peer presence
  - WebRTC connection management
  - File transfer coordination
  - Portal state synchronization
  - Live updates to terminal UI
  """

  use DroodotfooWeb, :live_view

  alias Droodotfoo.Fileverse.Portal
  alias Droodotfoo.Fileverse.Portal.WebRTC
  # alias Droodotfoo.Web3.Manager

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to portal updates
      Phoenix.PubSub.subscribe(Droodotfoo.PubSub, "portal:updates")

      # Initialize portal state
      _socket =
        assign(socket, :portal_state, %{
          active_portals: [],
          peer_connections: %{},
          file_transfers: %{},
          presence: %{}
        })
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"portal_id" => portal_id}, _url, socket) do
    # Load specific portal and its connections
    case Portal.get(portal_id) do
      {:ok, portal} ->
        socket = assign(socket, :current_portal, portal)
        socket = assign(socket, :portal_id, portal_id)
        {:noreply, socket}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Portal not found")}
    end
  end

  @impl true
  def handle_params(_params, _url, socket) do
    # Load all portals for connected wallet
    case get_wallet_address(socket) do
      nil ->
        {:noreply, put_flash(socket, :error, "Web3 wallet not connected")}

      wallet_address ->
        case Portal.list(wallet_address) do
          {:ok, portals} ->
            socket = assign(socket, :portals, portals)
            {:noreply, socket}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, "Failed to load portals: #{inspect(reason)}")}
        end
    end
  end

  @impl true
  def handle_event(
        "create_peer_connection",
        %{"connection_id" => _connection_id, "peer_id" => peer_id, "portal_id" => portal_id},
        socket
      ) do
    case get_wallet_address(socket) do
      nil ->
        {:noreply, put_flash(socket, :error, "Web3 wallet not connected")}

      wallet_address ->
        case WebRTC.create_peer_connection(peer_id,
               portal_id: portal_id,
               wallet_address: wallet_address
             ) do
          {:ok, connection} ->
            # Update portal state
            socket = update_portal_state(socket, :add_connection, connection)

            # Notify other peers
            Phoenix.PubSub.broadcast(
              Droodotfoo.PubSub,
              "portal:#{portal_id}",
              {:peer_joined, connection}
            )

            {:noreply, socket}

          {:error, reason} ->
            {:noreply,
             put_flash(socket, :error, "Failed to create peer connection: #{inspect(reason)}")}
        end
    end
  end

  @impl true
  def handle_event(
        "create_offer",
        %{"connection_id" => connection_id, "data_channels" => data_channels},
        socket
      ) do
    case WebRTC.create_offer(connection_id, data_channels: data_channels) do
      {:ok, offer} ->
        # Send offer to remote peer via signaling
        socket =
          push_event(socket, "offer_created", %{
            connection_id: connection_id,
            offer: offer
          })

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to create offer: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event(
        "process_answer",
        %{"connection_id" => connection_id, "answer" => answer},
        socket
      ) do
    case WebRTC.process_answer(connection_id, answer) do
      {:ok, connection} ->
        # Update connection state
        socket = update_portal_state(socket, :update_connection, connection)

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to process answer: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event(
        "add_ice_candidate",
        %{"connection_id" => connection_id, "candidate" => candidate},
        socket
      ) do
    case WebRTC.add_ice_candidate(connection_id, candidate) do
      {:ok, connection} ->
        # Update connection state
        socket = update_portal_state(socket, :update_connection, connection)

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to add ICE candidate: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event(
        "create_data_channel",
        %{"connection_id" => connection_id, "channel_name" => channel_name, "options" => options},
        socket
      ) do
    case WebRTC.create_data_channel(connection_id, channel_name, options) do
      {:ok, connection} ->
        # Update connection state
        socket = update_portal_state(socket, :update_connection, connection)

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to create data channel: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("close_connection", %{"connection_id" => connection_id}, socket) do
    case WebRTC.close_peer_connection(connection_id) do
      :ok ->
        # Update portal state
        socket = update_portal_state(socket, :remove_connection, connection_id)

        {:noreply, socket}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to close connection: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("share_file", %{"portal_id" => portal_id, "file_path" => file_path}, socket) do
    case get_wallet_address(socket) do
      nil ->
        {:noreply, put_flash(socket, :error, "Web3 wallet not connected")}

      wallet_address ->
        case Portal.share_file(portal_id, file_path, wallet_address: wallet_address) do
          {:ok, file_share} ->
            # Update portal state with file share
            socket = update_portal_state(socket, :add_file_share, file_share)

            # Notify other peers about file share
            Phoenix.PubSub.broadcast(
              Droodotfoo.PubSub,
              "portal:#{portal_id}",
              {:file_shared, file_share}
            )

            {:noreply, socket}

          {:error, reason} ->
            {:noreply, put_flash(socket, :error, "Failed to share file: #{inspect(reason)}")}
        end
    end
  end

  @impl true
  def handle_info({:peer_joined, connection}, socket) do
    # Update presence when peer joins
    socket = update_portal_state(socket, :add_connection, connection)

    # Show notification
    socket = put_flash(socket, :info, "Peer #{connection.peer_id} joined the portal")

    {:noreply, socket}
  end

  @impl true
  def handle_info({:peer_left, peer_id}, socket) do
    # Update presence when peer leaves
    socket = update_portal_state(socket, :remove_peer, peer_id)

    # Show notification
    socket = put_flash(socket, :info, "Peer #{peer_id} left the portal")

    {:noreply, socket}
  end

  @impl true
  def handle_info({:file_shared, file_share}, socket) do
    # Update portal state with new file share
    socket = update_portal_state(socket, :add_file_share, file_share)

    # Show notification
    socket = put_flash(socket, :info, "File #{file_share.filename} shared in portal")

    {:noreply, socket}
  end

  @impl true
  def handle_info({:connection_state_changed, connection_id, state}, socket) do
    # Update connection state
    socket = update_portal_state(socket, :update_connection_state, {connection_id, state})

    {:noreply, socket}
  end

  @impl true
  def handle_info({:connection_stats, stats}, socket) do
    # Update connection statistics
    socket = update_portal_state(socket, :update_connection_stats, stats)

    {:noreply, socket}
  end

  # Private helper functions

  defp get_wallet_address(socket) do
    # Get wallet address from session or assigns
    socket.assigns[:wallet_address] || socket.assigns[:web3_wallet_address]
  end

  defp update_portal_state(socket, action, data) do
    portal_state = socket.assigns.portal_state
    updated_state = apply_portal_action(action, data, portal_state)
    assign(socket, :portal_state, updated_state)
  end

  defp apply_portal_action(:add_connection, data, portal_state) do
    connections = Map.put(portal_state.peer_connections, data.id, data)
    %{portal_state | peer_connections: connections}
  end

  defp apply_portal_action(:update_connection, data, portal_state) do
    connections = Map.put(portal_state.peer_connections, data.id, data)
    %{portal_state | peer_connections: connections}
  end

  defp apply_portal_action(:remove_connection, {connection_id, _}, portal_state) do
    connections = Map.delete(portal_state.peer_connections, connection_id)
    %{portal_state | peer_connections: connections}
  end

  defp apply_portal_action(:add_file_share, data, portal_state) do
    file_transfers = Map.put(portal_state.file_transfers, data.id, data)
    %{portal_state | file_transfers: file_transfers}
  end

  defp apply_portal_action(:update_connection_state, {connection_id, state}, portal_state) do
    connections =
      Map.update(portal_state.peer_connections, connection_id, nil, fn conn ->
        %{conn | state: state}
      end)

    %{portal_state | peer_connections: connections}
  end

  defp apply_portal_action(:update_connection_stats, data, portal_state) do
    stats = Map.put(portal_state[:connection_stats] || %{}, data.connection_id, data)
    %{portal_state | connection_stats: stats}
  end

  defp apply_portal_action(:remove_peer, peer_id, portal_state) do
    connections =
      Enum.reject(portal_state.peer_connections, fn {_id, conn} ->
        conn.peer_id == peer_id
      end)
      |> Map.new()

    %{portal_state | peer_connections: connections}
  end

  defp apply_portal_action(_, _, portal_state), do: portal_state
end
