defmodule Droodotfoo.Web3.Auth do
  @moduledoc """
  Handles Web3 wallet authentication using message signing.
  Prevents replay attacks via nonces.
  """

  @doc """
  Generate a random nonce for signature verification.

  ## Examples

      iex> nonce = Droodotfoo.Web3.Auth.generate_nonce()
      iex> String.length(nonce)
      32

  """
  @spec generate_nonce() :: String.t()
  def generate_nonce do
    :crypto.strong_rand_bytes(16)
    |> Base.encode16(case: :lower)
  end

  @doc """
  Format the authentication message to be signed by the wallet.

  The message includes:
  - Welcome message
  - Wallet address being authenticated
  - Unique nonce to prevent replay attacks
  - Disclaimer about no blockchain transaction

  ## Examples

      iex> address = "0x1234567890abcdef1234567890abcdef12345678"
      iex> nonce = "abc123"
      iex> message = Droodotfoo.Web3.Auth.format_auth_message(address, nonce)
      iex> String.contains?(message, address)
      true

  """
  @spec format_auth_message(String.t(), String.t()) :: String.t()
  def format_auth_message(address, nonce) do
    """
    Welcome to droo.foo!

    Sign this message to authenticate your wallet:
    #{address}

    Nonce: #{nonce}

    This request will not trigger a blockchain transaction or cost any gas fees.
    """
  end

  @doc """
  Verify the signature and recover the signing address.

  Uses ECDSA signature recovery to extract the address that signed
  the message, then compares it to the claimed address.

  ## Parameters

  - `address`: The claimed wallet address (0x-prefixed hex string)
  - `nonce`: The nonce included in the signed message
  - `signature`: The signature produced by the wallet (0x-prefixed hex string)

  ## Returns

  - `{:ok, recovered_address}` if signature is valid and matches
  - `{:error, :address_mismatch}` if signature is valid but doesn't match claimed address
  - `{:error, reason}` for other failures

  ## Examples

      iex> # With valid signature
      iex> {:ok, address} = Droodotfoo.Web3.Auth.verify_signature(
      ...>   "0x1234...",
      ...>   "abc123",
      ...>   "0x5678..."
      ...> )

  """
  @spec verify_signature(String.t(), String.t(), String.t()) ::
          {:ok, String.t()} | {:error, atom() | String.t()}
  def verify_signature(address, nonce, signature) do
    message = format_auth_message(address, nonce)

    case recover_address(message, signature) do
      {:ok, recovered_address} ->
        normalized_claimed = normalize_address(address)
        normalized_recovered = normalize_address(recovered_address)

        if normalized_claimed == normalized_recovered do
          {:ok, recovered_address}
        else
          {:error, :address_mismatch}
        end

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Recover the Ethereum address from a signed message.

  Uses ExSecp256k1 for ECDSA signature recovery following Ethereum's
  personal_sign standard (prefixes message with "\\x19Ethereum Signed Message:\\n").

  ## Parameters

  - `message`: The original message that was signed
  - `signature`: The signature (0x-prefixed hex string, 65 bytes)

  ## Returns

  - `{:ok, address}` with the recovered Ethereum address
  - `{:error, reason}` if recovery fails

  """
  @spec recover_address(String.t(), String.t()) ::
          {:ok, String.t()} | {:error, atom() | String.t()}
  def recover_address(message, signature) do
    # Remove 0x prefix if present
    clean_signature = String.replace_prefix(signature, "0x", "")

    # Decode signature (should be 65 bytes: r[32] + s[32] + v[1])
    with {:ok, sig_bytes} <- Base.decode16(clean_signature, case: :mixed),
         true <- byte_size(sig_bytes) == 65 do
        # Split signature into r, s, v components
        <<r::binary-size(32), s::binary-size(32), v::integer-8>> = sig_bytes

        # Ethereum uses recovery id (v) of 27 or 28, need to subtract 27 for recovery
        recovery_id = if v >= 27, do: v - 27, else: v

        # Hash the message using Ethereum's personal_sign format
        message_hash = ethereum_message_hash(message)

        # Recover public key using secp256k1
        case ExSecp256k1.recover_compact(message_hash, r <> s, recovery_id) do
          {:ok, public_key} ->
            # Public key is 65 bytes (0x04 prefix + 64 bytes), we need the last 64 bytes
            <<_prefix::8, key::binary-size(64)>> = public_key

            # Ethereum address is last 20 bytes of keccak256 hash of public key
            address_bytes =
              ExKeccak.hash_256(key)
              |> binary_part(12, 20)

            # Format as 0x-prefixed hex string
            address = "0x" <> Base.encode16(address_bytes, case: :lower)
            {:ok, address}

          {:error, reason} ->
            {:error, reason}
        end
    else
      false -> {:error, :invalid_signature_length}
      {:error, reason} -> {:error, reason}
    end
  rescue
    error -> {:error, error}
  end

  @doc """
  Hash a message using Ethereum's personal_sign format.

  Prefixes the message with "\\x19Ethereum Signed Message:\\n" followed
  by the message length, then hashes with Keccak256.

  This matches the behavior of web3.eth.personal.sign and ethers.signMessage.

  """
  @spec ethereum_message_hash(String.t()) :: binary()
  def ethereum_message_hash(message) do
    prefix = "\x19Ethereum Signed Message:\n"
    message_length = byte_size(message) |> Integer.to_string()
    full_message = prefix <> message_length <> message

    ExKeccak.hash_256(full_message)
  end

  @doc """
  Normalize an Ethereum address to lowercase without 0x prefix.

  ## Examples

      iex> Droodotfoo.Web3.Auth.normalize_address("0xABCD1234")
      "abcd1234"

      iex> Droodotfoo.Web3.Auth.normalize_address("ABCD1234")
      "abcd1234"

  """
  @spec normalize_address(String.t()) :: String.t()
  def normalize_address(address) do
    address
    |> String.replace_prefix("0x", "")
    |> String.downcase()
  end

  @doc """
  Validate an Ethereum address format.

  Checks that the address:
  - Is a hex string
  - Has correct length (40 characters without 0x prefix, or 42 with)

  Returns `{:ok, normalized_address}` or `{:error, reason}`.

  ## Examples

      iex> Droodotfoo.Web3.Auth.validate_address("0x1234567890abcdef1234567890abcdef12345678")
      {:ok, "0x1234567890abcdef1234567890abcdef12345678"}

      iex> Droodotfoo.Web3.Auth.validate_address("invalid")
      {:error, :invalid_format}

  """
  @spec validate_address(String.t()) :: {:ok, String.t()} | {:error, atom()}
  def validate_address(address) when is_binary(address) do
    clean = String.replace_prefix(address, "0x", "")

    cond do
      String.length(clean) != 40 ->
        {:error, :invalid_length}

      not String.match?(clean, ~r/^[0-9a-fA-F]{40}$/) ->
        {:error, :invalid_format}

      true ->
        {:ok, "0x" <> String.downcase(clean)}
    end
  end

  def validate_address(_), do: {:error, :invalid_type}
end
