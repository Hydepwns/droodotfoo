defmodule Droodotfoo.Fileverse.Portal.Transfer do
  @moduledoc """
  File transfer management for Portal P2P collaboration.

  Handles:
  - File transfer coordination
  - Progress tracking and reporting
  - Transfer state management
  - Resume capability for failed transfers
  - Transfer integrity verification
  - WebRTC data channel integration
  - Transfer notifications and events

  Integrates with Chunker for file processing and WebRTC for P2P delivery.

  This module has been refactored into focused submodules:
  - Lifecycle - Transfer lifecycle management (start, update, complete, cancel, resume)
  - Storage - Transfer storage and retrieval
  - Encryption - Encryption operations (init, key exchange, encrypt/decrypt chunks)
  - Helpers - Utility functions (create, store, broadcast, generate ID)
  """

  alias Droodotfoo.Fileverse.Portal.Chunker
  alias Droodotfoo.Fileverse.Portal.Transfer.{Encryption, Lifecycle, Storage}

  @type transfer_state :: :pending | :transferring | :paused | :completed | :failed | :cancelled
  @type transfer :: %{
          id: String.t(),
          file_id: String.t(),
          portal_id: String.t(),
          sender: String.t(),
          recipients: [String.t()],
          filename: String.t(),
          size: integer(),
          state: transfer_state(),
          progress: Chunker.transfer_progress(),
          created_at: DateTime.t(),
          started_at: DateTime.t() | nil,
          completed_at: DateTime.t() | nil,
          error: String.t() | nil,
          metadata: Chunker.file_metadata()
        }

  @type transfer_event :: %{
          transfer_id: String.t(),
          event_type: :started | :progress | :completed | :failed | :cancelled,
          data: map(),
          timestamp: DateTime.t()
        }

  # Transfer Lifecycle Functions

  @doc """
  Start a new file transfer.

  See `Droodotfoo.Fileverse.Portal.Transfer.Lifecycle.start_transfer/3` for details.
  """
  @spec start_transfer(String.t(), String.t(), keyword()) :: {:ok, transfer()} | {:error, atom()}
  def start_transfer(portal_id, file_path, opts \\ []) do
    Lifecycle.start_transfer(portal_id, file_path, opts)
  end

  @doc """
  Start transfer from file data.

  See `Droodotfoo.Fileverse.Portal.Transfer.Lifecycle.start_transfer_data/4` for details.
  """
  @spec start_transfer_data(String.t(), binary(), String.t(), keyword()) ::
          {:ok, transfer()} | {:error, atom()}
  def start_transfer_data(portal_id, file_data, filename, opts \\ []) do
    Lifecycle.start_transfer_data(portal_id, file_data, filename, opts)
  end

  @doc """
  Update transfer progress.

  See `Droodotfoo.Fileverse.Portal.Transfer.Lifecycle.update_progress/2` for details.
  """
  @spec update_progress(String.t(), map()) :: {:ok, transfer()} | {:error, atom()}
  def update_progress(transfer_id, progress_data) do
    Lifecycle.update_progress(transfer_id, progress_data)
  end

  @doc """
  Complete a transfer.

  See `Droodotfoo.Fileverse.Portal.Transfer.Lifecycle.complete_transfer/2` for details.
  """
  @spec complete_transfer(String.t(), boolean()) :: {:ok, transfer()} | {:error, atom()}
  def complete_transfer(transfer_id, success \\ true) do
    Lifecycle.complete_transfer(transfer_id, success)
  end

  @doc """
  Cancel a transfer.

  See `Droodotfoo.Fileverse.Portal.Transfer.Lifecycle.cancel_transfer/1` for details.
  """
  @spec cancel_transfer(String.t()) :: {:ok, transfer()} | {:error, atom()}
  def cancel_transfer(transfer_id) do
    Lifecycle.cancel_transfer(transfer_id)
  end

  @doc """
  Resume a failed transfer.

  See `Droodotfoo.Fileverse.Portal.Transfer.Lifecycle.resume_transfer/1` for details.
  """
  @spec resume_transfer(String.t()) :: {:ok, transfer()} | {:error, atom()}
  def resume_transfer(transfer_id) do
    Lifecycle.resume_transfer(transfer_id)
  end

  # Transfer Storage Functions

  @doc """
  Get transfer by ID.

  See `Droodotfoo.Fileverse.Portal.Transfer.Storage.get_transfer/1` for details.
  """
  @spec get_transfer(String.t()) :: transfer() | nil
  def get_transfer(transfer_id) do
    Storage.get_transfer(transfer_id)
  end

  @doc """
  Get transfers for a portal.

  See `Droodotfoo.Fileverse.Portal.Transfer.Storage.get_portal_transfers/1` for details.
  """
  @spec get_portal_transfers(String.t()) :: [transfer()]
  def get_portal_transfers(portal_id) do
    Storage.get_portal_transfers(portal_id)
  end

  @doc """
  Get active transfers for a portal.

  See `Droodotfoo.Fileverse.Portal.Transfer.Storage.get_active_transfers/1` for details.
  """
  @spec get_active_transfers(String.t()) :: [transfer()]
  def get_active_transfers(portal_id) do
    Storage.get_active_transfers(portal_id)
  end

  # Transfer Encryption Functions

  @doc """
  Initialize encryption for a transfer.

  See `Droodotfoo.Fileverse.Portal.Transfer.Encryption.init_encryption/2` for details.
  """
  @spec init_encryption(String.t(), String.t()) :: {:ok, map()} | {:error, atom()}
  def init_encryption(transfer_id, wallet_address) do
    Encryption.init_encryption(transfer_id, wallet_address)
  end

  @doc """
  Exchange encryption keys with a peer for a transfer.

  See `Droodotfoo.Fileverse.Portal.Transfer.Encryption.exchange_keys/4` for details.
  """
  @spec exchange_keys(String.t(), String.t(), binary(), String.t()) ::
          {:ok, map()} | {:error, atom()}
  def exchange_keys(transfer_id, peer_id, peer_public_key, peer_wallet) do
    Encryption.exchange_keys(transfer_id, peer_id, peer_public_key, peer_wallet)
  end

  @doc """
  Encrypt file chunks for transfer.

  See `Droodotfoo.Fileverse.Portal.Transfer.Encryption.encrypt_chunks/3` for details.
  """
  @spec encrypt_chunks(String.t(), [Chunker.chunk()], String.t()) ::
          {:ok, [Droodotfoo.Fileverse.Portal.Encryption.encrypted_chunk()]} | {:error, atom()}
  def encrypt_chunks(transfer_id, chunks, peer_id) do
    Encryption.encrypt_chunks(transfer_id, chunks, peer_id)
  end

  @doc """
  Decrypt received file chunks.

  See `Droodotfoo.Fileverse.Portal.Transfer.Encryption.decrypt_chunks/3` for details.
  """
  @spec decrypt_chunks(
          String.t(),
          [Droodotfoo.Fileverse.Portal.Encryption.encrypted_chunk()],
          String.t()
        ) :: {:ok, [Chunker.chunk()]} | {:error, atom()}
  def decrypt_chunks(transfer_id, encrypted_chunks, peer_id) do
    Encryption.decrypt_chunks(transfer_id, encrypted_chunks, peer_id)
  end
end
