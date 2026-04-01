defmodule Droodotfoo.Fileverse.Portal.Encryption.MetadataHandler do
  @moduledoc """
  Metadata encryption and decryption for Portal transfers.
  """

  require Logger

  alias Droodotfoo.Fileverse.Portal.Encryption.CryptoOps

  @doc """
  Encrypt metadata for a peer.
  """
  def encrypt(metadata, session, peer_id) do
    case Map.get(session.peer_sessions, peer_id) do
      nil ->
        {:error, :peer_session_not_found}

      peer_session ->
        do_encrypt_metadata(metadata, session, peer_id, peer_session)
    end
  end

  @doc """
  Decrypt metadata from a peer.
  """
  def decrypt(encrypted_metadata, session, peer_id) do
    case Map.get(session.peer_sessions, peer_id) do
      nil ->
        {:error, :peer_session_not_found}

      peer_session ->
        do_decrypt_metadata(encrypted_metadata, peer_id, peer_session)
    end
  end

  defp do_encrypt_metadata(metadata, session, peer_id, peer_session) do
    metadata_json = Jason.encode!(metadata)

    case CryptoOps.encrypt(metadata_json, peer_session.session_key) do
      {:ok, {encrypted_data, nonce, tag}} ->
        encrypted_metadata = %{
          encrypted_metadata: encrypted_data,
          nonce: nonce,
          tag: tag,
          peer_id: peer_id,
          session_id: session.session_id,
          created_at: DateTime.utc_now()
        }

        Logger.debug("Encrypted metadata for peer #{peer_id}")
        {:ok, encrypted_metadata}

      {:error, reason} ->
        {:error, {:encryption_failed, reason}}
    end
  end

  defp do_decrypt_metadata(encrypted_metadata, peer_id, peer_session) do
    case CryptoOps.decrypt(
           encrypted_metadata.encrypted_metadata,
           encrypted_metadata.nonce,
           encrypted_metadata.tag,
           peer_session.session_key
         ) do
      {:ok, decrypted_json} ->
        parse_metadata_json(decrypted_json, peer_id)

      {:error, reason} ->
        {:error, {:decryption_failed, reason}}
    end
  end

  defp parse_metadata_json(decrypted_json, peer_id) do
    case Jason.decode(decrypted_json) do
      {:ok, metadata} ->
        Logger.debug("Decrypted metadata from peer #{peer_id}")
        {:ok, metadata}

      {:error, reason} ->
        {:error, {:json_parse_failed, reason}}
    end
  end
end
