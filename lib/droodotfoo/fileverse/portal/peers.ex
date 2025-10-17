defmodule Droodotfoo.Fileverse.Portal.Peers do
  @moduledoc """
  Portal peer management functions.
  Handles peer operations including presence, activity, and state management.
  """

  alias Droodotfoo.Fileverse.Portal.{Lifecycle, Presence}

  @doc """
  Get list of active peers in a Portal.

  ## Examples

      iex> Peers.list("portal_abc123")
      {:ok, [%{address: "0x...", ens_name: "alice.eth", ...}]}

  """
  @spec list(String.t()) :: {:ok, [map()]} | {:error, atom()}
  def list(portal_id) do
    case Lifecycle.get(portal_id) do
      {:ok, portal} -> {:ok, portal.peers}
      error -> error
    end
  end

  @doc """
  Get real-time peer presence for a Portal.

  ## Examples

      iex> Peers.presence("portal_abc123")
      {:ok, %{portal_id: "portal_abc123", peer_count: 3, active_peers: [...], ...}}

  """
  @spec presence(String.t()) :: {:ok, map()} | {:error, atom()}
  def presence(portal_id) do
    Presence.get_portal_presence(portal_id)
  end

  @doc """
  Get active peers in a Portal.

  ## Examples

      iex> Peers.active("portal_abc123")
      {:ok, [%{peer_id: "peer_123", activity_status: :active, ...}]}

  """
  @spec active(String.t()) :: {:ok, [map()]} | {:error, atom()}
  def active(portal_id) do
    Presence.get_active_peers(portal_id)
  end

  @doc """
  Update peer connection state.

  ## Examples

      iex> Peers.update_state("portal_abc", "peer_123", :connected)
      {:ok, %{peer_id: "peer_123", connection_state: :connected, ...}}

  """
  @spec update_state(String.t(), String.t(), atom()) :: {:ok, map()} | {:error, atom()}
  def update_state(portal_id, peer_id, connection_state) do
    Presence.update_peer(portal_id, peer_id, %{connection_state: connection_state})
  end

  @doc """
  Update peer activity status.

  ## Examples

      iex> Peers.update_activity("portal_abc", "peer_123", :idle)
      {:ok, %{peer_id: "peer_123", activity_status: :idle, ...}}

  """
  @spec update_activity(String.t(), String.t(), atom()) :: {:ok, map()} | {:error, atom()}
  def update_activity(portal_id, peer_id, activity_status) do
    Presence.update_activity(portal_id, peer_id, activity_status)
  end
end
