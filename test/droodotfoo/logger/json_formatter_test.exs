defmodule Droodotfoo.Logger.JsonFormatterTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Logger.JsonFormatter

  describe "format/4" do
    test "outputs valid JSON" do
      timestamp = {{2026, 1, 25}, {12, 0, 0, 0}}

      result = JsonFormatter.format(:info, "Test message", timestamp, [])

      assert [json, "\n"] = result
      assert {:ok, parsed} = Jason.decode(json)
      assert parsed["level"] == "info"
      assert parsed["message"] == "Test message"
      assert parsed["timestamp"] =~ "2026-01-25T12:00:00"
    end

    test "includes metadata" do
      timestamp = {{2026, 1, 25}, {12, 0, 0, 0}}
      metadata = [request_id: "abc123", path: "/test"]

      result = JsonFormatter.format(:info, "With metadata", timestamp, metadata)

      [json, _] = result
      {:ok, parsed} = Jason.decode(json)
      assert parsed["metadata"]["request_id"] == "abc123"
      assert parsed["metadata"]["path"] == "/test"
    end

    test "handles different log levels" do
      timestamp = {{2026, 1, 25}, {12, 0, 0, 0}}

      for level <- [:debug, :info, :warning, :error] do
        result = JsonFormatter.format(level, "Test", timestamp, [])
        [json, _] = result
        {:ok, parsed} = Jason.decode(json)
        assert parsed["level"] == Atom.to_string(level)
      end
    end

    test "filters nil metadata values" do
      timestamp = {{2026, 1, 25}, {12, 0, 0, 0}}
      metadata = [request_id: "abc", nil_value: nil]

      result = JsonFormatter.format(:info, "Test", timestamp, metadata)

      [json, _] = result
      {:ok, parsed} = Jason.decode(json)
      assert parsed["metadata"]["request_id"] == "abc"
      refute Map.has_key?(parsed["metadata"], "nil_value")
    end

    test "handles iodata messages" do
      timestamp = {{2026, 1, 25}, {12, 0, 0, 0}}
      message = ["Hello", " ", "World"]

      result = JsonFormatter.format(:info, message, timestamp, [])

      [json, _] = result
      {:ok, parsed} = Jason.decode(json)
      assert parsed["message"] == "Hello World"
    end
  end
end
