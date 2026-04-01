defmodule Droodotfoo.Fileverse.HeartBitTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Fileverse.HeartBit

  describe "send/2" do
    test "sends HeartBit with valid parameters" do
      wallet_address = "0x1234567890abcdef1234567890abcdef12345678"
      content_id = "doc_123"

      assert {:ok, heartbit} = HeartBit.send(content_id, wallet_address: wallet_address)

      assert heartbit.sender == wallet_address
      assert heartbit.content_id == content_id
      assert heartbit.amount == 1
      assert is_binary(heartbit.id)
      assert is_binary(heartbit.transaction_hash)
      assert is_integer(heartbit.block_number)
    end

    test "sends HeartBit with custom amount and message" do
      wallet_address = "0x1234567890abcdef1234567890abcdef12345678"
      content_id = "doc_123"
      amount = 5
      message = "Great work!"

      assert {:ok, heartbit} =
               HeartBit.send(content_id,
                 wallet_address: wallet_address,
                 amount: amount,
                 message: message
               )

      assert heartbit.amount == amount
      assert heartbit.message == message
    end

    test "returns error when wallet address is missing" do
      content_id = "doc_123"

      assert {:error, :wallet_required} = HeartBit.send(content_id)
    end
  end

  describe "get_for_content/2" do
    test "returns HeartBits for content" do
      wallet_address = "0x1234567890abcdef1234567890abcdef12345678"
      content_id = "doc_123"

      assert {:ok, heartbits} =
               HeartBit.get_for_content(content_id, wallet_address: wallet_address)

      assert is_list(heartbits)
    end

    test "returns error when wallet address is missing" do
      content_id = "doc_123"

      assert {:error, :wallet_required} = HeartBit.get_for_content(content_id)
    end
  end

  describe "get_metrics/2" do
    test "returns engagement metrics for content" do
      wallet_address = "0x1234567890abcdef1234567890abcdef12345678"
      content_id = "doc_123"

      assert {:ok, metrics} = HeartBit.get_metrics(content_id, wallet_address: wallet_address)

      assert is_integer(metrics.total_heartbits)
      assert is_integer(metrics.unique_senders)
      assert is_integer(metrics.unique_recipients)
      assert is_integer(metrics.total_amount)
      assert is_float(metrics.avg_amount)
      assert is_list(metrics.top_content)
      assert is_list(metrics.recent_activity)
    end

    test "returns error when wallet address is missing" do
      content_id = "doc_123"

      assert {:error, :wallet_required} = HeartBit.get_metrics(content_id)
    end
  end

  describe "get_activity_feed/1" do
    test "returns social activity feed" do
      wallet_address = "0x1234567890abcdef1234567890abcdef12345678"

      assert {:ok, activity_items} = HeartBit.get_activity_feed(wallet_address: wallet_address)
      assert is_list(activity_items)

      if not Enum.empty?(activity_items) do
        item = List.first(activity_items)
        assert Map.has_key?(item, :heartbit)
        assert Map.has_key?(item, :sender_ens)
        assert Map.has_key?(item, :recipient_ens)
        assert Map.has_key?(item, :content_title)
        assert Map.has_key?(item, :relative_time)
      end
    end

    test "returns error when wallet address is missing" do
      assert {:error, :wallet_required} = HeartBit.get_activity_feed()
    end
  end

  describe "get_sent_by/2" do
    test "returns HeartBits sent by wallet" do
      wallet_address = "0x1234567890abcdef1234567890abcdef12345678"
      sender_address = "0x1234567890abcdef1234567890abcdef12345678"

      assert {:ok, heartbits} =
               HeartBit.get_sent_by(sender_address, wallet_address: wallet_address)

      assert is_list(heartbits)
    end

    test "returns error when wallet address is missing" do
      sender_address = "0x1234567890abcdef1234567890abcdef12345678"

      assert {:error, :wallet_required} = HeartBit.get_sent_by(sender_address)
    end
  end
end
