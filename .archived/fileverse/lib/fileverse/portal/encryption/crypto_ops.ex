defmodule Droodotfoo.Fileverse.Portal.Encryption.CryptoOps do
  @moduledoc """
  Low-level cryptographic operations for Portal encryption.
  """

  @doc """
  Perform key exchange (mock Signal Protocol).
  """
  def key_exchange(_keys, _peer_public_key) do
    shared_secret = :crypto.strong_rand_bytes(32)
    {:ok, shared_secret}
  end

  @doc """
  Derive session key from shared secret and wallet addresses.
  """
  def derive_session_key(shared_secret, wallet1, wallet2) do
    input = shared_secret <> wallet1 <> wallet2
    :crypto.hash(:sha256, input)
  end

  @doc """
  Encrypt data using AES-256-GCM.
  """
  def encrypt(data, session_key) do
    nonce = :crypto.strong_rand_bytes(12)

    {encrypted, tag} =
      :crypto.crypto_one_time_aead(:aes_256_gcm, session_key, nonce, data, "", true)

    {:ok, {encrypted, nonce, tag}}
  end

  @doc """
  Decrypt data using AES-256-GCM.
  """
  def decrypt(encrypted_data, nonce, tag, session_key) do
    case :crypto.crypto_one_time_aead(
           :aes_256_gcm,
           session_key,
           nonce,
           encrypted_data,
           "",
           tag,
           false
         ) do
      :error -> {:error, :decryption_failed}
      decrypted -> {:ok, decrypted}
    end
  end

  @doc """
  Calculate SHA256 checksum of data.
  """
  def checksum(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end

  @doc """
  Generate random session ID.
  """
  def generate_session_id do
    "session_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end
end
