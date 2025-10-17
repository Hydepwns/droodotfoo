defmodule Droodotfoo.Fileverse.Portal.Lifecycle do
  @moduledoc """
  Portal lifecycle management functions.
  Handles creating, joining, leaving, listing, and getting portals.
  """

  require Logger

  alias Droodotfoo.Fileverse.Portal.{Helpers, Presence}

  @doc """
  Create a new Portal space.

  ## Parameters

  - `name`: Portal name
  - `opts`: Keyword list of options
    - `:wallet_address` - Creator's wallet address (required)
    - `:public` - Make portal publicly accessible (default: false)
    - `:encrypted` - Enable E2E encryption (default: true)
    - `:max_peers` - Maximum number of peers (default: 10)

  ## Examples

      iex> Lifecycle.create("My Team Space", wallet_address: "0x...")
      {:ok, %{id: "portal_abc123", name: "My Team Space", ...}}

  """
  @spec create(String.t(), keyword()) :: {:ok, map()} | {:error, atom()}
  def create(name, opts \\ []) do
    wallet_address = Keyword.get(opts, :wallet_address)
    public = Keyword.get(opts, :public, false)
    encrypted = Keyword.get(opts, :encrypted, true)

    if wallet_address do
      # Mock implementation
      # Production would:
      # 1. Deploy Portal smart contract
      # 2. Initialize WebRTC signaling server
      # 3. Generate encryption keys if encrypted
      # 4. Register with Fileverse backend
      portal = %{
        id: "portal_" <> Helpers.generate_id(),
        name: name,
        creator: wallet_address,
        created_at: DateTime.utc_now(),
        peers: [
          %{
            address: wallet_address,
            ens_name: nil,
            connection_status: :connected,
            joined_at: DateTime.utc_now(),
            is_host: true
          }
        ],
        files_shared: 0,
        encrypted: encrypted,
        public: public
      }

      # Track creator as first peer
      case Presence.track_peer(portal.id, wallet_address,
             wallet_address: wallet_address,
             connection_state: :connected,
             metadata: %{is_host: true, created_at: portal.created_at}
           ) do
        {:ok, _presence} ->
          Logger.info("Created Portal: #{portal.id} (#{name})")
          {:ok, portal}

        {:error, reason} ->
          Logger.error("Failed to track creator in portal: #{inspect(reason)}")
          {:ok, portal}
      end
    else
      {:error, :wallet_required}
    end
  end

  @doc """
  Join an existing Portal space.

  ## Parameters

  - `portal_id`: Portal ID or invite code
  - `opts`: Keyword list of options
    - `:wallet_address` - Joiner's wallet address (required)

  ## Examples

      iex> Lifecycle.join("portal_abc123", wallet_address: "0x...")
      {:ok, %{id: "portal_abc123", peers: [...], ...}}

  """
  @spec join(String.t(), keyword()) :: {:ok, map()} | {:error, atom()}
  def join(portal_id, opts \\ []) do
    wallet_address = Keyword.get(opts, :wallet_address)

    if wallet_address do
      # Mock implementation
      # Production would:
      # 1. Verify portal exists and is accessible
      # 2. Establish WebRTC connection to peers
      # 3. Exchange encryption keys if encrypted
      # 4. Notify existing peers of new member
      # Track peer joining
      case Presence.track_peer(portal_id, wallet_address,
             wallet_address: wallet_address,
             connection_state: :connecting,
             metadata: %{joined_at: DateTime.utc_now()}
           ) do
        {:ok, _presence} ->
          portal = Helpers.get_mock_portal(portal_id, wallet_address)
          Logger.info("Joined Portal: #{portal_id}")
          {:ok, portal}

        {:error, reason} ->
          Logger.error("Failed to track peer in portal: #{inspect(reason)}")
          {:error, :presence_tracking_failed}
      end
    else
      {:error, :wallet_required}
    end
  end

  @doc """
  List available Portal spaces for a wallet.

  ## Examples

      iex> Lifecycle.list("0x...")
      {:ok, [%{id: "portal_123", name: "Team Space", ...}]}

  """
  @spec list(String.t()) :: {:ok, [map()]} | {:error, atom()}
  def list(wallet_address) do
    # Mock data
    # Production would fetch from smart contracts and backend
    portals = [
      %{
        id: "portal_abc123",
        name: "Team Collaboration",
        creator: "0x1234...5678",
        created_at: DateTime.add(DateTime.utc_now(), -3600 * 24 * 2, :second),
        peers: [
          %{
            address: wallet_address,
            ens_name: "alice.eth",
            connection_status: :connected,
            joined_at: DateTime.add(DateTime.utc_now(), -3600 * 24, :second),
            is_host: false
          },
          %{
            address: "0x1234...5678",
            ens_name: "bob.eth",
            connection_status: :connected,
            joined_at: DateTime.add(DateTime.utc_now(), -3600 * 48, :second),
            is_host: true
          }
        ],
        files_shared: 12,
        encrypted: true,
        public: false
      },
      %{
        id: "portal_def456",
        name: "Public Documents",
        creator: wallet_address,
        created_at: DateTime.add(DateTime.utc_now(), -3600 * 24 * 5, :second),
        peers: [
          %{
            address: wallet_address,
            ens_name: "alice.eth",
            connection_status: :connected,
            joined_at: DateTime.add(DateTime.utc_now(), -3600 * 120, :second),
            is_host: true
          }
        ],
        files_shared: 3,
        encrypted: false,
        public: true
      }
    ]

    {:ok, portals}
  end

  @doc """
  Get Portal details by ID.

  ## Examples

      iex> Lifecycle.get("portal_abc123")
      {:ok, %{id: "portal_abc123", ...}}

  """
  @spec get(String.t()) :: {:ok, map()} | {:error, atom()}
  def get(portal_id) do
    # Mock implementation
    case list("0xmock...address") do
      {:ok, portals} ->
        portal = Enum.find(portals, &(&1.id == portal_id))

        if portal do
          {:ok, portal}
        else
          {:error, :not_found}
        end

      error ->
        error
    end
  end

  @doc """
  Leave a Portal space.

  ## Examples

      iex> Lifecycle.leave("portal_abc123", wallet_address: "0x...")
      :ok

  """
  @spec leave(String.t(), keyword()) :: :ok | {:error, atom()}
  def leave(portal_id, opts \\ []) do
    wallet_address = Keyword.get(opts, :wallet_address)

    if wallet_address do
      # Remove from presence tracking
      case Presence.untrack_peer(portal_id, wallet_address) do
        :ok ->
          Logger.info("Left Portal: #{portal_id}")
          :ok

        {:error, reason} ->
          Logger.error("Failed to untrack peer from portal: #{inspect(reason)}")
          :ok
      end
    else
      {:error, :wallet_required}
    end
  end
end
