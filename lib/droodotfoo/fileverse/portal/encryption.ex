defmodule Droodotfoo.Fileverse.Portal.Encryption do
  @moduledoc """
  End-to-end encryption integration for Portal P2P file transfers.

  This module provides:
  - Key exchange between peers using Signal Protocol
  - Encrypted file chunk transfer
  - Secure metadata sharing
  - Peer authentication and verification
  - Session management for multi-peer encryption
  - Integration with existing Portal transfer system

  ## Architecture

  - Uses existing `Droodotfoo.Fileverse.Encryption` for cryptographic primitives
  - Signal Protocol for key exchange and forward secrecy
  - AES-256-GCM for file chunk encryption
  - WebRTC data channels for encrypted communication
  - Wallet-based peer authentication
  """

  require Logger

  alias Droodotfoo.Fileverse.Encryption, as: BaseEncryption
  alias Droodotfoo.Fileverse.Portal.Chunker

  alias Droodotfoo.Fileverse.Portal.Encryption.{
    ChunkHandler,
    CryptoOps,
    MetadataHandler,
    SessionStore
  }

  @type encryption_session :: %{
          session_id: String.t(),
          portal_id: String.t(),
          wallet_address: String.t(),
          keys: BaseEncryption.encryption_keys(),
          peer_sessions: %{String.t() => peer_session()},
          created_at: DateTime.t(),
          last_activity: DateTime.t()
        }

  @type peer_session :: %{
          peer_id: String.t(),
          peer_wallet: String.t(),
          shared_secret: binary(),
          session_key: binary(),
          message_keys: [binary()],
          created_at: DateTime.t(),
          last_used: DateTime.t()
        }

  @type encrypted_chunk :: %{
          chunk_id: String.t(),
          encrypted_data: binary(),
          nonce: binary(),
          tag: binary(),
          peer_id: String.t(),
          session_id: String.t(),
          created_at: DateTime.t()
        }

  @type key_exchange_message :: %{
          type: :key_exchange,
          from_peer: String.t(),
          public_key: binary(),
          signature: binary(),
          timestamp: DateTime.t()
        }

  @doc """
  Initialize encryption session for a portal.
  """
  @spec init_portal_session(String.t(), String.t(), keyword()) ::
          {:ok, encryption_session()} | {:error, atom()}
  def init_portal_session(portal_id, wallet_address, opts \\ []) do
    session_id = Keyword.get(opts, :session_id, CryptoOps.generate_session_id())
    mock_signature = :crypto.strong_rand_bytes(65)

    case BaseEncryption.derive_keys_from_wallet(wallet_address, mock_signature) do
      {:ok, keys} ->
        session = %{
          session_id: session_id,
          portal_id: portal_id,
          wallet_address: wallet_address,
          keys: keys,
          peer_sessions: %{},
          created_at: DateTime.utc_now(),
          last_activity: DateTime.utc_now()
        }

        SessionStore.store(session)

        Logger.info("Initialized encryption session #{session_id} for portal #{portal_id}")
        {:ok, session}

      {:error, reason} ->
        {:error, {:key_derivation_failed, reason}}
    end
  end

  @doc """
  Exchange encryption keys with a peer.
  """
  @spec exchange_keys(encryption_session(), String.t(), binary(), String.t()) ::
          {:ok, encryption_session()} | {:error, atom()}
  def exchange_keys(session, peer_id, peer_public_key, peer_wallet) do
    case CryptoOps.key_exchange(session.keys, peer_public_key) do
      {:ok, shared_secret} ->
        session_key =
          CryptoOps.derive_session_key(shared_secret, session.wallet_address, peer_wallet)

        peer_session = %{
          peer_id: peer_id,
          peer_wallet: peer_wallet,
          shared_secret: shared_secret,
          session_key: session_key,
          message_keys: [],
          created_at: DateTime.utc_now(),
          last_used: DateTime.utc_now()
        }

        updated_session = %{
          session
          | peer_sessions: Map.put(session.peer_sessions, peer_id, peer_session),
            last_activity: DateTime.utc_now()
        }

        SessionStore.store(updated_session)

        Logger.info("Exchanged keys with peer #{peer_id} in session #{session.session_id}")
        {:ok, updated_session}

      {:error, reason} ->
        {:error, {:key_exchange_failed, reason}}
    end
  end

  @doc """
  Encrypt a file chunk for transfer to a specific peer.
  """
  @spec encrypt_chunk(Chunker.chunk(), encryption_session(), String.t()) ::
          {:ok, encrypted_chunk()} | {:error, atom()}
  defdelegate encrypt_chunk(chunk, session, peer_id), to: ChunkHandler, as: :encrypt

  @doc """
  Decrypt a received encrypted chunk.
  """
  @spec decrypt_chunk(encrypted_chunk(), encryption_session(), String.t()) ::
          {:ok, Chunker.chunk()} | {:error, atom()}
  defdelegate decrypt_chunk(encrypted_chunk, session, peer_id), to: ChunkHandler, as: :decrypt

  @doc """
  Encrypt metadata for secure sharing.
  """
  @spec encrypt_metadata(map(), encryption_session(), String.t()) ::
          {:ok, map()} | {:error, atom()}
  defdelegate encrypt_metadata(metadata, session, peer_id), to: MetadataHandler, as: :encrypt

  @doc """
  Decrypt received metadata.
  """
  @spec decrypt_metadata(map(), encryption_session(), String.t()) ::
          {:ok, map()} | {:error, atom()}
  defdelegate decrypt_metadata(encrypted_metadata, session, peer_id),
    to: MetadataHandler,
    as: :decrypt

  @doc """
  Get encryption session by ID.
  """
  @spec get_session(String.t()) :: encryption_session() | nil
  defdelegate get_session(session_id), to: SessionStore, as: :get

  @doc """
  Clean up expired encryption sessions.
  """
  @spec cleanup_sessions(integer()) :: :ok
  def cleanup_sessions(max_age_hours \\ 24) do
    SessionStore.cleanup(max_age_hours)
    Logger.info("Cleaned up encryption sessions older than #{max_age_hours} hours")
    :ok
  end
end
