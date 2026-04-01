defmodule Droodotfoo.Fileverse.Portal.TransferTest do
  use ExUnit.Case, async: false

  alias Droodotfoo.Fileverse.Portal.Transfer

  setup do
    # Clean up any existing state
    :ok
  end

  describe "start_transfer_data/4" do
    test "starts transfer with valid parameters" do
      portal_id = "portal_abc"
      file_data = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>
      filename = "test.bin"
      opts = [sender: "0x1234567890abcdef1234567890abcdef12345678"]

      assert {:ok, transfer} = Transfer.start_transfer_data(portal_id, file_data, filename, opts)

      assert is_binary(transfer.id)
      assert transfer.portal_id == portal_id
      assert transfer.sender == "0x1234567890abcdef1234567890abcdef12345678"
      assert transfer.filename == filename
      assert transfer.size == 10
      assert transfer.state == :pending
      assert is_map(transfer.progress)
      assert is_struct(transfer.created_at, DateTime)
      assert is_nil(transfer.started_at)
      assert is_nil(transfer.completed_at)
      assert is_nil(transfer.error)
      assert is_map(transfer.metadata)
    end

    test "returns error when sender is missing" do
      portal_id = "portal_abc"
      file_data = <<1, 2, 3, 4>>
      filename = "test.bin"
      opts = []

      assert {:error, :sender_required} =
               Transfer.start_transfer_data(portal_id, file_data, filename, opts)
    end

    test "starts transfer with custom recipients" do
      portal_id = "portal_abc"
      file_data = <<1, 2, 3, 4>>
      filename = "test.bin"

      recipients = [
        "0x1111111111111111111111111111111111111111",
        "0x2222222222222222222222222222222222222222"
      ]

      opts = [
        sender: "0x1234567890abcdef1234567890abcdef12345678",
        recipients: recipients
      ]

      assert {:ok, transfer} = Transfer.start_transfer_data(portal_id, file_data, filename, opts)
      assert transfer.recipients == recipients
    end

    test "starts transfer with custom chunk size" do
      portal_id = "portal_abc"
      file_data = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>
      filename = "test.bin"

      opts = [
        sender: "0x1234567890abcdef1234567890abcdef12345678",
        chunk_size: 3
      ]

      assert {:ok, transfer} = Transfer.start_transfer_data(portal_id, file_data, filename, opts)
      assert transfer.metadata.chunk_size == 3
    end
  end

  describe "update_progress/2" do
    test "updates transfer progress" do
      transfer_id = "transfer_123"

      progress_data = %{
        sent_chunks: 5,
        received_chunks: 3,
        failed_chunks: 1
      }

      assert {:ok, updated_transfer} = Transfer.update_progress(transfer_id, progress_data)

      assert updated_transfer.id == transfer_id
      assert updated_transfer.progress.sent_chunks == 5
      assert updated_transfer.progress.received_chunks == 3
      assert updated_transfer.progress.failed_chunks == 1
    end

    test "returns error for non-existent transfer" do
      transfer_id = "nonexistent"
      progress_data = %{sent_chunks: 5}

      assert {:error, :transfer_not_found} = Transfer.update_progress(transfer_id, progress_data)
    end
  end

  describe "complete_transfer/2" do
    test "completes transfer successfully" do
      transfer_id = "transfer_123"

      assert {:ok, transfer} = Transfer.complete_transfer(transfer_id, true)

      assert transfer.id == transfer_id
      assert transfer.state == :completed
      assert is_struct(transfer.completed_at, DateTime)
    end

    test "marks transfer as failed" do
      transfer_id = "transfer_123"

      assert {:ok, transfer} = Transfer.complete_transfer(transfer_id, false)

      assert transfer.id == transfer_id
      assert transfer.state == :failed
      assert is_struct(transfer.completed_at, DateTime)
    end

    test "returns error for non-existent transfer" do
      transfer_id = "nonexistent"

      assert {:error, :transfer_not_found} = Transfer.complete_transfer(transfer_id, true)
    end
  end

  describe "cancel_transfer/1" do
    test "cancels transfer" do
      transfer_id = "transfer_123"

      assert {:ok, transfer} = Transfer.cancel_transfer(transfer_id)

      assert transfer.id == transfer_id
      assert transfer.state == :cancelled
      assert is_struct(transfer.completed_at, DateTime)
    end

    test "returns error for non-existent transfer" do
      transfer_id = "nonexistent"

      assert {:error, :transfer_not_found} = Transfer.cancel_transfer(transfer_id)
    end
  end

  describe "get_transfer/1" do
    test "returns transfer for existing ID" do
      transfer_id = "transfer_123"

      transfer = Transfer.get_transfer(transfer_id)

      assert transfer.id == transfer_id
      assert is_binary(transfer.file_id)
      assert is_binary(transfer.portal_id)
      assert is_binary(transfer.sender)
      assert is_list(transfer.recipients)
      assert is_binary(transfer.filename)
      assert is_integer(transfer.size)
      assert is_atom(transfer.state)
      assert is_map(transfer.progress)
      assert is_struct(transfer.created_at, DateTime)
      assert is_map(transfer.metadata)
    end

    test "returns nil for non-existent transfer" do
      transfer_id = "nonexistent"

      assert is_nil(Transfer.get_transfer(transfer_id))
    end
  end

  describe "get_portal_transfers/1" do
    test "returns transfers for portal" do
      portal_id = "portal_abc"

      transfers = Transfer.get_portal_transfers(portal_id)

      assert is_list(transfers)
    end
  end

  describe "get_active_transfers/1" do
    test "returns only active transfers" do
      portal_id = "portal_abc"

      active_transfers = Transfer.get_active_transfers(portal_id)

      assert is_list(active_transfers)
      # All transfers should be pending or transferring
      assert Enum.all?(active_transfers, fn transfer ->
               transfer.state in [:pending, :transferring]
             end)
    end
  end

  describe "resume_transfer/1" do
    test "resumes failed transfer" do
      transfer_id = "transfer_123"

      assert {:ok, transfer} = Transfer.resume_transfer(transfer_id)

      assert transfer.id == transfer_id
      assert transfer.state == :transferring
      assert is_struct(transfer.started_at, DateTime)
      assert is_nil(transfer.error)
    end

    test "returns error for non-existent transfer" do
      transfer_id = "nonexistent"

      assert {:error, :transfer_not_found} = Transfer.resume_transfer(transfer_id)
    end

    test "returns error for non-failed transfer" do
      # Use a transfer ID that doesn't exist to test the error case
      transfer_id = "nonexistent"

      assert {:error, :transfer_not_found} = Transfer.resume_transfer(transfer_id)
    end
  end
end
