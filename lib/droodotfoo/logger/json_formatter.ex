defmodule Droodotfoo.Logger.JsonFormatter do
  @moduledoc """
  JSON log formatter for production environments.

  Outputs structured JSON logs that are easier to parse in log aggregators
  like Fly.io logs, Datadog, or CloudWatch.

  ## Configuration

  In config/prod.exs or config/runtime.exs:

      config :logger, :default_handler,
        formatter: {Droodotfoo.Logger.JsonFormatter, []}

  ## Output Format

      {"timestamp":"2026-01-25T12:00:00.000Z","level":"info","message":"Request completed","metadata":{"request_id":"abc123"}}

  """

  @doc """
  Formats a log message as JSON.
  """
  def format(level, message, timestamp, metadata) do
    json =
      %{
        timestamp: format_timestamp(timestamp),
        level: level,
        message: IO.iodata_to_binary(message)
      }
      |> add_metadata(metadata)
      |> Jason.encode!()

    [json, "\n"]
  rescue
    e ->
      # Fallback to basic format if JSON encoding fails
      "#{format_timestamp(timestamp)} [#{level}] #{message} (JSON format error: #{inspect(e)})\n"
  end

  defp format_timestamp({date, {hour, minute, second, micro}}) do
    {year, month, day} = date

    NaiveDateTime.new!(year, month, day, hour, minute, second, micro * 1000)
    |> DateTime.from_naive!("Etc/UTC")
    |> DateTime.to_iso8601()
  end

  defp add_metadata(json, []), do: json

  defp add_metadata(json, metadata) do
    # Filter out nil values and convert to map
    filtered =
      metadata
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Enum.map(fn {k, v} -> {k, format_value(v)} end)
      |> Map.new()

    if map_size(filtered) > 0 do
      Map.put(json, :metadata, filtered)
    else
      json
    end
  end

  defp format_value(v) when is_binary(v), do: v
  defp format_value(v) when is_atom(v), do: Atom.to_string(v)
  defp format_value(v) when is_number(v), do: v
  defp format_value(v) when is_list(v), do: Enum.map(v, &format_value/1)
  defp format_value(v) when is_map(v), do: Map.new(v, fn {k, val} -> {k, format_value(val)} end)
  defp format_value(v), do: inspect(v)
end
