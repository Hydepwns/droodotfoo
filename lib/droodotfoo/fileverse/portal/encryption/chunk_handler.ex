defmodule Droodotfoo.Fileverse.Portal.Encryption.ChunkHandler do
  @moduledoc """
  Chunk encryption and decryption for Portal transfers.
  """

  require Logger

  alias Droodotfoo.Fileverse.Portal.Encryption.{CryptoOps, SessionStore}

  @doc """
  Encrypt a chunk for transfer to a peer.
  """
  def encrypt(chunk, session, peer_id) do
    case Map.get(session.peer_sessions, peer_id) do
      nil ->
        {:error, :peer_session_not_found}

      peer_session ->
        do_encrypt_chunk(chunk, session, peer_id, peer_session)
    end
  end

  @doc """
  Decrypt a received chunk.
  """
  def decrypt(encrypted_chunk, session, peer_id) do
    case Map.get(session.peer_sessions, peer_id) do
      nil ->
        {:error, :peer_session_not_found}

      peer_session ->
        do_decrypt_chunk(encrypted_chunk, session, peer_id, peer_session)
    end
  end

  defp do_encrypt_chunk(chunk, session, peer_id, peer_session) do
    case CryptoOps.encrypt(chunk.data, peer_session.session_key) do
      {:ok, {encrypted_data, nonce, tag}} ->
        encrypted_chunk = %{
          chunk_id: chunk.id,
          encrypted_data: encrypted_data,
          nonce: nonce,
          tag: tag,
          peer_id: peer_id,
          session_id: session.session_id,
          created_at: DateTime.utc_now()
        }

        SessionStore.update_peer_activity(session, peer_id)

        Logger.debug("Encrypted chunk #{chunk.id} for peer #{peer_id}")
        {:ok, encrypted_chunk}

      {:error, reason} ->
        {:error, {:encryption_failed, reason}}
    end
  end

  defp do_decrypt_chunk(encrypted_chunk, session, peer_id, peer_session) do
    case CryptoOps.decrypt(
           encrypted_chunk.encrypted_data,
           encrypted_chunk.nonce,
           encrypted_chunk.tag,
           peer_session.session_key
         ) do
      {:ok, decrypted_data} ->
        chunk = %{
          id: encrypted_chunk.chunk_id,
          file_id: "file_from_encrypted_chunk",
          index: 0,
          data: decrypted_data,
          size: byte_size(decrypted_data),
          checksum: CryptoOps.checksum(decrypted_data),
          is_last: false,
          created_at: encrypted_chunk.created_at
        }

        SessionStore.update_peer_activity(session, peer_id)

        Logger.debug("Decrypted chunk #{encrypted_chunk.chunk_id} from peer #{peer_id}")
        {:ok, chunk}

      {:error, reason} ->
        {:error, {:decryption_failed, reason}}
    end
  end
end
