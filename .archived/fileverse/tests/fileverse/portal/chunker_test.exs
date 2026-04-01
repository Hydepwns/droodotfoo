defmodule Droodotfoo.Fileverse.Portal.ChunkerTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Fileverse.Portal.Chunker

  describe "chunk_data/3" do
    test "chunks binary data into pieces" do
      file_data = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>
      filename = "test.bin"
      opts = [sender: "0x1234567890abcdef1234567890abcdef12345678"]

      assert {:ok, result} = Chunker.chunk_data(file_data, filename, opts)

      assert is_binary(result.file_id)
      assert is_list(result.chunks)
      assert is_map(result.metadata)

      # Verify metadata
      assert result.metadata.filename == filename
      assert result.metadata.size == 10
      assert result.metadata.sender == "0x1234567890abcdef1234567890abcdef12345678"
      assert result.metadata.total_chunks > 0
    end

    test "returns error when sender is missing" do
      file_data = <<1, 2, 3, 4>>
      filename = "test.bin"
      opts = []

      assert {:error, :sender_required} = Chunker.chunk_data(file_data, filename, opts)
    end

    test "chunks with custom chunk size" do
      file_data = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>
      filename = "test.bin"

      opts = [
        sender: "0x1234567890abcdef1234567890abcdef12345678",
        chunk_size: 3
      ]

      assert {:ok, result} = Chunker.chunk_data(file_data, filename, opts)

      # With chunk size 3, 10 bytes should create 4 chunks (3+3+3+1)
      assert length(result.chunks) == 4
      assert result.metadata.total_chunks == 4
    end

    test "chunks with recipients" do
      file_data = <<1, 2, 3, 4>>
      filename = "test.bin"

      recipients = [
        "0x1111111111111111111111111111111111111111",
        "0x2222222222222222222222222222222222222222"
      ]

      opts = [
        sender: "0x1234567890abcdef1234567890abcdef12345678",
        recipients: recipients
      ]

      assert {:ok, result} = Chunker.chunk_data(file_data, filename, opts)
      assert result.metadata.recipients == recipients
    end
  end

  describe "reassemble_file/2" do
    test "reassembles chunks into original data" do
      file_data = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>
      filename = "test.bin"
      sender = "0x1234567890abcdef1234567890abcdef12345678"

      # Chunk the data
      {:ok, %{chunks: chunks, metadata: metadata}} =
        Chunker.chunk_data(file_data, filename, sender: sender)

      # Reassemble
      assert {:ok, result} = Chunker.reassemble_file(chunks, metadata)

      assert result.data == file_data
      assert result.filename == filename
      assert result.size == 10
      assert result.verified == true
    end

    test "returns error for missing chunks" do
      file_data = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>
      filename = "test.bin"
      sender = "0x1234567890abcdef1234567890abcdef12345678"

      # Chunk the data
      {:ok, %{chunks: chunks, metadata: metadata}} =
        Chunker.chunk_data(file_data, filename, sender: sender)

      # Remove a chunk
      incomplete_chunks = Enum.drop(chunks, 1)

      assert {:error, {:missing_chunks, _}} = Chunker.reassemble_file(incomplete_chunks, metadata)
    end

    test "returns error for size mismatch" do
      file_data = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>
      filename = "test.bin"
      sender = "0x1234567890abcdef1234567890abcdef12345678"

      # Chunk the data
      {:ok, %{chunks: chunks, metadata: metadata}} =
        Chunker.chunk_data(file_data, filename, sender: sender)

      # Modify metadata to have wrong size
      wrong_metadata = %{metadata | size: 5}

      assert {:error, :size_mismatch} = Chunker.reassemble_file(chunks, wrong_metadata)
    end

    test "returns error for checksum mismatch" do
      file_data = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>
      filename = "test.bin"
      sender = "0x1234567890abcdef1234567890abcdef12345678"

      # Chunk the data
      {:ok, %{chunks: chunks, metadata: metadata}} =
        Chunker.chunk_data(file_data, filename, sender: sender)

      # Modify metadata to have wrong checksum
      wrong_metadata = %{metadata | checksum: "wrong_checksum"}

      assert {:error, :checksum_mismatch} = Chunker.reassemble_file(chunks, wrong_metadata)
    end
  end

  describe "get_transfer_progress/5" do
    test "calculates transfer progress" do
      file_id = "file_abc123"
      sent_chunks = 10
      received_chunks = 8
      failed_chunks = 1
      start_time = DateTime.add(DateTime.utc_now(), -60, :second)

      progress =
        Chunker.get_transfer_progress(
          file_id,
          sent_chunks,
          received_chunks,
          failed_chunks,
          start_time
        )

      assert progress.file_id == file_id
      assert progress.total_chunks == 19
      assert progress.sent_chunks == 10
      assert progress.received_chunks == 8
      assert progress.failed_chunks == 1
      assert progress.progress_percentage == 42.11
      assert is_integer(progress.estimated_time_remaining)
      assert is_float(progress.transfer_speed)
    end

    test "handles zero elapsed time" do
      file_id = "file_abc123"
      sent_chunks = 5
      received_chunks = 3
      failed_chunks = 0
      start_time = DateTime.utc_now()

      progress =
        Chunker.get_transfer_progress(
          file_id,
          sent_chunks,
          received_chunks,
          failed_chunks,
          start_time
        )

      assert progress.transfer_speed == 0.0
      assert progress.estimated_time_remaining == 0
    end
  end

  describe "validate_chunk/1" do
    test "validates chunk with correct checksum" do
      data = <<1, 2, 3, 4, 5>>
      checksum = :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)

      chunk = %{
        id: "chunk_123",
        file_id: "file_abc",
        index: 0,
        data: data,
        size: 5,
        checksum: checksum,
        is_last: false,
        created_at: DateTime.utc_now()
      }

      assert {:ok, true} = Chunker.validate_chunk(chunk)
    end

    test "returns error for invalid checksum" do
      data = <<1, 2, 3, 4, 5>>

      chunk = %{
        id: "chunk_123",
        file_id: "file_abc",
        index: 0,
        data: data,
        size: 5,
        checksum: "invalid_checksum",
        is_last: false,
        created_at: DateTime.utc_now()
      }

      assert {:error, :invalid_checksum} = Chunker.validate_chunk(chunk)
    end
  end

  describe "get_optimal_chunk_size/2" do
    test "returns appropriate chunk size for network quality" do
      file_size = 1_000_000

      excellent_size = Chunker.get_optimal_chunk_size(file_size, :excellent)
      good_size = Chunker.get_optimal_chunk_size(file_size, :good)
      fair_size = Chunker.get_optimal_chunk_size(file_size, :fair)
      poor_size = Chunker.get_optimal_chunk_size(file_size, :poor)

      assert excellent_size >= good_size
      assert good_size >= fair_size
      assert fair_size >= poor_size
    end

    test "adjusts chunk size based on file size" do
      small_file_size = Chunker.get_optimal_chunk_size(50_000, :good)
      medium_file_size = Chunker.get_optimal_chunk_size(1_000_000, :good)
      large_file_size = Chunker.get_optimal_chunk_size(20_000_000, :good)

      assert small_file_size <= medium_file_size
      assert medium_file_size <= large_file_size
    end

    test "respects minimum and maximum chunk sizes" do
      # Test with very small file
      small_size = Chunker.get_optimal_chunk_size(100, :poor)
      # minimum
      assert small_size >= 1024

      # Test with very large file
      large_size = Chunker.get_optimal_chunk_size(100_000_000, :excellent)
      # maximum
      assert large_size <= 64_000
    end
  end

  describe "create_metadata/4" do
    test "creates metadata from chunks" do
      _file_data = <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>
      filename = "test.bin"
      sender = "0x1234567890abcdef1234567890abcdef12345678"
      recipients = ["0x1111111111111111111111111111111111111111"]

      # Create chunks manually
      chunks = [
        %{
          id: "chunk_0",
          file_id: "file_abc",
          index: 0,
          data: <<1, 2, 3, 4, 5>>,
          size: 5,
          checksum: :crypto.hash(:sha256, <<1, 2, 3, 4, 5>>) |> Base.encode16(case: :lower),
          is_last: false,
          created_at: DateTime.utc_now()
        },
        %{
          id: "chunk_1",
          file_id: "file_abc",
          index: 1,
          data: <<6, 7, 8, 9, 10>>,
          size: 5,
          checksum: :crypto.hash(:sha256, <<6, 7, 8, 9, 10>>) |> Base.encode16(case: :lower),
          is_last: true,
          created_at: DateTime.utc_now()
        }
      ]

      metadata = Chunker.create_metadata(chunks, filename, sender, recipients)

      assert metadata.id == "file_abc"
      assert metadata.filename == filename
      assert metadata.size == 10
      assert metadata.total_chunks == 2
      assert metadata.chunk_size == 5
      assert metadata.sender == sender
      assert metadata.recipients == recipients
      assert is_binary(metadata.checksum)
      assert is_struct(metadata.created_at, DateTime)
    end

    test "detects MIME type from filename" do
      chunks = [
        %{
          id: "chunk_0",
          file_id: "file_abc",
          index: 0,
          data: <<1, 2, 3, 4>>,
          size: 4,
          checksum: "abc123",
          is_last: true,
          created_at: DateTime.utc_now()
        }
      ]

      pdf_metadata = Chunker.create_metadata(chunks, "document.pdf", "sender", [])
      assert pdf_metadata.mime_type == "application/pdf"

      txt_metadata = Chunker.create_metadata(chunks, "readme.txt", "sender", [])
      assert txt_metadata.mime_type == "text/plain"

      jpg_metadata = Chunker.create_metadata(chunks, "image.jpg", "sender", [])
      assert jpg_metadata.mime_type == "image/jpeg"

      unknown_metadata = Chunker.create_metadata(chunks, "unknown.xyz", "sender", [])
      assert unknown_metadata.mime_type == "application/octet-stream"
    end
  end
end
