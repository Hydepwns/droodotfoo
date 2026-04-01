defmodule Droodotfoo.Fileverse.Portal.Transfer.Encryption do
  @moduledoc """
  Transfer encryption functions.
  Handles encryption initialization, key exchange, and chunk encryption/decryption.
  """

  require Logger

  alias Droodotfoo.Fileverse.Portal.Chunker
  alias Droodotfoo.Fileverse.Portal.Encryption, as: PortalEncryption
  alias Droodotfoo.Fileverse.Portal.Transfer.Storage

  @doc """
  Initialize encryption for a transfer.

  ## Parameters

  - `transfer_id`: Transfer identifier
  - `wallet_address`: Sender's wallet address

  ## Examples

      iex> Encryption.init_encryption("transfer_123", "0x...")
      {:ok, %{session_id: "session_123", ...}}

  """
  @spec init_encryption(String.t(), String.t()) :: {:ok, map()} | {:error, atom()}
  def init_encryption(transfer_id, wallet_address) do
    case Storage.get_transfer(transfer_id) do
      nil ->
        {:error, :transfer_not_found}

      transfer ->
        # Initialize encryption session for the portal
        case PortalEncryption.init_portal_session(transfer.portal_id, wallet_address) do
          {:ok, session} ->
            Logger.info("Initialized encryption for transfer #{transfer_id}")
            {:ok, %{session_id: session.session_id, session: session}}

          {:error, reason} ->
            {:error, {:encryption_init_failed, reason}}
        end
    end
  end

  @doc """
  Exchange encryption keys with a peer for a transfer.

  ## Parameters

  - `transfer_id`: Transfer identifier
  - `peer_id`: Peer identifier
  - `peer_public_key`: Peer's public key
  - `peer_wallet`: Peer's wallet address

  ## Examples

      iex> Encryption.exchange_keys("transfer_123", "peer_456", public_key, "0x...")
      {:ok, %{session_id: "session_123", ...}}

  """
  @spec exchange_keys(String.t(), String.t(), binary(), String.t()) ::
          {:ok, map()} | {:error, atom()}
  def exchange_keys(transfer_id, peer_id, peer_public_key, peer_wallet) do
    case Storage.get_transfer(transfer_id) do
      nil ->
        {:error, :transfer_not_found}

      transfer ->
        do_exchange_keys(transfer, transfer_id, peer_id, peer_public_key, peer_wallet)
    end
  end

  @doc """
  Encrypt file chunks for transfer.

  ## Parameters

  - `transfer_id`: Transfer identifier
  - `chunks`: List of file chunks to encrypt
  - `peer_id`: Target peer identifier

  ## Examples

      iex> Encryption.encrypt_chunks("transfer_123", chunks, "peer_456")
      {:ok, [%{chunk_id: "chunk_1", encrypted_data: <<...>>, ...}]}

  """
  @spec encrypt_chunks(String.t(), [Chunker.chunk()], String.t()) ::
          {:ok, [PortalEncryption.encrypted_chunk()]} | {:error, atom()}
  def encrypt_chunks(transfer_id, chunks, peer_id) do
    case Storage.get_transfer(transfer_id) do
      nil ->
        {:error, :transfer_not_found}

      transfer ->
        do_encrypt_chunks(transfer, transfer_id, chunks, peer_id)
    end
  end

  @doc """
  Decrypt received file chunks.

  ## Parameters

  - `transfer_id`: Transfer identifier
  - `encrypted_chunks`: List of encrypted chunks to decrypt
  - `peer_id`: Source peer identifier

  ## Examples

      iex> Encryption.decrypt_chunks("transfer_123", encrypted_chunks, "peer_456")
      {:ok, [%{id: "chunk_1", data: <<...>>, ...}]}

  """
  @spec decrypt_chunks(String.t(), [PortalEncryption.encrypted_chunk()], String.t()) ::
          {:ok, [Chunker.chunk()]} | {:error, atom()}
  def decrypt_chunks(transfer_id, encrypted_chunks, peer_id) do
    case Storage.get_transfer(transfer_id) do
      nil ->
        {:error, :transfer_not_found}

      transfer ->
        do_decrypt_chunks(transfer, transfer_id, encrypted_chunks, peer_id)
    end
  end

  # Private helper functions

  defp get_encryption_session(portal_id) do
    # Mock implementation - in production would query encryption session storage
    case portal_id do
      "portal_abc" ->
        %{
          session_id: "session_123",
          portal_id: portal_id,
          wallet_address: "0x1234567890abcdef1234567890abcdef12345678",
          keys: %{
            public_key: :crypto.strong_rand_bytes(32),
            private_key: :crypto.strong_rand_bytes(32),
            wallet_address: "0x1234567890abcdef1234567890abcdef12345678"
          },
          peer_sessions: %{
            "peer_456" => %{
              peer_id: "peer_456",
              peer_wallet: "0x876543210fedcba9876543210fedcba9876543210",
              shared_secret: :crypto.strong_rand_bytes(32),
              session_key: :crypto.strong_rand_bytes(32),
              message_keys: [],
              created_at: DateTime.add(DateTime.utc_now(), -300, :second),
              last_used: DateTime.utc_now()
            }
          },
          created_at: DateTime.add(DateTime.utc_now(), -600, :second),
          last_activity: DateTime.utc_now()
        }

      _ ->
        nil
    end
  end

  defp do_exchange_keys(transfer, transfer_id, peer_id, peer_public_key, peer_wallet) do
    case get_encryption_session(transfer.portal_id) do
      nil ->
        {:error, :encryption_session_not_found}

      session ->
        perform_key_exchange(session, transfer_id, peer_id, peer_public_key, peer_wallet)
    end
  end

  defp perform_key_exchange(session, transfer_id, peer_id, peer_public_key, peer_wallet) do
    case PortalEncryption.exchange_keys(session, peer_id, peer_public_key, peer_wallet) do
      {:ok, updated_session} ->
        Logger.info("Exchanged keys for transfer #{transfer_id} with peer #{peer_id}")
        {:ok, %{session_id: updated_session.session_id, session: updated_session}}

      {:error, reason} ->
        {:error, {:key_exchange_failed, reason}}
    end
  end

  defp do_encrypt_chunks(transfer, transfer_id, chunks, peer_id) do
    case get_encryption_session(transfer.portal_id) do
      nil ->
        {:error, :encryption_session_not_found}

      session ->
        encrypt_chunks_with_session(session, transfer_id, chunks, peer_id)
    end
  end

  defp encrypt_chunks_with_session(session, transfer_id, chunks, peer_id) do
    encrypted_chunks =
      Enum.map(chunks, fn chunk ->
        case PortalEncryption.encrypt_chunk(chunk, session, peer_id) do
          {:ok, encrypted_chunk} -> encrypted_chunk
          {:error, reason} -> {:error, reason}
        end
      end)

    check_encryption_errors(encrypted_chunks, transfer_id)
  end

  defp check_encryption_errors(encrypted_chunks, transfer_id) do
    case Enum.find(encrypted_chunks, &match?({:error, _}, &1)) do
      nil ->
        Logger.info("Encrypted #{length(encrypted_chunks)} chunks for transfer #{transfer_id}")
        {:ok, encrypted_chunks}

      {:error, reason} ->
        {:error, {:encryption_failed, reason}}
    end
  end

  defp do_decrypt_chunks(transfer, transfer_id, encrypted_chunks, peer_id) do
    case get_encryption_session(transfer.portal_id) do
      nil ->
        {:error, :encryption_session_not_found}

      session ->
        decrypt_chunks_with_session(session, transfer_id, encrypted_chunks, peer_id)
    end
  end

  defp decrypt_chunks_with_session(session, transfer_id, encrypted_chunks, peer_id) do
    decrypted_chunks =
      Enum.map(encrypted_chunks, fn encrypted_chunk ->
        case PortalEncryption.decrypt_chunk(encrypted_chunk, session, peer_id) do
          {:ok, decrypted_chunk} -> decrypted_chunk
          {:error, reason} -> {:error, reason}
        end
      end)

    check_decryption_errors(decrypted_chunks, transfer_id, length(encrypted_chunks))
  end

  defp check_decryption_errors(decrypted_chunks, transfer_id, chunk_count) do
    case Enum.find(decrypted_chunks, &match?({:error, _}, &1)) do
      nil ->
        Logger.info("Decrypted #{chunk_count} chunks for transfer #{transfer_id}")
        {:ok, decrypted_chunks}

      {:error, reason} ->
        {:error, {:decryption_failed, reason}}
    end
  end
end
