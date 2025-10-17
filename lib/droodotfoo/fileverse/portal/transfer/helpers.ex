defmodule Droodotfoo.Fileverse.Portal.Transfer.Helpers do
  @moduledoc """
  Transfer utility functions.
  Handles transfer creation, storage, event broadcasting, and ID generation.
  """

  alias Droodotfoo.Fileverse.Portal.Chunker

  @doc """
  Create a new transfer record.

  ## Parameters

  - `portal_id`: Portal identifier
  - `file_id`: File identifier
  - `sender`: Sender's wallet address
  - `recipients`: List of recipient addresses
  - `metadata`: File metadata from Chunker

  ## Examples

      iex> Helpers.create_transfer("portal_abc", "file_123", "0x...", ["0x..."], metadata)
      %{id: "transfer_...", portal_id: "portal_abc", ...}

  """
  @spec create_transfer(String.t(), String.t(), String.t(), [String.t()], Chunker.file_metadata()) ::
          map()
  def create_transfer(portal_id, file_id, sender, recipients, metadata) do
    transfer_id = generate_transfer_id()

    %{
      id: transfer_id,
      file_id: file_id,
      portal_id: portal_id,
      sender: sender,
      recipients: recipients,
      filename: metadata.filename,
      size: metadata.size,
      state: :pending,
      progress: %{
        file_id: file_id,
        total_chunks: metadata.total_chunks,
        sent_chunks: 0,
        received_chunks: 0,
        failed_chunks: 0,
        progress_percentage: 0.0,
        estimated_time_remaining: 0,
        transfer_speed: 0.0
      },
      created_at: DateTime.utc_now(),
      started_at: nil,
      completed_at: nil,
      error: nil,
      metadata: metadata
    }
  end

  @doc """
  Store a transfer record.

  ## Parameters

  - `transfer`: Transfer record to store

  ## Examples

      iex> Helpers.store_transfer(transfer)
      :ok

  """
  @spec store_transfer(map()) :: :ok
  def store_transfer(_transfer) do
    # Mock implementation - in production would store in ETS or database
    :ok
  end

  @doc """
  Broadcast a transfer event to the portal.

  ## Parameters

  - `transfer`: Transfer record
  - `event_type`: Type of event (:started, :progress, :completed, :failed, :cancelled)
  - `data`: Additional event data

  ## Examples

      iex> Helpers.broadcast_transfer_event(transfer, :started, %{filename: "test.pdf"})
      :ok

  """
  @spec broadcast_transfer_event(map(), atom(), map()) :: :ok
  def broadcast_transfer_event(transfer, event_type, data) do
    event = %{
      transfer_id: transfer.id,
      event_type: event_type,
      data: data,
      timestamp: DateTime.utc_now()
    }

    # Broadcast to portal
    Phoenix.PubSub.broadcast(
      Droodotfoo.PubSub,
      "portal:#{transfer.portal_id}",
      {:transfer_event, event}
    )
  end

  @doc """
  Generate a unique transfer ID.

  ## Examples

      iex> Helpers.generate_transfer_id()
      "transfer_a1b2c3d4e5f67890"

  """
  @spec generate_transfer_id() :: String.t()
  def generate_transfer_id do
    "transfer_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end
end
