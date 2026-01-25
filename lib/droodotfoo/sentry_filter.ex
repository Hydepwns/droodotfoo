defmodule Droodotfoo.SentryFilter do
  @moduledoc """
  Filters and modifies Sentry events before they are sent.

  This module filters out noisy or unactionable errors to reduce
  Sentry quota usage and keep the error stream clean.
  """

  require Logger

  @doc """
  Filter function called before sending events to Sentry.

  Returns the event to send it, or nil to drop it.
  """
  @spec filter_event(Sentry.Event.t()) :: Sentry.Event.t() | nil
  def filter_event(event) do
    cond do
      # Filter out common browser/bot noise
      ignored_exception?(event) -> nil
      ignored_user_agent?(event) -> nil
      # Allow all other events
      true -> event
    end
  end

  # Exceptions that are not actionable (client errors, bots, etc.)
  defp ignored_exception?(%{exception: exceptions}) when is_list(exceptions) do
    Enum.any?(exceptions, fn ex ->
      type = Map.get(ex, :type, "")
      value = Map.get(ex, :value, "")

      # Common non-actionable exceptions
      type in [
        "Phoenix.Router.NoRouteError",
        "Plug.Conn.InvalidQueryError"
      ] or
        # Bot probing for vulnerabilities
        String.contains?(value, [
          ".php",
          ".asp",
          ".env",
          "wp-admin",
          "wp-login",
          "xmlrpc"
        ])
    end)
  end

  defp ignored_exception?(_), do: false

  # Filter out known bot user agents
  defp ignored_user_agent?(%{request: %{headers: headers}}) when is_map(headers) do
    user_agent = Map.get(headers, "user-agent", "") |> String.downcase()

    bot_patterns = [
      "bot",
      "crawler",
      "spider",
      "scan",
      "python-requests",
      "curl/",
      "wget/"
    ]

    Enum.any?(bot_patterns, &String.contains?(user_agent, &1))
  end

  defp ignored_user_agent?(_), do: false
end
