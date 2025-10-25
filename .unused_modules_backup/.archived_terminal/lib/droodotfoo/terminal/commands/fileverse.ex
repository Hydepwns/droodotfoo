defmodule Droodotfoo.Terminal.Commands.Fileverse do
  @moduledoc """
  Fileverse integration commands for the terminal.

  Provides commands for:
  - IPFS: ipfs cat, ipfs gateway, ipfs ls
  - dDocs: ddoc list, ddoc new, ddoc view, docs
  - Storage: upload, files, file info, file versions
  - Portal: portal create/join/share/leave/peers/status
  - Encryption: encrypt, decrypt
  - dSheets: sheet list/new/open/query/export/sort, sheets
  - HeartBit: like, likes, activity
  """

  use Droodotfoo.Terminal.CommandBase

  alias Droodotfoo.Web3.IPFS
  alias Droodotfoo.Fileverse.{DDoc, DSheet, Encryption, Portal, Storage}

  @impl true
  def execute("ipfs", args, state), do: ipfs(args, state)
  def execute("ddoc", args, state), do: ddoc(args, state)
  def execute("docs", args, state), do: docs(args, state)
  def execute("upload", args, state), do: upload(args, state)
  def execute("files", args, state), do: files(args, state)
  def execute("file", args, state), do: file(args, state)
  def execute("portal", args, state), do: portal(args, state)
  def execute("encrypt", args, state), do: encrypt(args, state)
  def execute("decrypt", args, state), do: decrypt(args, state)
  def execute("sheet", args, state), do: sheet(args, state)
  def execute("sheets", args, state), do: sheets(args, state)

  def execute(command, _args, state) do
    {:error, "Unknown Fileverse command: #{command}", state}
  end

  # IPFS Commands

  @doc """
  IPFS content commands - fetch and display IPFS content.
  """
  def ipfs([], _state) do
    {:error,
     "Usage:\n  ipfs cat <cid>    - Fetch and display IPFS content\n  ipfs gateway <cid> - Show gateway URLs"}
  end

  def ipfs(["cat", cid], _state) do
    case IPFS.cat(cid) do
      {:ok, content} ->
        formatted = IPFS.format_content(content, max_lines: 100)

        output = """
        IPFS Content
        #{String.duplicate("=", 78)}

        CID:          #{content.cid}
        Content-Type: #{content.content_type}
        Size:         #{format_content_size(content.size)}
        Gateway:      #{String.replace(content.gateway, "https://", "")}

        #{String.duplicate("-", 78)}

        #{formatted}
        """

        {:ok, output}

      {:error, :invalid_cid} ->
        {:error, "Invalid IPFS CID format"}

      {:error, :not_found} ->
        {:error, "Content not found on IPFS"}

      {:error, :content_too_large} ->
        {:error, "Content too large to display (>10MB)"}

      {:error, :all_gateways_failed} ->
        {:error, "Failed to fetch from all IPFS gateways"}

      {:error, reason} ->
        {:error, "Failed to fetch IPFS content: #{reason}"}
    end
  end

  def ipfs(["gateway", cid], _state) do
    if IPFS.valid_cid?(cid) do
      output = """
      IPFS Gateway URLs
      #{String.duplicate("=", 78)}

      CID: #{cid}

      Available Gateways:
      - https://cloudflare-ipfs.com/ipfs/#{cid}
      - https://ipfs.io/ipfs/#{cid}
      - https://gateway.pinata.cloud/ipfs/#{cid}
      - https://dweb.link/ipfs/#{cid}

      Copy any URL to access the content in your browser.
      """

      {:ok, output}
    else
      {:error, "Invalid IPFS CID format"}
    end
  end

  def ipfs([subcommand | _], _state) do
    {:error,
     "Unknown ipfs subcommand: #{subcommand}\n\nUsage:\n  ipfs cat <cid>     - Fetch and display content\n  ipfs gateway <cid> - Show gateway URLs"}
  end

  # dDocs Commands

  @doc """
  Fileverse dDocs - encrypted document management.
  """
  def ddoc([], state) do
    wallet = get_wallet_address(state)

    if wallet do
      {:error,
       "Usage:\n  ddoc list          - List your documents\n  ddoc new <title>   - Create new document\n  ddoc view <id>     - View document\n  ddoc delete <id>   - Delete document"}
    else
      {:error, "Please connect your wallet first using: web3 connect"}
    end
  end

  def ddoc(["list"], state) do
    wallet = get_wallet_address(state)

    if wallet do
      case DDoc.list(wallet) do
        {:ok, docs} ->
          output = """
          Fileverse dDocs - Encrypted Documents
          #{String.duplicate("=", 78)}

          #{DDoc.format_doc_list(docs)}

          Note: Full dDocs integration requires @fileverse-dev/ddoc React SDK
          """

          {:ok, output}

        {:error, reason} ->
          {:error, "Failed to list documents: #{reason}"}
      end
    else
      {:error, "Please connect your wallet first"}
    end
  end

  def ddoc(["new", title], state) do
    wallet = get_wallet_address(state)

    if wallet do
      case DDoc.create(title, wallet_address: wallet) do
        {:ok, doc} ->
          {:ok, "Created document: #{doc.id}\nTitle: #{doc.title}\nEncrypted: YES"}

        {:error, :wallet_required} ->
          {:error, "Wallet connection required"}

        {:error, reason} ->
          {:error, "Failed to create document: #{reason}"}
      end
    else
      {:error, "Please connect your wallet first"}
    end
  end

  def ddoc(["view", doc_id], state) do
    wallet = get_wallet_address(state)

    if wallet do
      opts = if state.encryption_keys, do: [encryption_keys: state.encryption_keys], else: []

      case DDoc.get(doc_id, wallet, opts) do
        {:ok, doc} ->
          {:ok,
           DDoc.format_doc_info(doc) <>
             "\n#{String.duplicate("-", 78)}\n\n#{doc.content}"}

        {:error, :not_found} ->
          {:error, "Document not found: #{doc_id}"}

        {:error, reason} ->
          {:error, "Failed to load document: #{reason}"}
      end
    else
      {:error, "Please connect your wallet first"}
    end
  end

  def ddoc([subcommand | _], _state) do
    {:error, "Unknown ddoc subcommand: #{subcommand}"}
  end

  def docs(_args, state), do: ddoc(["list"], state)

  # Storage Commands

  @doc """
  File upload and storage management.
  """
  def upload([file_path | _rest], state) do
    wallet = get_wallet_address(state)

    if wallet do
      case Storage.upload(file_path, wallet_address: wallet) do
        {:ok, metadata} ->
          output = """
          File Upload Successful
          #{String.duplicate("=", 78)}

          #{Storage.format_file_info(metadata)}

          Note: Full upload implementation requires Fileverse Storage API
          """

          {:ok, output}

        {:error, :wallet_required} ->
          {:error, "Please connect your wallet first with :web3 connect"}

        {:error, reason} ->
          {:error, "Upload failed: #{inspect(reason)}"}
      end
    else
      {:error, "Please connect your wallet first with :web3 connect"}
    end
  end

  def upload([], _state) do
    {:error, "Usage: :upload <file_path>"}
  end

  def files(_args, state) do
    wallet = get_wallet_address(state)

    if wallet do
      case Storage.list_files(wallet) do
        {:ok, file_list} ->
          output = """
          Fileverse Storage - My Files
          #{String.duplicate("=", 78)}

          #{Storage.format_file_list(file_list)}

          Use ':file info <cid>' to view file details
          Use ':file versions <cid>' to see version history

          Note: Full storage integration requires Fileverse Storage API
          """

          {:ok, output}

        {:error, :wallet_required} ->
          {:error, "Please connect your wallet first with :web3 connect"}

        {:error, reason} ->
          {:error, "Failed to list files: #{inspect(reason)}"}
      end
    else
      {:error, "Please connect your wallet first with :web3 connect"}
    end
  end

  def file(["info", cid], state) do
    wallet = get_wallet_address(state)

    if wallet do
      case Storage.get_file(cid, wallet) do
        {:ok, metadata} ->
          output = """
          #{Storage.format_file_info(metadata)}

          Note: Full storage integration requires Fileverse Storage API
          """

          {:ok, output}

        {:error, :not_found} ->
          {:error, "File not found: #{cid}"}

        {:error, reason} ->
          {:error, "Failed to get file info: #{inspect(reason)}"}
      end
    else
      {:error, "Please connect your wallet first with :web3 connect"}
    end
  end

  def file([], _state) do
    {:error, "Usage: :file info <cid> or :file versions <cid>"}
  end

  def file(_args, _state) do
    {:error, "Usage: :file info <cid> or :file versions <cid>"}
  end

  # Encryption Commands

  @doc """
  Encrypt and decrypt content with wallet.
  """
  def encrypt([], _state) do
    {:error, "Usage: encrypt <doc_id>"}
  end

  def encrypt([doc_id], state) do
    wallet = get_wallet_address(state)

    if wallet do
      case Encryption.encrypt_document(doc_id, wallet) do
        {:ok, encrypted} ->
          {:ok, "Document encrypted: #{encrypted.id}"}

        {:error, reason} ->
          {:error, "Encryption failed: #{reason}"}
      end
    else
      {:error, "Please connect your wallet first"}
    end
  end

  def encrypt(_args, _state) do
    {:error, "Usage: encrypt <doc_id>"}
  end

  def decrypt([], _state) do
    {:error, "Usage: decrypt <doc_id>"}
  end

  def decrypt([doc_id], state) do
    wallet = get_wallet_address(state)

    if wallet do
      case Encryption.decrypt_document(doc_id, wallet) do
        {:ok, decrypted} ->
          {:ok, "Document decrypted:\n\n#{decrypted.content}"}

        {:error, reason} ->
          {:error, "Decryption failed: #{reason}"}
      end
    else
      {:error, "Please connect your wallet first"}
    end
  end

  def decrypt(_args, _state) do
    {:error, "Usage: decrypt <doc_id>"}
  end

  # Portal Commands

  @doc """
  P2P collaboration portals with WebRTC.
  """
  def portal([], _state) do
    {:error,
     "Usage:\n  portal list                - List your portals\n  portal create <name>       - Create new portal\n  portal join <id>           - Join existing portal"}
  end

  def portal(["list"], state) do
    if state.web3_wallet_connected do
      wallet = state.web3_wallet_address

      case Portal.list(wallet) do
        {:ok, portals} ->
          output = """
          Fileverse Portals - P2P Collaboration Spaces
          =============================================

          #{Portal.format_portal_list(portals)}

          Commands:
            :portal create <name>     - Create new portal
            :portal join <id>         - Join portal
            :portal peers <id>        - View members

          Note: Full Portal integration requires Fileverse Portal SDK and WebRTC
          """

          {:ok, output, state}

        {:error, reason} ->
          {:error, "Failed to list portals: #{inspect(reason)}"}
      end
    else
      {:error, "Web3 wallet not connected. Run: :web3 connect"}
    end
  end

  def portal(_args, _state) do
    {:error, "Invalid portal command"}
  end

  # dSheets Commands

  @doc """
  Onchain data visualization with dSheets.
  """
  def sheet([], _state) do
    {:error,
     "Usage:\n  sheet list          - List your sheets\n  sheet new <name>    - Create new sheet\n  sheet open <id>     - Open sheet"}
  end

  def sheet(["list"], state) do
    wallet = get_wallet_address(state)

    if wallet do
      case DSheet.list(wallet) do
        {:ok, sheets} ->
          {:ok, "dSheets: #{length(sheets)} sheets found"}

        {:error, reason} ->
          {:error, "Failed to list sheets: #{reason}"}
      end
    else
      {:error, "Please connect your wallet first"}
    end
  end

  def sheet([subcommand | _], _state) do
    {:error, "Unknown sheet subcommand: #{subcommand}"}
  end

  def sheets(_args, state), do: sheet(["list"], state)

  # Helper Functions

  @doc false
  defp get_wallet_address(%{web3_wallet_address: address}) when is_binary(address),
    do: address

  defp get_wallet_address(%{web3_wallet: %{address: address}}) when is_binary(address),
    do: address

  defp get_wallet_address(_), do: nil

  @doc false
  defp format_content_size(bytes) when bytes < 1024, do: "#{bytes} bytes"
  defp format_content_size(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 2)} KB"

  defp format_content_size(bytes) when bytes < 1_073_741_824,
    do: "#{Float.round(bytes / 1_048_576, 2)} MB"

  defp format_content_size(bytes), do: "#{Float.round(bytes / 1_073_741_824, 2)} GB"
end
