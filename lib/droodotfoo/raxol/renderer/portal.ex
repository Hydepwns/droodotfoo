defmodule Droodotfoo.Raxol.Renderer.Portal do
  @moduledoc """
  Portal P2P UI rendering components for the terminal.
  Handles live connection status, file transfers, and peer activity displays.
  """

  alias Droodotfoo.Raxol.{BoxBuilder, BoxConfig}
  alias Droodotfoo.Raxol.Renderer.Helpers

  @doc """
  Draw the enhanced Portal UI if portal is active in the current section.
  """
  def draw_enhanced_ui(buffer, state) do
    if state.current_section == :portal and state.portal_active do
      draw_live_status(buffer, state)
    else
      buffer
    end
  end

  @doc """
  Draw the live Portal status with connection info, transfers, and notifications.
  """
  def draw_live_status(buffer, state) do
    # Live connection status indicators
    connection_status = get_connection_status(state)
    active_transfers = get_active_transfers(state)
    peer_activity = get_peer_activity(state)
    notifications = get_recent_notifications(state)

    # Build content sections
    content = [
      "",
      "Connection Status: #{format_connection_status(connection_status)}",
      ""
    ]

    # Add peer activity if available
    content =
      if length(peer_activity) > 0 do
        activity_box = BoxBuilder.inner_box("Recent Activity", Enum.take(peer_activity, 3))
        content ++ activity_box ++ [""]
      else
        content
      end

    # Add transfers if available
    content =
      if length(active_transfers) > 0 do
        transfer_lines =
          Enum.map(active_transfers, fn transfer ->
            progress_bar = Helpers.create_progress_bar(transfer.progress, 35)
            filename = BoxConfig.truncate_text(transfer.filename, 25)
            "#{filename} #{progress_bar}"
          end)

        transfer_box = BoxBuilder.inner_box("Active Transfers", transfer_lines)
        content ++ transfer_box ++ [""]
      else
        content
      end

    # Add notifications if available
    content =
      if length(notifications) > 0 do
        notification_box = BoxBuilder.inner_box("Notifications", Enum.take(notifications, 2))
        content ++ notification_box ++ [""]
      else
        content
      end

    # Add commands section
    content =
      content ++
        [
          "Commands:",
          "  :portal status    - Detailed connection info",
          "  :portal transfers - View all transfers",
          "  :portal activity  - Recent peer activity",
          ""
        ]

    box_lines = BoxBuilder.build("Portal P2P Status", content)
    Helpers.draw_box_at(buffer, box_lines, 0, 0)
  end

  # Get real-time connection status from Portal state.
  defp get_connection_status(state) do
    case state.portal_connection do
      %{status: :connected, peer_count: count} ->
        %{status: :connected, peer_count: count, quality: :excellent}

      %{status: :connecting} ->
        %{status: :connecting, peer_count: 0, quality: :poor}

      %{status: :disconnected} ->
        %{status: :disconnected, peer_count: 0, quality: :none}

      _ ->
        %{status: :disconnected, peer_count: 0, quality: :none}
    end
  end

  # Get active file transfers from Portal state.
  defp get_active_transfers(state) do
    case state.portal_transfers do
      transfers when is_list(transfers) ->
        Enum.filter(transfers, fn transfer ->
          transfer.state in [:pending, :transferring]
        end)

      _ ->
        []
    end
  end

  # Get recent peer activity from Portal state.
  defp get_peer_activity(state) do
    case state.portal_activity do
      activity when is_list(activity) ->
        Enum.take(activity, 5)

      _ ->
        []
    end
  end

  # Get recent notifications from Portal state.
  defp get_recent_notifications(state) do
    case state.portal_notifications do
      notifications when is_list(notifications) ->
        Enum.take(notifications, 3)

      _ ->
        []
    end
  end

  # Format connection status with quality icon and peer count.
  defp format_connection_status(%{status: :connected, peer_count: count, quality: quality}) do
    quality_icon =
      case quality do
        :excellent -> "[+]"
        :good -> "[~]"
        :fair -> "[!]"
        :poor -> "[X]"
        _ -> "[?]"
      end

    "#{quality_icon} Connected (#{count} peers)"
  end

  defp format_connection_status(%{status: :connecting}) do
    "[~] Connecting..."
  end

  defp format_connection_status(%{status: :disconnected}) do
    "[X] Disconnected"
  end

  defp format_connection_status(_) do
    "[?] Unknown"
  end
end
