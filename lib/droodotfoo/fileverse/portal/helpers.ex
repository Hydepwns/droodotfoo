defmodule Droodotfoo.Fileverse.Portal.Helpers do
  @moduledoc """
  Portal helper functions.
  Provides utility functions for ID generation, time formatting, and mock data.
  """

  @doc """
  Generate a random ID for portals and shares.

  ## Examples

      iex> Helpers.generate_id()
      "a1b2c3d4e5f67890"

  """
  @spec generate_id() :: String.t()
  def generate_id do
    :crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)
  end

  @doc """
  Format a datetime as relative time.

  ## Examples

      iex> Helpers.format_relative_time(~U[2024-01-01 12:00:00Z])
      "2d ago"

  """
  @spec format_relative_time(DateTime.t()) :: String.t()
  def format_relative_time(datetime) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, datetime, :second)

    cond do
      diff_seconds < 60 ->
        "#{diff_seconds}s ago"

      diff_seconds < 3600 ->
        minutes = div(diff_seconds, 60)
        "#{minutes}m ago"

      diff_seconds < 86_400 ->
        hours = div(diff_seconds, 3600)
        "#{hours}h ago"

      diff_seconds < 2_592_000 ->
        days = div(diff_seconds, 86_400)
        "#{days}d ago"

      true ->
        months = div(diff_seconds, 2_592_000)
        "#{months}mo ago"
    end
  end

  @doc """
  Get mock portal data for testing.

  ## Examples

      iex> Helpers.get_mock_portal("portal_123", "0x...")
      %{id: "portal_123", name: "Mock Portal", ...}

  """
  @spec get_mock_portal(String.t(), String.t()) :: map()
  def get_mock_portal(portal_id, wallet_address) do
    %{
      id: portal_id,
      name: "Mock Portal",
      creator: "0xabcd...efgh",
      created_at: DateTime.add(DateTime.utc_now(), -3600, :second),
      peers: [
        %{
          address: "0xabcd...efgh",
          ens_name: "creator.eth",
          connection_status: :connected,
          joined_at: DateTime.add(DateTime.utc_now(), -3600, :second),
          is_host: true
        },
        %{
          address: wallet_address,
          ens_name: nil,
          connection_status: :connected,
          joined_at: DateTime.utc_now(),
          is_host: false
        }
      ],
      files_shared: 0,
      encrypted: true,
      public: false
    }
  end

  @doc """
  Get connection status for a portal.

  ## Examples

      iex> Helpers.get_connection_status("portal_123")
      %{status: :connected, peer_count: 3, ...}

  """
  @spec get_connection_status(String.t()) :: map()
  def get_connection_status(_portal_id) do
    # Mock implementation - would get real connection status
    %{
      status: :connected,
      peer_count: 3,
      quality: :excellent,
      uptime: 3600,
      bandwidth: "10 Mbps",
      latency: 45,
      encryption: true
    }
  end

  @doc """
  Get portal statistics.

  ## Examples

      iex> Helpers.get_portal_stats("portal_123")
      %{total_peers: 3, active_peers: 3, ...}

  """
  @spec get_portal_stats(String.t()) :: map()
  def get_portal_stats(_portal_id) do
    # Mock implementation - would get real statistics
    %{
      total_peers: 3,
      active_peers: 3,
      total_transfers: 15,
      active_transfers: 2,
      total_data_transferred: "50.2 MB",
      average_connection_quality: :excellent,
      uptime: 3600
    }
  end
end
