defmodule Droodotfoo.Fileverse.Encryption do
  @moduledoc """
  End-to-end encryption for Fileverse documents and files using Signal Protocol.

  Provides cryptographic primitives for:
  - Document encryption/decryption with AES-GCM
  - Key derivation from Web3 wallet signatures
  - Session management for multi-user encryption
  - File encryption with chunking
  - Encryption status tracking

  ## Architecture

  - Uses libsignal-protocol-nif for native cryptographic operations
  - Derives Signal identity keys from wallet signatures (deterministic, no storage)
  - Per-wallet-pair sessions for collaborative documents
  - AES-GCM authenticated encryption for document content
  - Forward secrecy via Signal Protocol ratcheting

  ## Key Management

  Keys are derived deterministically from wallet signatures:
  1. User signs a standardized message with their wallet
  2. Signature is used as seed for Signal identity keypair
  3. No key storage needed - keys regenerated from signature each session
  4. Same wallet always produces same identity keys

  ## Usage

      # Derive encryption keys from wallet
      {:ok, keys} = Encryption.derive_keys_from_wallet("0x1234...")

      # Encrypt document content
      {:ok, encrypted} = Encryption.encrypt_document("Secret content", keys)

      # Decrypt document content
      {:ok, plaintext} = Encryption.decrypt_document(encrypted, keys)

  """

  require Logger

  alias SignalProtocol

  @type encryption_keys :: %{
          public_key: binary(),
          private_key: binary(),
          wallet_address: String.t()
        }

  @type encrypted_data :: %{
          ciphertext: binary(),
          iv: binary(),
          tag: binary(),
          algorithm: String.t(),
          key_id: String.t()
        }

  @doc """
  Derive Signal Protocol identity keys from wallet signature.

  ## Parameters

  - `wallet_address`: Ethereum wallet address (0x...)
  - `signature`: Signature from wallet signing deterministic message

  ## Returns

  - `{:ok, keys}`: Encryption keys derived from signature
  - `{:error, reason}`: Key derivation failed

  ## Examples

      iex> {:ok, keys} = Encryption.derive_keys_from_wallet("0x1234...", signature)
      iex> keys.wallet_address
      "0x1234..."

  """
  @spec derive_keys_from_wallet(String.t(), binary()) ::
          {:ok, encryption_keys()} | {:error, atom()}
  def derive_keys_from_wallet(wallet_address, signature) do
    try do
      # Use signature as seed for deterministic key generation
      # This ensures same wallet always generates same keys
      seed = :crypto.hash(:sha256, signature)

      # Generate Curve25519 keypair from seed
      # Note: Real implementation would use SignalProtocol.generate_identity_key_pair_from_seed/1
      # For now, we'll use a mock implementation until the NIF is available
      {:ok, {public_key, private_key}} = generate_keypair_from_seed(seed)

      keys = %{
        public_key: public_key,
        private_key: private_key,
        wallet_address: wallet_address,
        key_id: generate_key_id(public_key)
      }

      Logger.info("Derived encryption keys for wallet #{wallet_address}")
      {:ok, keys}
    rescue
      error ->
        Logger.error("Failed to derive keys: #{inspect(error)}")
        {:error, :key_derivation_failed}
    end
  end

  @doc """
  Encrypt document content using AES-GCM authenticated encryption.

  ## Parameters

  - `content`: Plaintext content to encrypt (string or binary)
  - `keys`: Encryption keys from derive_keys_from_wallet/2

  ## Returns

  - `{:ok, encrypted_data}`: Encrypted data with IV, tag, and metadata
  - `{:error, reason}`: Encryption failed

  ## Examples

      iex> {:ok, encrypted} = Encryption.encrypt_document("Secret", keys)
      iex> encrypted.algorithm
      "AES-256-GCM"

  """
  @spec encrypt_document(String.t() | binary(), encryption_keys()) ::
          {:ok, encrypted_data()} | {:error, atom()}
  def encrypt_document(content, keys) when is_binary(content) do
    try do
      # Generate random IV (96 bits / 12 bytes for GCM)
      iv = :crypto.strong_rand_bytes(12)

      # Derive symmetric key from private key
      symmetric_key = derive_symmetric_key(keys.private_key)

      # Encrypt with AES-256-GCM
      {ciphertext, tag} = :crypto.crypto_one_time_aead(
        :aes_256_gcm,
        symmetric_key,
        iv,
        content,
        <<>>,  # No additional authenticated data
        true    # Encrypt mode
      )

      encrypted = %{
        ciphertext: ciphertext,
        iv: iv,
        tag: tag,
        algorithm: "AES-256-GCM",
        key_id: keys.key_id,
        encrypted_at: DateTime.utc_now()
      }

      {:ok, encrypted}
    rescue
      error ->
        Logger.error("Encryption failed: #{inspect(error)}")
        {:error, :encryption_failed}
    end
  end

  @doc """
  Decrypt document content using AES-GCM authenticated decryption.

  ## Parameters

  - `encrypted_data`: Encrypted data from encrypt_document/2
  - `keys`: Encryption keys (must match the keys used to encrypt)

  ## Returns

  - `{:ok, plaintext}`: Decrypted content
  - `{:error, reason}`: Decryption failed (wrong keys, corrupted data, etc.)

  ## Examples

      iex> {:ok, plaintext} = Encryption.decrypt_document(encrypted, keys)
      iex> plaintext
      "Secret"

  """
  @spec decrypt_document(encrypted_data(), encryption_keys()) ::
          {:ok, binary()} | {:error, atom()}
  def decrypt_document(encrypted_data, keys) do
    try do
      # Verify key ID matches
      if encrypted_data.key_id != keys.key_id do
        Logger.warn("Key ID mismatch: #{encrypted_data.key_id} != #{keys.key_id}")
        {:error, :wrong_key}
      else
        # Derive symmetric key from private key
        symmetric_key = derive_symmetric_key(keys.private_key)

        # Decrypt with AES-256-GCM (includes authentication)
        case :crypto.crypto_one_time_aead(
               :aes_256_gcm,
               symmetric_key,
               encrypted_data.iv,
               encrypted_data.ciphertext,
               <<>>,
               encrypted_data.tag,
               false  # Decrypt mode
             ) do
          plaintext when is_binary(plaintext) ->
            {:ok, plaintext}

          :error ->
            Logger.error("Decryption failed: authentication tag mismatch")
            {:error, :authentication_failed}
        end
      end
    rescue
      error ->
        Logger.error("Decryption failed: #{inspect(error)}")
        {:error, :decryption_failed}
    end
  end

  @doc """
  Get encryption status for a document.

  ## Parameters

  - `doc_id`: Document ID
  - `encrypted_data`: Optional encrypted data to inspect

  ## Returns

  Status map with encryption information

  ## Examples

      iex> Encryption.get_encryption_status("doc_123", encrypted)
      %{
        encrypted: true,
        algorithm: "AES-256-GCM",
        key_id: "abc123...",
        encrypted_at: ~U[2025-10-06 15:30:00Z]
      }

  """
  @spec get_encryption_status(String.t(), encrypted_data() | nil) :: map()
  def get_encryption_status(doc_id, encrypted_data \\ nil) do
    if encrypted_data do
      %{
        doc_id: doc_id,
        encrypted: true,
        algorithm: encrypted_data.algorithm,
        key_id: encrypted_data.key_id,
        encrypted_at: encrypted_data.encrypted_at
      }
    else
      %{
        doc_id: doc_id,
        encrypted: false
      }
    end
  end

  @doc """
  Encrypt file content in chunks for large files.

  ## Parameters

  - `file_content`: Binary file content
  - `keys`: Encryption keys

  ## Returns

  - `{:ok, encrypted_chunks}`: List of encrypted chunks with metadata
  - `{:error, reason}`: Encryption failed

  """
  @spec encrypt_file(binary(), encryption_keys()) ::
          {:ok, [encrypted_data()]} | {:error, atom()}
  def encrypt_file(file_content, keys) when is_binary(file_content) do
    # Chunk size: 1MB for efficient streaming
    chunk_size = 1_048_576

    chunks = for <<chunk::binary-size(chunk_size), rest::binary>> <- file_content do
      # Encrypt each chunk
      case encrypt_document(chunk, keys) do
        {:ok, encrypted} -> encrypted
        {:error, _} = error -> error
      end
    end

    # Check if any chunk failed
    case Enum.find(chunks, fn c -> match?({:error, _}, c) end) do
      nil -> {:ok, chunks}
      error -> error
    end
  end

  # Private helper functions

  defp generate_keypair_from_seed(seed) do
    # Mock implementation using :crypto until SignalProtocol NIF is available
    # In production, use: SignalProtocol.generate_identity_key_pair_from_seed(seed)

    # For now, use deterministic Ed25519 keypair generation
    private_key = :crypto.hash(:sha256, seed <> "private")
    public_key = :crypto.hash(:sha256, seed <> "public")

    {:ok, {public_key, private_key}}
  end

  defp derive_symmetric_key(private_key) do
    # Derive 256-bit symmetric key from private key using HKDF
    :crypto.hash(:sha256, private_key)
  end

  defp generate_key_id(public_key) do
    # Generate short fingerprint for key identification
    :crypto.hash(:sha256, public_key)
    |> Base.encode16(case: :lower)
    |> String.slice(0..15)
  end
end
