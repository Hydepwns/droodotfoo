defmodule Droodotfoo.Fileverse.Portal.Transfer.Storage do
  @moduledoc """
  Transfer storage and retrieval functions.
  Handles getting transfers by ID, portal, and active status.
  """

  @doc """
  Get transfer by ID.

  ## Parameters

  - `transfer_id`: Transfer identifier

  ## Examples

      iex> Storage.get_transfer("transfer_123")
      %{id: "transfer_123", state: :transferring, ...}

  """
  @spec get_transfer(String.t()) :: map() | nil
  def get_transfer(transfer_id) do
    # Mock implementation - in production would query ETS or database
    get_mock_transfer(transfer_id)
  end

  @doc """
  Get transfers for a portal.

  ## Parameters

  - `portal_id`: Portal identifier

  ## Examples

      iex> Storage.get_portal_transfers("portal_abc")
      [%{id: "transfer_123", portal_id: "portal_abc", ...}]

  """
  @spec get_portal_transfers(String.t()) :: [map()]
  def get_portal_transfers(_portal_id) do
    # Mock implementation - in production would query by portal_id
    []
  end

  @doc """
  Get active transfers for a portal.

  ## Parameters

  - `portal_id`: Portal identifier

  ## Examples

      iex> Storage.get_active_transfers("portal_abc")
      [%{id: "transfer_123", state: :transferring, ...}]

  """
  @spec get_active_transfers(String.t()) :: [map()]
  def get_active_transfers(portal_id) do
    get_portal_transfers(portal_id)
    |> Enum.filter(fn transfer -> transfer.state in [:pending, :transferring] end)
  end

  # Private mock implementation

  defp get_mock_transfer(transfer_id) do
    # Only return mock data for specific test transfer IDs
    case transfer_id do
      "transfer_123" ->
        %{
          id: transfer_id,
          file_id: "file_abc123",
          portal_id: "portal_abc",
          sender: "0x1234567890abcdef1234567890abcdef12345678",
          recipients: ["0x876543210fedcba9876543210fedcba9876543210"],
          filename: "test.pdf",
          size: 1024,
          state: :failed,
          progress: %{
            file_id: "file_abc123",
            total_chunks: 10,
            sent_chunks: 5,
            received_chunks: 3,
            failed_chunks: 0,
            progress_percentage: 30.0,
            estimated_time_remaining: 60,
            transfer_speed: 0.5
          },
          created_at: DateTime.add(DateTime.utc_now(), -300, :second),
          started_at: DateTime.add(DateTime.utc_now(), -240, :second),
          completed_at: nil,
          error: nil,
          metadata: %{
            id: "file_abc123",
            filename: "test.pdf",
            size: 1024,
            mime_type: "application/pdf",
            checksum: "abc123def456",
            total_chunks: 10,
            chunk_size: 1024,
            created_at: DateTime.add(DateTime.utc_now(), -300, :second),
            sender: "0x1234567890abcdef1234567890abcdef12345678",
            recipients: ["0x876543210fedcba9876543210fedcba9876543210"]
          }
        }

      _ ->
        nil
    end
  end
end
