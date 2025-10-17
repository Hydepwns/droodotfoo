defmodule Droodotfoo.Fileverse.Portal.TransferProgress do
  @moduledoc """
  Real-time transfer progress tracking for Portal P2P file transfers.

  Handles:
  - Transfer progress monitoring
  - Speed calculation and ETA estimation
  - Progress bar generation
  - Real-time updates via PubSub
  - Transfer statistics and analytics
  - Progress persistence and cleanup

  Integrates with Transfer and Chunker modules.
  """

  require Logger

  @type transfer_progress :: %{
          transfer_id: String.t(),
          file_id: String.t(),
          filename: String.t(),
          total_size: integer(),
          transferred_size: integer(),
          progress_percentage: float(),
          speed_bytes_per_second: float(),
          eta_seconds: integer(),
          start_time: DateTime.t(),
          last_update: DateTime.t(),
          status: :pending | :transferring | :paused | :completed | :failed,
          error_message: String.t() | nil
        }

  @type progress_update :: %{
          transfer_id: String.t(),
          progress: transfer_progress(),
          timestamp: DateTime.t()
        }

  @type transfer_stats :: %{
          total_transfers: integer(),
          active_transfers: integer(),
          completed_transfers: integer(),
          failed_transfers: integer(),
          total_data_transferred: integer(),
          average_speed: float(),
          success_rate: float()
        }

  @doc """
  Start tracking progress for a transfer.

  ## Parameters

  - `transfer_id`: Unique transfer identifier
  - `file_id`: File identifier
  - `filename`: Name of the file being transferred
  - `total_size`: Total size of the file in bytes
  - `opts`: Keyword list of options
    - `:portal_id` - Portal ID (required)
    - `:sender` - Sender's wallet address
    - `:recipients` - List of recipient addresses

  ## Examples

      iex> TransferProgress.start_tracking("transfer_123", "file_456", "document.pdf", 1024 * 1024, portal_id: "portal_abc")
      {:ok, %{transfer_id: "transfer_123", progress_percentage: 0.0, ...}}

  """
  @spec start_tracking(String.t(), String.t(), String.t(), integer(), keyword()) ::
          {:ok, transfer_progress()} | {:error, atom()}
  def start_tracking(transfer_id, file_id, filename, total_size, opts \\ []) do
    portal_id = Keyword.get(opts, :portal_id)
    _sender = Keyword.get(opts, :sender)
    _recipients = Keyword.get(opts, :recipients, [])

    if portal_id do
      progress = %{
        transfer_id: transfer_id,
        file_id: file_id,
        filename: filename,
        total_size: total_size,
        transferred_size: 0,
        progress_percentage: 0.0,
        speed_bytes_per_second: 0.0,
        eta_seconds: 0,
        start_time: DateTime.utc_now(),
        last_update: DateTime.utc_now(),
        status: :pending,
        error_message: nil
      }

      # Broadcast initial progress
      broadcast_progress_update(portal_id, progress)

      # Log transfer start
      Logger.info(
        "Started tracking transfer #{transfer_id} for file #{filename} (#{format_size(total_size)})"
      )

      {:ok, progress}
    else
      {:error, :portal_id_required}
    end
  end

  @doc """
  Update transfer progress.

  ## Parameters

  - `transfer_id`: Transfer identifier
  - `transferred_size`: Number of bytes transferred so far
  - `opts`: Keyword list of options
    - `:portal_id` - Portal ID (required)
    - `:status` - New transfer status (optional)

  ## Examples

      iex> TransferProgress.update_progress("transfer_123", 512 * 1024, portal_id: "portal_abc")
      {:ok, %{transfer_id: "transfer_123", progress_percentage: 50.0, ...}}

  """
  @spec update_progress(String.t(), integer(), keyword()) ::
          {:ok, transfer_progress()} | {:error, atom()}
  def update_progress(transfer_id, transferred_size, opts \\ []) do
    portal_id = Keyword.get(opts, :portal_id)
    status = Keyword.get(opts, :status)

    if portal_id do
      do_update_progress(transfer_id, transferred_size, status, portal_id)
    else
      {:error, :portal_id_required}
    end
  end

  @doc """
  Complete a transfer.

  ## Parameters

  - `transfer_id`: Transfer identifier
  - `opts`: Keyword list of options
    - `:portal_id` - Portal ID (required)
    - `:final_size` - Final transferred size (optional)

  ## Examples

      iex> TransferProgress.complete_transfer("transfer_123", portal_id: "portal_abc")
      {:ok, %{transfer_id: "transfer_123", status: :completed, ...}}

  """
  @spec complete_transfer(String.t(), keyword()) ::
          {:ok, transfer_progress()} | {:error, atom()}
  def complete_transfer(transfer_id, opts \\ []) do
    portal_id = Keyword.get(opts, :portal_id)
    final_size = Keyword.get(opts, :final_size)

    if portal_id do
      # Get current progress
      current_progress = get_current_progress(transfer_id)

      if current_progress do
        completed_progress = %{
          current_progress
          | status: :completed,
            transferred_size: final_size || current_progress.total_size,
            progress_percentage: 100.0,
            speed_bytes_per_second: 0.0,
            eta_seconds: 0,
            last_update: DateTime.utc_now()
        }

        # Broadcast completion
        broadcast_progress_update(portal_id, completed_progress)

        # Log completion
        duration =
          DateTime.diff(completed_progress.last_update, completed_progress.start_time, :second)

        Logger.info("Transfer #{transfer_id} completed in #{duration}s")

        {:ok, completed_progress}
      else
        {:error, :transfer_not_found}
      end
    else
      {:error, :portal_id_required}
    end
  end

  @doc """
  Fail a transfer.

  ## Parameters

  - `transfer_id`: Transfer identifier
  - `error_message`: Error message describing the failure
  - `opts`: Keyword list of options
    - `:portal_id` - Portal ID (required)

  ## Examples

      iex> TransferProgress.fail_transfer("transfer_123", "Network timeout", portal_id: "portal_abc")
      {:ok, %{transfer_id: "transfer_123", status: :failed, ...}}

  """
  @spec fail_transfer(String.t(), String.t(), keyword()) ::
          {:ok, transfer_progress()} | {:error, atom()}
  def fail_transfer(transfer_id, error_message, opts \\ []) do
    portal_id = Keyword.get(opts, :portal_id)

    if portal_id do
      # Get current progress
      current_progress = get_current_progress(transfer_id)

      if current_progress do
        failed_progress = %{
          current_progress
          | status: :failed,
            error_message: error_message,
            last_update: DateTime.utc_now()
        }

        # Broadcast failure
        broadcast_progress_update(portal_id, failed_progress)

        # Log failure
        Logger.error("Transfer #{transfer_id} failed: #{error_message}")

        {:ok, failed_progress}
      else
        {:error, :transfer_not_found}
      end
    else
      {:error, :portal_id_required}
    end
  end

  @doc """
  Get current progress for a transfer.

  ## Parameters

  - `transfer_id`: Transfer identifier

  ## Examples

      iex> TransferProgress.get_progress("transfer_123")
      {:ok, %{transfer_id: "transfer_123", progress_percentage: 75.5, ...}}

  """
  @spec get_progress(String.t()) :: {:ok, transfer_progress()} | {:error, atom()}
  def get_progress(transfer_id) do
    progress = get_current_progress(transfer_id)

    if progress do
      {:ok, progress}
    else
      {:error, :transfer_not_found}
    end
  end

  @doc """
  Get all active transfers for a portal.

  ## Parameters

  - `portal_id`: Portal identifier

  ## Examples

      iex> TransferProgress.get_active_transfers("portal_abc")
      {:ok, [%{transfer_id: "transfer_123", ...}, ...]}

  """
  @spec get_active_transfers(String.t()) :: {:ok, [transfer_progress()]} | {:error, atom()}
  def get_active_transfers(portal_id) do
    # Mock implementation - would get from database/cache
    active_transfers = get_mock_active_transfers(portal_id)
    {:ok, active_transfers}
  end

  @doc """
  Get transfer statistics for a portal.

  ## Parameters

  - `portal_id`: Portal identifier
  - `opts`: Keyword list of options
    - `:timeframe` - Timeframe for statistics (default: :last_24h)

  ## Examples

      iex> TransferProgress.get_stats("portal_abc")
      {:ok, %{total_transfers: 15, active_transfers: 2, ...}}

  """
  @spec get_stats(String.t(), keyword()) :: {:ok, transfer_stats()} | {:error, atom()}
  def get_stats(_portal_id, opts \\ []) do
    _timeframe = Keyword.get(opts, :timeframe, :last_24h)

    # Mock implementation
    stats = %{
      total_transfers: 15,
      active_transfers: 2,
      completed_transfers: 12,
      failed_transfers: 1,
      # 50MB
      total_data_transferred: 50 * 1024 * 1024,
      # 2.5 MB/s
      average_speed: 2.5 * 1024 * 1024,
      success_rate: 92.3
    }

    {:ok, stats}
  end

  # Helper functions

  defp do_update_progress(transfer_id, transferred_size, status, portal_id) do
    current_progress = get_current_progress(transfer_id)

    if current_progress do
      calculate_and_broadcast_progress(
        current_progress,
        transfer_id,
        transferred_size,
        status,
        portal_id
      )
    else
      {:error, :transfer_not_found}
    end
  end

  defp calculate_and_broadcast_progress(
         current_progress,
         transfer_id,
         transferred_size,
         status,
         portal_id
       ) do
    progress_percentage = transferred_size / current_progress.total_size * 100
    speed = calculate_speed(current_progress, transferred_size)
    eta = calculate_eta(current_progress, transferred_size, speed)

    updated_progress = %{
      current_progress
      | transferred_size: transferred_size,
        progress_percentage: progress_percentage,
        speed_bytes_per_second: speed,
        eta_seconds: eta,
        last_update: DateTime.utc_now(),
        status: status || current_progress.status
    }

    broadcast_progress_update(portal_id, updated_progress)
    log_progress_if_significant(transfer_id, progress_percentage)

    {:ok, updated_progress}
  end

  defp log_progress_if_significant(transfer_id, progress_percentage) do
    if rem(round(progress_percentage), 10) == 0 do
      Logger.info("Transfer #{transfer_id}: #{Float.round(progress_percentage, 1)}% complete")
    end
  end

  defp get_current_progress(transfer_id) do
    # Mock implementation - would get from database/cache
    %{
      transfer_id: transfer_id,
      file_id: "file_456",
      filename: "document.pdf",
      # 1MB
      total_size: 1024 * 1024,
      # 512KB
      transferred_size: 512 * 1024,
      progress_percentage: 50.0,
      # 1MB/s
      speed_bytes_per_second: 1024 * 1024,
      eta_seconds: 30,
      start_time: DateTime.add(DateTime.utc_now(), -60, :second),
      last_update: DateTime.utc_now(),
      status: :transferring,
      error_message: nil
    }
  end

  defp get_mock_active_transfers(_portal_id) do
    [
      %{
        transfer_id: "transfer_1",
        file_id: "file_1",
        filename: "document.pdf",
        total_size: 1024 * 1024,
        transferred_size: 512 * 1024,
        progress_percentage: 50.0,
        speed_bytes_per_second: 1024 * 1024,
        eta_seconds: 30,
        start_time: DateTime.add(DateTime.utc_now(), -60, :second),
        last_update: DateTime.utc_now(),
        status: :transferring,
        error_message: nil
      },
      %{
        transfer_id: "transfer_2",
        file_id: "file_2",
        filename: "image.jpg",
        total_size: 512 * 1024,
        transferred_size: 256 * 1024,
        progress_percentage: 50.0,
        speed_bytes_per_second: 512 * 1024,
        eta_seconds: 15,
        start_time: DateTime.add(DateTime.utc_now(), -30, :second),
        last_update: DateTime.utc_now(),
        status: :transferring,
        error_message: nil
      }
    ]
  end

  defp calculate_speed(current_progress, transferred_size) do
    time_elapsed = DateTime.diff(DateTime.utc_now(), current_progress.start_time, :second)

    if time_elapsed > 0 do
      transferred_size / time_elapsed
    else
      0.0
    end
  end

  defp calculate_eta(current_progress, transferred_size, speed) do
    remaining_bytes = current_progress.total_size - transferred_size

    if speed > 0 do
      round(remaining_bytes / speed)
    else
      0
    end
  end

  defp broadcast_progress_update(portal_id, progress) do
    update = %{
      transfer_id: progress.transfer_id,
      progress: progress,
      timestamp: DateTime.utc_now()
    }

    # Broadcast to portal-specific channel
    Phoenix.PubSub.broadcast(
      Droodotfoo.PubSub,
      "portal:#{portal_id}:transfers",
      {:transfer_progress, update}
    )

    # Also broadcast to global transfers channel
    Phoenix.PubSub.broadcast(
      Droodotfoo.PubSub,
      "portal:transfers",
      {:transfer_progress, update}
    )
  end

  defp format_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_size(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 2)} KB"

  defp format_size(bytes) when bytes < 1_073_741_824,
    do: "#{Float.round(bytes / 1_048_576, 2)} MB"

  defp format_size(bytes), do: "#{Float.round(bytes / 1_073_741_824, 2)} GB"
end
