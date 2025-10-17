defmodule Droodotfoo.Fileverse.Portal.Chunker do
  @moduledoc """
  File chunking system for P2P file transfers.

  Handles:
  - File chunking into optimal sizes for WebRTC data channels
  - Chunk metadata and ordering
  - Integrity verification with checksums
  - Resume capability for failed transfers
  - Progress tracking and reporting
  - Memory-efficient streaming

  Optimized for WebRTC data channel constraints and network conditions.
  """

  require Logger

  @type chunk :: %{
          id: String.t(),
          file_id: String.t(),
          index: integer(),
          data: binary(),
          size: integer(),
          checksum: String.t(),
          is_last: boolean(),
          created_at: DateTime.t()
        }

  @type file_metadata :: %{
          id: String.t(),
          filename: String.t(),
          size: integer(),
          mime_type: String.t(),
          checksum: String.t(),
          total_chunks: integer(),
          chunk_size: integer(),
          created_at: DateTime.t(),
          sender: String.t(),
          recipients: [String.t()]
        }

  @type transfer_progress :: %{
          file_id: String.t(),
          total_chunks: integer(),
          sent_chunks: integer(),
          received_chunks: integer(),
          failed_chunks: integer(),
          progress_percentage: float(),
          estimated_time_remaining: integer(),
          transfer_speed: float()
        }

  # Default chunk size optimized for WebRTC data channels (16KB)
  @default_chunk_size 16_384
  @max_chunk_size 64_000
  @min_chunk_size 1_024

  @doc """
  Chunk a file into transferable pieces.

  ## Parameters

  - `file_path`: Path to the file to chunk
  - `opts`: Keyword list of options
    - `:chunk_size` - Size of each chunk in bytes (default: 16KB)
    - `:file_id` - Unique file identifier (auto-generated if not provided)
    - `:sender` - Sender's wallet address
    - `:recipients` - List of recipient addresses

  ## Examples

      iex> Chunker.chunk_file("/path/to/file.pdf", sender: "0x...", recipients: ["0x..."])
      {:ok, %{file_id: "file_abc123", chunks: [...], metadata: %{...}}}

  """
  @spec chunk_file(String.t(), keyword()) :: {:ok, map()} | {:error, atom()}
  def chunk_file(file_path, opts \\ []) do
    chunk_size = Keyword.get(opts, :chunk_size, @default_chunk_size)
    file_id = Keyword.get(opts, :file_id, generate_file_id())
    sender = Keyword.get(opts, :sender)
    recipients = Keyword.get(opts, :recipients, [])

    if is_nil(sender) do
      {:error, :sender_required}
    else
      case File.read(file_path) do
        {:ok, file_data} ->
          chunk_file_data(file_data, file_path, file_id, chunk_size, sender, recipients)

        {:error, reason} ->
          {:error, {:file_read_error, reason}}
      end
    end
  end

  @doc """
  Chunk file data from memory.

  ## Parameters

  - `file_data`: Binary file data
  - `filename`: Original filename
  - `opts`: Keyword list of options

  ## Examples

      iex> Chunker.chunk_data(<<1, 2, 3, 4>>, "test.bin", sender: "0x...")
      {:ok, %{file_id: "file_abc123", chunks: [...], metadata: %{...}}}

  """
  @spec chunk_data(binary(), String.t(), keyword()) :: {:ok, map()} | {:error, atom()}
  def chunk_data(file_data, filename, opts \\ []) do
    chunk_size = Keyword.get(opts, :chunk_size, @default_chunk_size)
    file_id = Keyword.get(opts, :file_id, generate_file_id())
    sender = Keyword.get(opts, :sender)
    recipients = Keyword.get(opts, :recipients, [])

    if is_nil(sender) do
      {:error, :sender_required}
    else
      chunk_file_data(file_data, filename, file_id, chunk_size, sender, recipients)
    end
  end

  @doc """
  Reassemble chunks into original file.

  ## Parameters

  - `chunks`: List of chunks in order
  - `metadata`: File metadata

  ## Examples

      iex> Chunker.reassemble_file(chunks, metadata)
      {:ok, %{data: <<...>>, filename: "test.pdf", size: 1024, verified: true}}

  """
  @spec reassemble_file([chunk()], file_metadata()) :: {:ok, map()} | {:error, atom()}
  def reassemble_file(chunks, metadata) do
    # Sort chunks by index
    sorted_chunks = Enum.sort_by(chunks, & &1.index)

    # Verify we have all chunks
    expected_indices = 0..(metadata.total_chunks - 1) |> Enum.to_list()
    received_indices = Enum.map(sorted_chunks, & &1.index)

    if received_indices == expected_indices do
      # Reassemble data
      file_data = Enum.map(sorted_chunks, & &1.data) |> IO.iodata_to_binary()
      verify_reassembled_file(file_data, metadata)
    else
      missing_chunks = expected_indices -- received_indices
      {:error, {:missing_chunks, missing_chunks}}
    end
  end

  @doc """
  Get transfer progress for a file.

  ## Parameters

  - `file_id`: File identifier
  - `sent_chunks`: Number of chunks sent
  - `received_chunks`: Number of chunks received
  - `failed_chunks`: Number of failed chunks
  - `start_time`: Transfer start time

  ## Examples

      iex> Chunker.get_transfer_progress("file_abc", 10, 8, 1, start_time)
      %{progress_percentage: 80.0, estimated_time_remaining: 30, ...}

  """
  @spec get_transfer_progress(String.t(), integer(), integer(), integer(), DateTime.t()) ::
          transfer_progress()
  def get_transfer_progress(file_id, sent_chunks, received_chunks, failed_chunks, start_time) do
    total_chunks = sent_chunks + received_chunks + failed_chunks
    progress_percentage = if total_chunks > 0, do: received_chunks / total_chunks * 100, else: 0.0

    # Calculate transfer speed
    elapsed_seconds = DateTime.diff(DateTime.utc_now(), start_time, :second)
    transfer_speed = if elapsed_seconds > 0, do: received_chunks / elapsed_seconds, else: 0.0

    # Estimate time remaining
    remaining_chunks = total_chunks - received_chunks

    estimated_time_remaining =
      if transfer_speed > 0, do: round(remaining_chunks / transfer_speed), else: 0

    %{
      file_id: file_id,
      total_chunks: total_chunks,
      sent_chunks: sent_chunks,
      received_chunks: received_chunks,
      failed_chunks: failed_chunks,
      progress_percentage: Float.round(progress_percentage, 2),
      estimated_time_remaining: estimated_time_remaining,
      transfer_speed: Float.round(transfer_speed, 2)
    }
  end

  @doc """
  Validate chunk integrity.

  ## Parameters

  - `chunk`: Chunk to validate

  ## Examples

      iex> Chunker.validate_chunk(chunk)
      {:ok, true} | {:error, :invalid_checksum}

  """
  @spec validate_chunk(chunk()) :: {:ok, boolean()} | {:error, atom()}
  def validate_chunk(chunk) do
    calculated_checksum = calculate_checksum(chunk.data)

    if calculated_checksum == chunk.checksum do
      {:ok, true}
    else
      {:error, :invalid_checksum}
    end
  end

  @doc """
  Get optimal chunk size for network conditions.

  ## Parameters

  - `file_size`: Size of file to transfer
  - `network_quality`: Network quality (:excellent, :good, :fair, :poor)

  ## Examples

      iex> Chunker.get_optimal_chunk_size(1_000_000, :good)
      16384

  """
  @spec get_optimal_chunk_size(integer(), atom()) :: integer()
  def get_optimal_chunk_size(file_size, network_quality) do
    base_size =
      case network_quality do
        :excellent -> @default_chunk_size * 2
        :good -> @default_chunk_size
        :fair -> @default_chunk_size / 2
        :poor -> @default_chunk_size / 4
      end

    # Adjust based on file size
    adjusted_size =
      cond do
        file_size < 100_000 -> min(base_size, @default_chunk_size / 2)
        file_size > 10_000_000 -> min(base_size * 2, @max_chunk_size)
        true -> base_size
      end

    # Ensure within bounds
    max(round(adjusted_size), @min_chunk_size)
    |> min(@max_chunk_size)
  end

  @doc """
  Create file metadata from chunks.

  ## Parameters

  - `chunks`: List of chunks
  - `filename`: Original filename
  - `sender`: Sender's wallet address
  - `recipients`: List of recipient addresses

  ## Examples

      iex> Chunker.create_metadata(chunks, "test.pdf", "0x...", ["0x..."])
      %{id: "file_abc", filename: "test.pdf", size: 1024, ...}

  """
  @spec create_metadata([chunk()], String.t(), String.t(), [String.t()]) :: file_metadata()
  def create_metadata(chunks, filename, sender, recipients) do
    total_chunks = length(chunks)
    chunk_size = if total_chunks > 0, do: byte_size(hd(chunks).data), else: 0
    file_data = Enum.map(chunks, & &1.data) |> IO.iodata_to_binary()
    file_size = byte_size(file_data)
    checksum = calculate_checksum(file_data)
    mime_type = get_mime_type(filename)

    %{
      id: hd(chunks).file_id,
      filename: filename,
      size: file_size,
      mime_type: mime_type,
      checksum: checksum,
      total_chunks: total_chunks,
      chunk_size: chunk_size,
      created_at: DateTime.utc_now(),
      sender: sender,
      recipients: recipients
    }
  end

  # Private helper functions

  defp chunk_file_data(file_data, file_path, file_id, chunk_size, sender, recipients) do
    filename = Path.basename(file_path)
    file_size = byte_size(file_data)
    chunk_size = chunk_size || @default_chunk_size
    total_chunks = div(file_size + chunk_size - 1, chunk_size)

    # Create chunks
    chunks =
      file_data
      |> chunk_binary(chunk_size)
      |> Enum.with_index()
      |> Enum.map(fn {chunk_data, index} ->
        is_last = index == total_chunks - 1
        create_chunk(file_id, index, chunk_data, is_last)
      end)

    # Create metadata
    metadata = create_metadata(chunks, filename, sender, recipients)

    Logger.info("Chunked file #{filename} into #{total_chunks} chunks (#{file_size} bytes)")
    {:ok, %{file_id: file_id, chunks: chunks, metadata: metadata}}
  end

  defp chunk_binary(data, chunk_size) do
    chunk_binary(data, chunk_size, [])
  end

  defp chunk_binary(<<>>, _chunk_size, acc) do
    Enum.reverse(acc)
  end

  defp chunk_binary(data, chunk_size, acc) do
    data_size = byte_size(data)

    if data_size == 0 do
      Enum.reverse(acc)
    else
      chunk_size_to_use = min(chunk_size, data_size)
      chunk = binary_part(data, 0, chunk_size_to_use)

      if data_size <= chunk_size do
        Enum.reverse([chunk | acc])
      else
        remaining = binary_part(data, chunk_size, data_size - chunk_size)
        chunk_binary(remaining, chunk_size, [chunk | acc])
      end
    end
  end

  defp create_chunk(file_id, index, data, is_last) do
    %{
      id: "#{file_id}_chunk_#{index}",
      file_id: file_id,
      index: index,
      data: data,
      size: byte_size(data),
      checksum: calculate_checksum(data),
      is_last: is_last,
      created_at: DateTime.utc_now()
    }
  end

  defp calculate_checksum(data) do
    :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
  end

  defp generate_file_id do
    "file_" <> (:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower))
  end

  defp get_mime_type(filename) do
    filename
    |> Path.extname()
    |> String.downcase()
    |> mime_type_from_extension()
  end

  defp mime_type_from_extension(ext) do
    mime_type_map()[ext] || "application/octet-stream"
  end

  defp mime_type_map do
    %{
      ".pdf" => "application/pdf",
      ".txt" => "text/plain",
      ".jpg" => "image/jpeg",
      ".jpeg" => "image/jpeg",
      ".png" => "image/png",
      ".gif" => "image/gif",
      ".mp4" => "video/mp4",
      ".mp3" => "audio/mpeg",
      ".zip" => "application/zip",
      ".json" => "application/json"
    }
  end

  defp verify_reassembled_file(file_data, metadata) do
    if byte_size(file_data) == metadata.size do
      verify_checksum(file_data, metadata)
    else
      {:error, :size_mismatch}
    end
  end

  defp verify_checksum(file_data, metadata) do
    calculated_checksum = calculate_checksum(file_data)

    if calculated_checksum == metadata.checksum do
      {:ok,
       %{
         data: file_data,
         filename: metadata.filename,
         size: metadata.size,
         verified: true,
         checksum: calculated_checksum
       }}
    else
      {:error, :checksum_mismatch}
    end
  end
end
