defmodule Droodotfoo.Fileverse.Portal.Transfer.Lifecycle do
  @moduledoc """
  Transfer lifecycle management functions.
  Handles starting, updating, completing, cancelling, and resuming transfers.
  """

  require Logger

  alias Droodotfoo.Fileverse.Portal.Chunker
  alias Droodotfoo.Fileverse.Portal.Presence
  alias Droodotfoo.Fileverse.Portal.Transfer.{Helpers, Storage}

  @doc """
  Start a new file transfer.

  ## Parameters

  - `portal_id`: Portal identifier
  - `file_path`: Path to file to transfer
  - `opts`: Keyword list of options
    - `:sender` - Sender's wallet address (required)
    - `:recipients` - List of recipient addresses (default: all portal peers)
    - `:chunk_size` - Chunk size for transfer
    - `:network_quality` - Network quality for optimization

  ## Examples

      iex> Lifecycle.start_transfer("portal_abc", "/path/file.pdf", sender: "0x...")
      {:ok, %{id: "transfer_123", state: :pending, ...}}

  """
  @spec start_transfer(String.t(), String.t(), keyword()) :: {:ok, map()} | {:error, atom()}
  def start_transfer(portal_id, file_path, opts \\ []) do
    sender = Keyword.get(opts, :sender)
    recipients = Keyword.get(opts, :recipients, :all)
    chunk_size = Keyword.get(opts, :chunk_size)
    _network_quality = Keyword.get(opts, :network_quality, :good)

    if is_nil(sender) do
      {:error, :sender_required}
    else
      do_start_transfer(portal_id, file_path, sender, recipients, chunk_size)
    end
  end

  @doc """
  Start transfer from file data.

  ## Parameters

  - `portal_id`: Portal identifier
  - `file_data`: Binary file data
  - `filename`: Original filename
  - `opts`: Keyword list of options

  ## Examples

      iex> Lifecycle.start_transfer_data("portal_abc", <<1,2,3,4>>, "test.bin", sender: "0x...")
      {:ok, %{id: "transfer_123", state: :pending, ...}}

  """
  @spec start_transfer_data(String.t(), binary(), String.t(), keyword()) ::
          {:ok, map()} | {:error, atom()}
  def start_transfer_data(portal_id, file_data, filename, opts \\ []) do
    sender = Keyword.get(opts, :sender)
    recipients = Keyword.get(opts, :recipients, :all)
    chunk_size = Keyword.get(opts, :chunk_size)

    if is_nil(sender) do
      {:error, :sender_required}
    else
      do_start_transfer_data(portal_id, file_data, filename, sender, recipients, chunk_size)
    end
  end

  @doc """
  Update transfer progress.

  ## Parameters

  - `transfer_id`: Transfer identifier
  - `progress_data`: Progress update data

  ## Examples

      iex> Lifecycle.update_progress("transfer_123", %{sent_chunks: 5, received_chunks: 3})
      {:ok, %{id: "transfer_123", progress: %{progress_percentage: 60.0, ...}}}

  """
  @spec update_progress(String.t(), map()) :: {:ok, map()} | {:error, atom()}
  def update_progress(transfer_id, progress_data) do
    case Storage.get_transfer(transfer_id) do
      nil ->
        {:error, :transfer_not_found}

      transfer ->
        # Update progress
        updated_progress = Map.merge(transfer.progress, progress_data)
        updated_transfer = %{transfer | progress: updated_progress}

        # Store updated transfer
        Helpers.store_transfer(updated_transfer)

        # Broadcast progress event
        Helpers.broadcast_transfer_event(updated_transfer, :progress, updated_progress)

        {:ok, updated_transfer}
    end
  end

  @doc """
  Complete a transfer.

  ## Parameters

  - `transfer_id`: Transfer identifier
  - `success`: Whether transfer was successful

  ## Examples

      iex> Lifecycle.complete_transfer("transfer_123", true)
      {:ok, %{id: "transfer_123", state: :completed, ...}}

  """
  @spec complete_transfer(String.t(), boolean()) :: {:ok, map()} | {:error, atom()}
  def complete_transfer(transfer_id, success \\ true) do
    case Storage.get_transfer(transfer_id) do
      nil ->
        {:error, :transfer_not_found}

      transfer ->
        new_state = if success, do: :completed, else: :failed

        updated_transfer = %{
          transfer
          | state: new_state,
            completed_at: DateTime.utc_now()
        }

        # Store updated transfer
        Helpers.store_transfer(updated_transfer)

        # Broadcast completion event
        event_type = if success, do: :completed, else: :failed
        Helpers.broadcast_transfer_event(updated_transfer, event_type, %{success: success})

        Logger.info("Transfer #{transfer_id} #{if success, do: "completed", else: "failed"}")
        {:ok, updated_transfer}
    end
  end

  @doc """
  Cancel a transfer.

  ## Parameters

  - `transfer_id`: Transfer identifier

  ## Examples

      iex> Lifecycle.cancel_transfer("transfer_123")
      {:ok, %{id: "transfer_123", state: :cancelled, ...}}

  """
  @spec cancel_transfer(String.t()) :: {:ok, map()} | {:error, atom()}
  def cancel_transfer(transfer_id) do
    case Storage.get_transfer(transfer_id) do
      nil ->
        {:error, :transfer_not_found}

      transfer ->
        updated_transfer = %{
          transfer
          | state: :cancelled,
            completed_at: DateTime.utc_now()
        }

        # Store updated transfer
        Helpers.store_transfer(updated_transfer)

        # Broadcast cancellation event
        Helpers.broadcast_transfer_event(updated_transfer, :cancelled, %{})

        Logger.info("Transfer #{transfer_id} cancelled")
        {:ok, updated_transfer}
    end
  end

  @doc """
  Resume a failed transfer.

  ## Parameters

  - `transfer_id`: Transfer identifier

  ## Examples

      iex> Lifecycle.resume_transfer("transfer_123")
      {:ok, %{id: "transfer_123", state: :transferring, ...}}

  """
  @spec resume_transfer(String.t()) :: {:ok, map()} | {:error, atom()}
  def resume_transfer(transfer_id) do
    case Storage.get_transfer(transfer_id) do
      nil ->
        {:error, :transfer_not_found}

      transfer ->
        if transfer.state == :failed do
          updated_transfer = %{
            transfer
            | state: :transferring,
              started_at: DateTime.utc_now(),
              error: nil
          }

          # Store updated transfer
          Helpers.store_transfer(updated_transfer)

          # Broadcast resume event
          Helpers.broadcast_transfer_event(updated_transfer, :started, %{resumed: true})

          Logger.info("Resumed transfer #{transfer_id}")
          {:ok, updated_transfer}
        else
          {:error, :transfer_not_failed}
        end
    end
  end

  # Private helper functions

  defp do_start_transfer(portal_id, file_path, sender, recipients, chunk_size) do
    final_recipients = get_final_recipients(portal_id, sender, recipients)

    chunk_opts = [
      sender: sender,
      recipients: final_recipients,
      chunk_size: chunk_size
    ]

    start_transfer_with_chunks(portal_id, sender, final_recipients, fn ->
      Chunker.chunk_file(file_path, chunk_opts)
    end)
  end

  defp do_start_transfer_data(portal_id, file_data, filename, sender, recipients, chunk_size) do
    final_recipients = get_final_recipients(portal_id, sender, recipients)

    chunk_opts = [
      sender: sender,
      recipients: final_recipients,
      chunk_size: chunk_size
    ]

    start_transfer_with_chunks(portal_id, sender, final_recipients, fn ->
      Chunker.chunk_data(file_data, filename, chunk_opts)
    end)
  end

  defp get_final_recipients(portal_id, sender, :all) do
    case Presence.get_portal_peers(portal_id) do
      {:ok, peers} -> Enum.map(peers, & &1.wallet_address)
      {:error, _} -> [sender]
    end
  end

  defp get_final_recipients(_portal_id, _sender, recipients), do: recipients

  defp start_transfer_with_chunks(portal_id, sender, final_recipients, chunk_fn) do
    case chunk_fn.() do
      {:ok, %{file_id: file_id, chunks: _chunks, metadata: metadata}} ->
        create_and_broadcast_transfer(portal_id, file_id, sender, final_recipients, metadata)

      {:error, reason} ->
        {:error, {:chunking_failed, reason}}
    end
  end

  defp create_and_broadcast_transfer(portal_id, file_id, sender, final_recipients, metadata) do
    transfer = Helpers.create_transfer(portal_id, file_id, sender, final_recipients, metadata)
    Helpers.store_transfer(transfer)

    Helpers.broadcast_transfer_event(transfer, :started, %{
      filename: metadata.filename,
      size: metadata.size
    })

    Logger.info("Started transfer #{transfer.id} for file #{metadata.filename}")
    {:ok, transfer}
  end
end
