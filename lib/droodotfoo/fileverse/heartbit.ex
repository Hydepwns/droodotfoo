defmodule Droodotfoo.Fileverse.HeartBit do
  @moduledoc """
  Fileverse HeartBit SDK integration for onchain social interactions.

  Provides terminal interface for:
  - Sending "HeartBits" (provable onchain likes)
  - Viewing like counts and engagement metrics
  - Social activity feed with wallet addresses/ENS names
  - User engagement analytics

  Note: Full implementation requires HeartBit SDK integration
  and onchain transaction handling.
  """

  require Logger

  @type heartbit :: %{
          id: String.t(),
          sender: String.t(),
          recipient: String.t(),
          content_id: String.t(),
          content_type: :document | :file | :portal | :sheet,
          amount: integer(),
          message: String.t() | nil,
          created_at: DateTime.t(),
          transaction_hash: String.t() | nil,
          block_number: integer() | nil
        }

  @type engagement_metrics :: %{
          total_heartbits: integer(),
          unique_senders: integer(),
          unique_recipients: integer(),
          total_amount: integer(),
          avg_amount: float(),
          top_content: [content_engagement()],
          recent_activity: [heartbit()]
        }

  @type content_engagement :: %{
          content_id: String.t(),
          content_type: atom(),
          title: String.t(),
          total_likes: integer(),
          unique_likers: integer(),
          total_amount: integer(),
          last_activity: DateTime.t()
        }

  @type activity_feed_item :: %{
          heartbit: heartbit(),
          sender_ens: String.t() | nil,
          recipient_ens: String.t() | nil,
          content_title: String.t(),
          relative_time: String.t()
        }

  @doc """
  Send a HeartBit (like) to content.

  ## Parameters

  - `content_id`: ID of the content to like
  - `opts`: Keyword list of options
    - `:wallet_address` - Sender's wallet address (required)
    - `:amount` - Amount of HeartBits to send (default: 1)
    - `:message` - Optional message with the like
    - `:content_type` - Type of content (:document, :file, :portal, :sheet)

  ## Examples

      iex> HeartBit.send("doc_123", wallet_address: "0x...", amount: 5)
      {:ok, %{id: "heartbit_456", transaction_hash: "0x...", ...}}

  """
  @spec send(String.t(), keyword()) :: {:ok, heartbit()} | {:error, atom()}
  def send(content_id, opts \\ []) do
    wallet_address = Keyword.get(opts, :wallet_address)
    amount = Keyword.get(opts, :amount, 1)
    message = Keyword.get(opts, :message)
    content_type = Keyword.get(opts, :content_type, :document)

    if is_nil(wallet_address) do
      {:error, :wallet_required}
    else
      # Mock implementation - in production would:
      # 1. Validate wallet connection
      # 2. Check content exists and is accessible
      # 3. Submit onchain transaction
      # 4. Wait for confirmation
      # 5. Update local state

      heartbit = %{
        id: "heartbit_#{:crypto.strong_rand_bytes(8) |> Base.encode16(case: :lower)}",
        sender: wallet_address,
        recipient: get_content_owner(content_id, content_type),
        content_id: content_id,
        content_type: content_type,
        amount: amount,
        message: message,
        created_at: DateTime.utc_now(),
        transaction_hash: "0x#{:crypto.strong_rand_bytes(32) |> Base.encode16(case: :lower)}",
        block_number: 18_500_000 + :rand.uniform(1000)
      }

      # Store in mock database
      store_heartbit(heartbit)

      Logger.info(
        "HeartBit sent: #{heartbit.id} from #{abbreviate_address(wallet_address)} to #{content_id}"
      )

      {:ok, heartbit}
    end
  end

  @doc """
  Get HeartBits for specific content.

  ## Parameters

  - `content_id`: ID of the content
  - `opts`: Keyword list of options
    - `:wallet_address` - Viewer's wallet address (for access control)
    - `:limit` - Maximum number of HeartBits to return (default: 20)
    - `:offset` - Number of HeartBits to skip (default: 0)

  ## Examples

      iex> HeartBit.get_for_content("doc_123", wallet_address: "0x...")
      {:ok, [%{id: "heartbit_456", sender: "0x...", amount: 5, ...}, ...]}

  """
  @spec get_for_content(String.t(), keyword()) :: {:ok, [heartbit()]} | {:error, atom()}
  def get_for_content(content_id, opts \\ []) do
    wallet_address = Keyword.get(opts, :wallet_address)
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)

    if is_nil(wallet_address) do
      {:error, :wallet_required}
    else
      # Mock implementation - filter and return HeartBits for content
      heartbits =
        get_mock_heartbits()
        |> Enum.filter(&(&1.content_id == content_id))
        |> Enum.sort_by(& &1.created_at, {:desc, DateTime})
        |> Enum.drop(offset)
        |> Enum.take(limit)

      {:ok, heartbits}
    end
  end

  @doc """
  Get engagement metrics for content or user.

  ## Parameters

  - `target`: Content ID or wallet address
  - `opts`: Keyword list of options
    - `:wallet_address` - Viewer's wallet address (for access control)
    - `:time_range` - Time range for metrics (:day, :week, :month, :all)

  ## Examples

      iex> HeartBit.get_metrics("doc_123", wallet_address: "0x...")
      {:ok, %{total_heartbits: 15, unique_senders: 8, ...}}

  """
  @spec get_metrics(String.t(), keyword()) :: {:ok, engagement_metrics()} | {:error, atom()}
  def get_metrics(target, opts \\ []) do
    wallet_address = Keyword.get(opts, :wallet_address)
    time_range = Keyword.get(opts, :time_range, :all)

    if is_nil(wallet_address) do
      {:error, :wallet_required}
    else
      # Mock implementation - calculate metrics
      heartbits =
        get_mock_heartbits()
        |> filter_by_target(target)
        |> filter_by_time_range(time_range)

      metrics = %{
        total_heartbits: length(heartbits),
        unique_senders: heartbits |> Enum.map(& &1.sender) |> Enum.uniq() |> length(),
        unique_recipients: heartbits |> Enum.map(& &1.recipient) |> Enum.uniq() |> length(),
        total_amount: Enum.sum(Enum.map(heartbits, & &1.amount)),
        avg_amount: calculate_avg_amount(heartbits),
        top_content: get_top_content(heartbits),
        recent_activity:
          heartbits |> Enum.sort_by(& &1.created_at, {:desc, DateTime}) |> Enum.take(5)
      }

      {:ok, metrics}
    end
  end

  @doc """
  Get social activity feed.

  ## Parameters

  - `opts`: Keyword list of options
    - `:wallet_address` - Viewer's wallet address (required)
    - `:limit` - Maximum number of items (default: 20)
    - `:filter` - Filter by content type or sender

  ## Examples

      iex> HeartBit.get_activity_feed(wallet_address: "0x...")
      {:ok, [%{heartbit: %{...}, sender_ens: "alice.eth", ...}, ...]}

  """
  @spec get_activity_feed(keyword()) :: {:ok, [activity_feed_item()]} | {:error, atom()}
  def get_activity_feed(opts \\ []) do
    wallet_address = Keyword.get(opts, :wallet_address)
    limit = Keyword.get(opts, :limit, 20)
    filter = Keyword.get(opts, :filter)

    if is_nil(wallet_address) do
      {:error, :wallet_required}
    else
      # Mock implementation - get recent HeartBits with ENS names
      heartbits =
        get_mock_heartbits()
        |> apply_filter(filter)
        |> Enum.sort_by(& &1.created_at, {:desc, DateTime})
        |> Enum.take(limit)

      activity_items =
        Enum.map(heartbits, fn heartbit ->
          %{
            heartbit: heartbit,
            sender_ens: resolve_ens_name(heartbit.sender),
            recipient_ens: resolve_ens_name(heartbit.recipient),
            content_title: get_content_title(heartbit.content_id, heartbit.content_type),
            relative_time: format_relative_time(heartbit.created_at)
          }
        end)

      {:ok, activity_items}
    end
  end

  @doc """
  Get HeartBits sent by a specific wallet.

  ## Parameters

  - `sender_address`: Wallet address of the sender
  - `opts`: Keyword list of options
    - `:wallet_address` - Viewer's wallet address (for access control)
    - `:limit` - Maximum number of HeartBits (default: 20)

  ## Examples

      iex> HeartBit.get_sent_by("0x...", wallet_address: "0x...")
      {:ok, [%{id: "heartbit_456", recipient: "0x...", amount: 5, ...}, ...]}

  """
  @spec get_sent_by(String.t(), keyword()) :: {:ok, [heartbit()]} | {:error, atom()}
  def get_sent_by(sender_address, opts \\ []) do
    wallet_address = Keyword.get(opts, :wallet_address)
    limit = Keyword.get(opts, :limit, 20)

    if is_nil(wallet_address) do
      {:error, :wallet_required}
    else
      heartbits =
        get_mock_heartbits()
        |> Enum.filter(&(&1.sender == sender_address))
        |> Enum.sort_by(& &1.created_at, {:desc, DateTime})
        |> Enum.take(limit)

      {:ok, heartbits}
    end
  end

  # Private helper functions

  defp get_content_owner(_content_id, content_type) do
    # Mock implementation - in production would query content metadata
    case content_type do
      :document -> "0x#{:crypto.strong_rand_bytes(20) |> Base.encode16(case: :lower)}"
      :file -> "0x#{:crypto.strong_rand_bytes(20) |> Base.encode16(case: :lower)}"
      :portal -> "0x#{:crypto.strong_rand_bytes(20) |> Base.encode16(case: :lower)}"
      :sheet -> "0x#{:crypto.strong_rand_bytes(20) |> Base.encode16(case: :lower)}"
    end
  end

  defp store_heartbit(_heartbit) do
    # Mock implementation - in production would store in database
    :ok
  end

  defp get_mock_heartbits do
    # Mock data for demonstration
    [
      %{
        id: "heartbit_001",
        sender: "0x1234567890abcdef1234567890abcdef12345678",
        recipient: "0xabcdef1234567890abcdef1234567890abcdef12",
        content_id: "doc_123",
        content_type: :document,
        amount: 3,
        message: "Great work on this document!",
        created_at: DateTime.add(DateTime.utc_now(), -3600, :second),
        transaction_hash: "0xabc123def456789",
        block_number: 18_500_001
      },
      %{
        id: "heartbit_002",
        sender: "0x9876543210fedcba9876543210fedcba98765432",
        recipient: "0xabcdef1234567890abcdef1234567890abcdef12",
        content_id: "file_456",
        content_type: :file,
        amount: 1,
        message: nil,
        created_at: DateTime.add(DateTime.utc_now(), -7200, :second),
        transaction_hash: "0xdef456abc789012",
        block_number: 18_500_002
      },
      %{
        id: "heartbit_003",
        sender: "0xabcdef1234567890abcdef1234567890abcdef12",
        recipient: "0x1234567890abcdef1234567890abcdef12345678",
        content_id: "portal_789",
        content_type: :portal,
        amount: 5,
        message: "Amazing collaboration space!",
        created_at: DateTime.add(DateTime.utc_now(), -10_800, :second),
        transaction_hash: "0x789012def456abc",
        block_number: 18_500_003
      }
    ]
  end

  defp filter_by_target(heartbits, target) do
    # Check if target is a content ID or wallet address
    if String.starts_with?(target, "0x") do
      # Wallet address - filter by sender or recipient
      Enum.filter(heartbits, fn hb ->
        hb.sender == target or hb.recipient == target
      end)
    else
      # Content ID
      Enum.filter(heartbits, &(&1.content_id == target))
    end
  end

  defp filter_by_time_range(heartbits, time_range) do
    now = DateTime.utc_now()

    cutoff =
      case time_range do
        :day -> DateTime.add(now, -86_400, :second)
        :week -> DateTime.add(now, -604_800, :second)
        :month -> DateTime.add(now, -2_592_000, :second)
        :all -> DateTime.from_unix!(0)
      end

    Enum.filter(heartbits, &(DateTime.compare(&1.created_at, cutoff) == :gt))
  end

  defp calculate_avg_amount(heartbits) do
    if Enum.empty?(heartbits) do
      0.0
    else
      total = Enum.sum(Enum.map(heartbits, & &1.amount))
      total / length(heartbits)
    end
  end

  defp get_top_content(heartbits) do
    heartbits
    |> Enum.group_by(& &1.content_id)
    |> Enum.map(fn {content_id, content_heartbits} ->
      %{
        content_id: content_id,
        content_type: List.first(content_heartbits).content_type,
        title: get_content_title(content_id, List.first(content_heartbits).content_type),
        total_likes: length(content_heartbits),
        unique_likers: content_heartbits |> Enum.map(& &1.sender) |> Enum.uniq() |> length(),
        total_amount: Enum.sum(Enum.map(content_heartbits, & &1.amount)),
        last_activity: content_heartbits |> Enum.map(& &1.created_at) |> Enum.max(DateTime)
      }
    end)
    |> Enum.sort_by(& &1.total_amount, :desc)
    |> Enum.take(5)
  end

  defp apply_filter(heartbits, nil), do: heartbits

  defp apply_filter(heartbits, filter) when is_atom(filter) do
    Enum.filter(heartbits, &(&1.content_type == filter))
  end

  defp apply_filter(heartbits, filter) when is_binary(filter) do
    Enum.filter(heartbits, &(&1.sender == filter))
  end

  defp resolve_ens_name(address) do
    # Mock implementation - in production would use ENS resolution
    case address do
      "0x1234567890abcdef1234567890abcdef12345678" -> "alice.eth"
      "0x9876543210fedcba9876543210fedcba98765432" -> "bob.eth"
      "0xabcdef1234567890abcdef1234567890abcdef12" -> "charlie.eth"
      _ -> nil
    end
  end

  defp get_content_title(_content_id, content_type) do
    # Mock implementation - in production would query content metadata
    case content_type do
      :document -> "My Important Document"
      :file -> "Project Files Archive"
      :portal -> "Team Collaboration Space"
      :sheet -> "Token Analytics Sheet"
    end
  end

  defp abbreviate_address(address) do
    if String.length(address) > 10 do
      String.slice(address, 0, 6) <> "..." <> String.slice(address, -4, 4)
    else
      address
    end
  end

  defp format_relative_time(datetime) do
    now = DateTime.utc_now()
    diff_seconds = DateTime.diff(now, datetime, :second)

    cond do
      diff_seconds < 60 -> "#{diff_seconds}s ago"
      diff_seconds < 3600 -> "#{div(diff_seconds, 60)}m ago"
      diff_seconds < 86_400 -> "#{div(diff_seconds, 3600)}h ago"
      diff_seconds < 604_800 -> "#{div(diff_seconds, 86_400)}d ago"
      true -> "#{div(diff_seconds, 604_800)}w ago"
    end
  end
end
