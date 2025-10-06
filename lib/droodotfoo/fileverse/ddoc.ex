defmodule Droodotfoo.Fileverse.DDoc do
  @moduledoc """
  Fileverse dDocs integration for encrypted collaborative documents.

  Provides terminal interface for creating, editing, and managing
  decentralized documents with end-to-end encryption.

  Note: Full implementation requires @fileverse-dev/ddoc React SDK
  and LiveView hooks for React component integration.
  """

  require Logger

  alias Droodotfoo.Fileverse.Encryption

  @type document :: %{
          id: String.t(),
          title: String.t(),
          content: String.t() | map(),
          author: String.t(),
          collaborators: [String.t()],
          encrypted: boolean(),
          created_at: DateTime.t(),
          updated_at: DateTime.t(),
          ipfs_cid: String.t() | nil,
          encryption_metadata: map() | nil
        }

  @doc """
  Create a new dDoc.

  ## Parameters

  - `title`: Document title
  - `opts`: Keyword list of options
    - `:wallet_address` - Creator's wallet address
    - `:encrypted` - Enable encryption (default: true)
    - `:collaborators` - List of wallet addresses with access
    - `:content` - Initial content (default: "")
    - `:encryption_keys` - Encryption keys for E2E encryption

  ## Examples

      iex> Droodotfoo.Fileverse.DDoc.create("My Doc", wallet_address: "0x...")
      {:ok, %{id: "doc_123", title: "My Doc", ...}}

  """
  @spec create(String.t(), keyword()) :: {:ok, document()} | {:error, atom()}
  def create(title, opts \\ []) do
    wallet_address = Keyword.get(opts, :wallet_address)
    encrypted = Keyword.get(opts, :encrypted, true)
    collaborators = Keyword.get(opts, :collaborators, [])
    content = Keyword.get(opts, :content, "")
    encryption_keys = Keyword.get(opts, :encryption_keys)

    if not wallet_address do
      {:error, :wallet_required}
    else
      # Encrypt content if keys provided
      {final_content, encryption_metadata} =
        if encrypted and encryption_keys do
          case Encryption.encrypt_document(content, encryption_keys) do
            {:ok, encrypted_data} ->
              {encrypted_data, %{
                algorithm: encrypted_data.algorithm,
                key_id: encrypted_data.key_id,
                encrypted_at: encrypted_data.encrypted_at
              }}

            {:error, _reason} ->
              Logger.warn("Failed to encrypt document, storing plaintext")
              {content, nil}
          end
        else
          {content, nil}
        end

      doc = %{
        id: "ddoc_" <> generate_id(),
        title: title,
        content: final_content,
        author: wallet_address,
        collaborators: collaborators,
        encrypted: encrypted and encryption_metadata != nil,
        created_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        ipfs_cid: nil,
        encryption_metadata: encryption_metadata
      }

      {:ok, doc}
    end
  end

  @doc """
  List documents for a wallet address.

  ## Examples

      iex> Droodotfoo.Fileverse.DDoc.list("0x...")
      {:ok, [%{id: "doc_123", title: "My Doc", ...}]}

  """
  @spec list(String.t()) :: {:ok, [document()]} | {:error, atom()}
  def list(wallet_address) do
    if not wallet_address do
      {:error, :wallet_required}
    else
      # Mock implementation
      # Production would fetch from Fileverse
      docs = [
        %{
          id: "ddoc_001",
          title: "Meeting Notes - Q4 2025",
          content: "# Q4 Planning\n\n- Goals\n- Milestones",
          author: wallet_address,
          collaborators: [],
          encrypted: true,
          created_at: DateTime.utc_now() |> DateTime.add(-86400, :second),
          updated_at: DateTime.utc_now() |> DateTime.add(-3600, :second),
          ipfs_cid: "QmExample123"
        },
        %{
          id: "ddoc_002",
          title: "Project Roadmap",
          content: "# Roadmap\n\nPhase 1: Research\nPhase 2: Development",
          author: wallet_address,
          collaborators: ["0x1234..."],
          encrypted: true,
          created_at: DateTime.utc_now() |> DateTime.add(-172800, :second),
          updated_at: DateTime.utc_now(),
          ipfs_cid: "QmExample456"
        }
      ]

      {:ok, docs}
    end
  end

  @doc """
  Get a document by ID.

  ## Parameters

  - `doc_id`: Document ID
  - `wallet_address`: Wallet address for access control
  - `opts`: Keyword list of options
    - `:encryption_keys` - Keys to decrypt if document is encrypted

  ## Examples

      iex> Droodotfoo.Fileverse.DDoc.get("doc_123", "0x...")
      {:ok, %{id: "doc_123", title: "My Doc", ...}}

  """
  @spec get(String.t(), String.t(), keyword()) :: {:ok, document()} | {:error, atom()}
  def get(doc_id, wallet_address, opts \\ []) do
    if not wallet_address do
      {:error, :wallet_required}
    else
      encryption_keys = Keyword.get(opts, :encryption_keys)

      # Mock implementation
      # Production would fetch from Fileverse and decrypt if needed
      case String.starts_with?(doc_id, "ddoc_") do
        true ->
          content =
            "# Sample dDoc\n\nThis is a decentralized document stored on IPFS.\n\nFeatures:\n- End-to-end encryption\n- Real-time collaboration\n- Version history\n- Offline editing"

          # Mock encrypted content
          encrypted_metadata = %{
            algorithm: "AES-256-GCM",
            key_id: "mock_key_id",
            encrypted_at: DateTime.utc_now()
          }

          doc = %{
            id: doc_id,
            title: "Sample Document",
            content: content,
            author: wallet_address,
            collaborators: [],
            encrypted: true,
            created_at: DateTime.utc_now() |> DateTime.add(-86400, :second),
            updated_at: DateTime.utc_now(),
            ipfs_cid: "QmSample789",
            encryption_metadata: encrypted_metadata
          }

          # Decrypt if keys provided (for real encrypted documents)
          final_doc =
            if encryption_keys and is_map(doc.content) do
              case Encryption.decrypt_document(doc.content, encryption_keys) do
                {:ok, plaintext} ->
                  %{doc | content: plaintext}

                {:error, _reason} ->
                  Logger.warn("Failed to decrypt document #{doc_id}")
                  %{doc | content: "[ENCRYPTED - Unable to decrypt]"}
              end
            else
              doc
            end

          {:ok, final_doc}

        false ->
          {:error, :not_found}
      end
    end
  end

  @doc """
  Delete a document.

  ## Examples

      iex> Droodotfoo.Fileverse.DDoc.delete("doc_123", "0x...")
      {:ok, "Document deleted"}

  """
  @spec delete(String.t(), String.t()) :: {:ok, String.t()} | {:error, atom()}
  def delete(doc_id, wallet_address) do
    if not wallet_address do
      {:error, :wallet_required}
    else
      # Mock implementation
      # Production would call Fileverse API
      {:ok, "Document #{doc_id} deleted"}
    end
  end

  @doc """
  Share a document with collaborators.

  ## Examples

      iex> Droodotfoo.Fileverse.DDoc.share("doc_123", ["0x1234...", "0x5678..."], "0x...")
      {:ok, "Document shared with 2 collaborators"}

  """
  @spec share(String.t(), [String.t()], String.t()) :: {:ok, String.t()} | {:error, atom()}
  def share(doc_id, collaborator_addresses, wallet_address) do
    if not wallet_address do
      {:error, :wallet_required}
    else
      # Mock implementation
      # Production would update access control on Fileverse
      count = length(collaborator_addresses)
      {:ok, "Document #{doc_id} shared with #{count} collaborator(s)"}
    end
  end

  @doc """
  Format document metadata for terminal display.
  """
  @spec format_doc_info(document()) :: String.t()
  def format_doc_info(doc) do
    created = Calendar.strftime(doc.created_at, "%Y-%m-%d %H:%M UTC")
    updated = Calendar.strftime(doc.updated_at, "%Y-%m-%d %H:%M UTC")

    encrypted_status =
      if doc.encrypted do
        metadata = doc.encryption_metadata

        if metadata do
          "YES - [E2E] #{metadata.algorithm}"
        else
          "YES (E2E)"
        end
      else
        "NO"
      end

    ipfs_status = if doc.ipfs_cid, do: doc.ipfs_cid, else: "Not published"

    encryption_info =
      if doc.encrypted and doc.encryption_metadata do
        """

        Encryption Details:
          Algorithm:   #{doc.encryption_metadata.algorithm}
          Key ID:      #{doc.encryption_metadata.key_id}
          Encrypted:   #{Calendar.strftime(doc.encryption_metadata.encrypted_at, "%Y-%m-%d %H:%M UTC")}
        """
      else
        ""
      end

    """
    Document: #{doc.title}
    #{String.duplicate("=", 78)}

    ID:            #{doc.id}
    Author:        #{shorten_address(doc.author)}
    Created:       #{created}
    Last Updated:  #{updated}
    Encrypted:     #{encrypted_status}
    IPFS CID:      #{ipfs_status}
    Collaborators: #{length(doc.collaborators)}#{encryption_info}
    """
  end

  @doc """
  Format document list for terminal display.
  """
  @spec format_doc_list([document()]) :: String.t()
  def format_doc_list(docs) when is_list(docs) do
    if Enum.empty?(docs) do
      "No documents found."
    else
      header = String.pad_trailing("ID", 15) <> String.pad_trailing("Title", 35) <> "Updated"

      rows =
        Enum.map(docs, fn doc ->
          id = String.pad_trailing(doc.id, 15)
          title = String.pad_trailing(truncate(doc.title, 32), 35)
          updated = relative_time(doc.updated_at)
          "#{id}#{title}#{updated}"
        end)

      Enum.join([header, String.duplicate("-", 78) | rows], "\n")
    end
  end

  ## Private Functions

  defp generate_id do
    8
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end

  defp shorten_address(address) when is_binary(address) and byte_size(address) > 10 do
    prefix = String.slice(address, 0..5)
    suffix = String.slice(address, -4..-1//1)
    "#{prefix}...#{suffix}"
  end

  defp shorten_address(address), do: address

  defp truncate(string, max_length) when byte_size(string) > max_length do
    String.slice(string, 0, max_length - 3) <> "..."
  end

  defp truncate(string, _max_length), do: string

  defp relative_time(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "#{diff}s ago"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      diff < 604800 -> "#{div(diff, 86400)}d ago"
      true -> Calendar.strftime(datetime, "%Y-%m-%d")
    end
  end
end
