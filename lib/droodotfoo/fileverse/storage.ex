defmodule Droodotfoo.Fileverse.Storage do
  @moduledoc """
  Fileverse Storage integration for decentralized file uploads.

  Provides terminal interface for uploading files to IPFS via Fileverse
  infrastructure with UCAN-based authentication.

  Note: Full implementation requires Fileverse Storage API
  and UCAN token generation.
  """

  require Logger

  @type file_metadata :: %{
          cid: String.t(),
          filename: String.t(),
          size: integer(),
          content_type: String.t(),
          uploader: String.t(),
          uploaded_at: DateTime.t(),
          version: integer(),
          versions: [String.t()],
          storage_cost: float() | nil
        }

  @type upload_progress :: %{
          filename: String.t(),
          bytes_uploaded: integer(),
          total_bytes: integer(),
          percent: float(),
          status: :uploading | :pinning | :complete | :error
        }

  @doc """
  Upload a file to IPFS via Fileverse Storage.

  ## Parameters

  - `file_path`: Local file path to upload
  - `opts`: Keyword list of options
    - `:wallet_address` - Uploader's wallet address
    - `:filename` - Override filename (default: basename of file_path)
    - `:encrypt` - Enable encryption (default: true)
    - `:progress_callback` - Function to receive upload progress updates

  ## Examples

      iex> Droodotfoo.Fileverse.Storage.upload("/path/to/file.pdf", wallet_address: "0x...")
      {:ok, %{cid: "Qm...", filename: "file.pdf", ...}}

  """
  @spec upload(String.t(), keyword()) :: {:ok, file_metadata()} | {:error, atom()}
  def upload(file_path, opts \\ []) do
    wallet_address = Keyword.get(opts, :wallet_address)
    filename = Keyword.get(opts, :filename, Path.basename(file_path))
    _encrypt = Keyword.get(opts, :encrypt, true)

    if wallet_address do
      # Mock implementation
      # Production would:
      # 1. Generate UCAN token for authentication
      # 2. Read file contents
      # 3. Optionally encrypt with wallet key
      # 4. Upload to Fileverse Storage API
      # 5. Pin to IPFS
      # 6. Return IPFS CID and metadata

      # Simulate file info
      case File.stat(file_path) do
        {:ok, stat} ->
          metadata = %{
            cid: "Qm" <> generate_cid(),
            filename: filename,
            size: stat.size,
            content_type: guess_content_type(filename),
            uploader: wallet_address,
            uploaded_at: DateTime.utc_now(),
            version: 1,
            versions: [],
            storage_cost: calculate_storage_cost(stat.size)
          }

          {:ok, metadata}

        {:error, _} ->
          # For demo purposes, return mock data even if file doesn't exist
          metadata = %{
            cid: "Qm" <> generate_cid(),
            filename: filename,
            size: 1024 * 256,
            content_type: guess_content_type(filename),
            uploader: wallet_address,
            uploaded_at: DateTime.utc_now(),
            version: 1,
            versions: [],
            storage_cost: calculate_storage_cost(1024 * 256)
          }

          {:ok, metadata}
      end
    else
      {:error, :wallet_required}
    end
  end

  @doc """
  List uploaded files for a wallet address.

  ## Examples

      iex> Droodotfoo.Fileverse.Storage.list_files("0x...")
      {:ok, [%{cid: "Qm...", filename: "document.pdf", ...}]}

  """
  @spec list_files(String.t()) :: {:ok, [file_metadata()]} | {:error, atom()}
  def list_files(wallet_address) do
    if wallet_address do
      # Mock implementation
      # Production would fetch from Fileverse API
      files = [
        %{
          cid: "QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG",
          filename: "whitepaper.pdf",
          size: 2_457_600,
          content_type: "application/pdf",
          uploader: wallet_address,
          uploaded_at: DateTime.utc_now() |> DateTime.add(-172_800, :second),
          version: 2,
          versions: ["QmOldVersion1", "QmOldVersion2"],
          storage_cost: 0.0024
        },
        %{
          cid: "QmT4AeWE9Q9b1yZ6848xNgYpJYZ62QjxKbZsFUyP1Bz6gH",
          filename: "screenshot.png",
          size: 524_288,
          content_type: "image/png",
          uploader: wallet_address,
          uploaded_at: DateTime.utc_now() |> DateTime.add(-86_400, :second),
          version: 1,
          versions: [],
          storage_cost: 0.0005
        },
        %{
          cid: "QmRN4Ke4Thqy6xvfDzXqWy8yD8H8z9QHKD8qN1Yx2QqMo",
          filename: "data.json",
          size: 8192,
          content_type: "application/json",
          uploader: wallet_address,
          uploaded_at: DateTime.utc_now() |> DateTime.add(-3600, :second),
          version: 1,
          versions: [],
          storage_cost: 0.00001
        }
      ]

      {:ok, files}
    else
      {:error, :wallet_required}
    end
  end

  @doc """
  Get file metadata by CID.

  ## Examples

      iex> Droodotfoo.Fileverse.Storage.get_file("Qm...")
      {:ok, %{cid: "Qm...", filename: "file.pdf", ...}}

  """
  @spec get_file(String.t(), String.t()) :: {:ok, file_metadata()} | {:error, atom()}
  def get_file(cid, wallet_address) do
    if wallet_address do
      # Mock implementation
      # Production would fetch from Fileverse API
      if String.starts_with?(cid, "Qm") or String.starts_with?(cid, "bafy") do
        metadata = %{
          cid: cid,
          filename: "example-file.txt",
          size: 4096,
          content_type: "text/plain",
          uploader: wallet_address,
          uploaded_at: DateTime.utc_now() |> DateTime.add(-86_400, :second),
          version: 1,
          versions: [],
          storage_cost: 0.00001
        }

        {:ok, metadata}
      else
        {:error, :not_found}
      end
    else
      {:error, :wallet_required}
    end
  end

  @doc """
  Get all versions of a file.

  ## Examples

      iex> Droodotfoo.Fileverse.Storage.get_versions("Qm...")
      {:ok, [%{version: 2, cid: "Qm...", uploaded_at: ~U[...]}, ...]}

  """
  @spec get_versions(String.t()) :: {:ok, [map()]} | {:error, atom()}
  def get_versions(cid) do
    # Mock implementation
    # Production would fetch version history from Fileverse
    versions = [
      %{
        version: 2,
        cid: cid,
        uploaded_at: DateTime.utc_now(),
        size: 4096,
        notes: "Updated content"
      },
      %{
        version: 1,
        cid: "QmOlderVersion123",
        uploaded_at: DateTime.utc_now() |> DateTime.add(-86_400, :second),
        size: 3072,
        notes: "Initial upload"
      }
    ]

    {:ok, versions}
  end

  @doc """
  Delete a file from storage.

  ## Examples

      iex> Droodotfoo.Fileverse.Storage.delete("Qm...", "0x...")
      {:ok, "File deleted"}

  """
  @spec delete(String.t(), String.t()) :: {:ok, String.t()} | {:error, atom()}
  def delete(cid, wallet_address) do
    if wallet_address do
      # Mock implementation
      # Production would call Fileverse API
      {:ok, "File #{cid} deleted from storage"}
    else
      {:error, :wallet_required}
    end
  end

  @doc """
  Format file list for terminal display.
  """
  @spec format_file_list([file_metadata()]) :: String.t()
  def format_file_list(files) when is_list(files) do
    if Enum.empty?(files) do
      "No files found."
    else
      header =
        String.pad_trailing("Filename", 30) <>
          String.pad_trailing("Size", 12) <>
          String.pad_trailing("Type", 15) <>
          "Uploaded"

      rows =
        Enum.map(files, fn file ->
          filename = String.pad_trailing(truncate(file.filename, 27), 30)
          size = String.pad_trailing(format_bytes(file.size), 12)
          content_type = String.pad_trailing(truncate(file.content_type, 12), 15)
          uploaded = relative_time(file.uploaded_at)
          "#{filename}#{size}#{content_type}#{uploaded}"
        end)

      Enum.join([header, String.duplicate("-", 78) | rows], "\n")
    end
  end

  @doc """
  Format file metadata for terminal display.
  """
  @spec format_file_info(file_metadata()) :: String.t()
  def format_file_info(file) do
    uploaded = Calendar.strftime(file.uploaded_at, "%Y-%m-%d %H:%M UTC")
    cost = if file.storage_cost, do: "$#{file.storage_cost} USD/month", else: "Free tier"

    versions_info =
      if file.version > 1 do
        "Version #{file.version} (#{length(file.versions)} previous versions)"
      else
        "Version 1 (no previous versions)"
      end

    """
    File Metadata
    #{String.duplicate("=", 78)}

    Filename:      #{file.filename}
    IPFS CID:      #{file.cid}
    Size:          #{format_bytes(file.size)}
    Content-Type:  #{file.content_type}
    Uploader:      #{shorten_address(file.uploader)}
    Uploaded:      #{uploaded}
    #{versions_info}
    Storage Cost:  #{cost}

    Gateway URL:   https://cloudflare-ipfs.com/ipfs/#{file.cid}
    """
  end

  @doc """
  Generate ASCII progress bar for upload.
  """
  @spec format_progress(upload_progress()) :: String.t()
  def format_progress(progress) do
    bar_width = 40
    filled = round(progress.percent * bar_width / 100)
    empty = bar_width - filled

    bar = String.duplicate("█", filled) <> String.duplicate("░", empty)

    status_text =
      case progress.status do
        :uploading -> "Uploading"
        :pinning -> "Pinning to IPFS"
        :complete -> "Complete"
        :error -> "Error"
      end

    """
    #{progress.filename}
    [#{bar}] #{Float.round(progress.percent, 1)}%
    #{format_bytes(progress.bytes_uploaded)} / #{format_bytes(progress.total_bytes)} - #{status_text}
    """
  end

  ## Private Functions

  defp generate_cid do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end

  defp guess_content_type(filename) do
    filename
    |> Path.extname()
    |> String.downcase()
    |> content_type_from_extension()
  end

  defp content_type_from_extension(ext) do
    content_type_map()[ext] || "application/octet-stream"
  end

  defp content_type_map do
    %{
      ".pdf" => "application/pdf",
      ".png" => "image/png",
      ".jpg" => "image/jpeg",
      ".jpeg" => "image/jpeg",
      ".gif" => "image/gif",
      ".json" => "application/json",
      ".txt" => "text/plain",
      ".md" => "text/markdown",
      ".html" => "text/html",
      ".css" => "text/css",
      ".js" => "application/javascript",
      ".zip" => "application/zip"
    }
  end

  defp calculate_storage_cost(size_bytes) do
    # Mock storage cost calculation
    # Fileverse pricing: ~$0.001 per GB per month (example)
    gb = size_bytes / (1024 * 1024 * 1024)
    Float.round(gb * 0.001, 5)
  end

  defp format_bytes(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_bytes(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 2)} KB"

  defp format_bytes(bytes) when bytes < 1_073_741_824,
    do: "#{Float.round(bytes / 1_048_576, 2)} MB"

  defp format_bytes(bytes), do: "#{Float.round(bytes / 1_073_741_824, 2)} GB"

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
      diff < 86_400 -> "#{div(diff, 3600)}h ago"
      diff < 604_800 -> "#{div(diff, 86_400)}d ago"
      true -> Calendar.strftime(datetime, "%Y-%m-%d")
    end
  end
end
