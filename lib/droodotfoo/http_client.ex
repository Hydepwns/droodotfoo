defmodule Droodotfoo.HttpClient do
  @moduledoc """
  Shared HTTP client utilities for API integrations.
  Provides consistent error handling and client configuration.
  """

  require Logger

  @doc """
  Creates a new Req HTTP client with common configuration.

  ## Options
  - `:base_url` - Base URL for all requests
  - `:headers` - List of headers to include
  - `:retry` - Retry strategy (default: `:transient`)
  - `:max_retries` - Maximum retry attempts (default: 2)
  - `:timeout` - Request timeout in milliseconds (default: 10_000)
  """
  def new(base_url, headers, opts \\ []) do
    # Extract known options and remove them from opts to avoid passing unknown keys to Req
    timeout = Keyword.get(opts, :timeout, 10_000)
    retry = Keyword.get(opts, :retry, :transient)
    max_retries = Keyword.get(opts, :max_retries, 2)

    # Remove options we've already extracted to avoid duplication
    remaining_opts = Keyword.drop(opts, [:timeout, :retry, :max_retries])

    Req.new(
      [
        base_url: base_url,
        headers: headers,
        retry: retry,
        max_retries: max_retries,
        receive_timeout: timeout
      ] ++ remaining_opts
    )
  end

  @doc """
  Makes an HTTP request with standardized error handling.

  Returns `{:ok, response}` for successful requests (2xx status codes).
  Returns `{:error, reason}` for failures with consistent error atoms.

  ## Error Reasons
  - `:unauthorized` - 401 status
  - `:forbidden` or `:rate_limited` - 403 status
  - `:not_found` - 404 status
  - `:rate_limited` - 429 status
  - `:api_error` - Other HTTP errors
  - `:request_failed` - Network/connection errors
  """
  def request(client, opts) do
    case Req.request(client, opts) do
      {:ok, %{status: status} = response} when status in 200..299 ->
        {:ok, response}

      {:ok, %{status: 401}} ->
        Logger.warning("HTTP 401: Unauthorized")
        {:error, :unauthorized}

      {:ok, %{status: 403}} ->
        Logger.warning("HTTP 403: Forbidden/Rate Limited")
        {:error, :rate_limited}

      {:ok, %{status: 404}} ->
        Logger.warning("HTTP 404: Not Found")
        {:error, :not_found}

      {:ok, %{status: 429}} ->
        Logger.warning("HTTP 429: Rate Limited")
        {:error, :rate_limited}

      {:ok, %{status: status}} ->
        Logger.error("HTTP #{status}: API error")
        {:error, :api_error}

      {:error, reason} ->
        Logger.error("HTTP request failed: #{inspect(reason)}")
        {:error, :request_failed}
    end
  end

  @doc """
  Makes a GET request with error handling.
  """
  def get(client, path, opts \\ []) do
    request(client, [method: :get, url: path] ++ opts)
  end

  @doc """
  Makes a POST request with error handling.
  """
  def post(client, path, body, opts \\ []) do
    request(client, [method: :post, url: path, json: body] ++ opts)
  end

  @doc """
  Makes a PUT request with error handling.
  """
  def put(client, path, body, opts \\ []) do
    request(client, [method: :put, url: path, json: body] ++ opts)
  end

  @doc """
  Makes a DELETE request with error handling.
  """
  def delete(client, path, opts \\ []) do
    request(client, [method: :delete, url: path] ++ opts)
  end
end
