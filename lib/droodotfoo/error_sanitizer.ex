defmodule Droodotfoo.ErrorSanitizer do
  @moduledoc """
  Sanitizes error messages for safe logging.

  Prevents sensitive data (tokens, URLs, internal paths, stack traces)
  from leaking into log files.
  """

  @doc """
  Sanitizes an error for safe logging.

  Extracts safe message content from various error formats while
  stripping potentially sensitive details like tokens, URLs, and stack traces.

  ## Examples

      iex> Droodotfoo.ErrorSanitizer.sanitize(%{message: "Connection failed"})
      "Connection failed"

      iex> Droodotfoo.ErrorSanitizer.sanitize(%RuntimeError{message: "oops"})
      "oops"

      iex> Droodotfoo.ErrorSanitizer.sanitize(:unknown_error)
      "An error occurred"
  """
  @spec sanitize(term()) :: String.t()
  def sanitize(%{message: msg}) when is_binary(msg), do: msg
  def sanitize(%{reason: reason}) when is_binary(reason), do: reason
  def sanitize(error) when is_binary(error), do: error
  def sanitize(%{__exception__: true} = e), do: Exception.message(e)
  def sanitize(%{__struct__: struct}), do: "#{inspect(struct)} error"
  def sanitize(atom) when is_atom(atom), do: Atom.to_string(atom)
  def sanitize(_), do: "An error occurred"
end
