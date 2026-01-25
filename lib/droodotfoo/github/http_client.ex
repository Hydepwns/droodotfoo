defmodule Droodotfoo.GitHub.HttpClient do
  @moduledoc """
  HTTP client for GitHub API with retry logic and status handling.
  """

  require Logger

  alias Droodotfoo.ErrorSanitizer

  @github_rest_api_url "https://api.github.com"
  @github_graphql_url "https://api.github.com/graphql"
  @max_retries 3

  @doc """
  Make a REST API request with retry logic.
  """
  def rest_request(path, opts \\ []) do
    url = @github_rest_api_url <> path
    headers = build_rest_headers()
    retry_count = Keyword.get(opts, :retry_count, 0)

    case Req.get(url, headers: headers) do
      {:ok, %{status: status}}
      when status in [500, 502, 503, 504] and retry_count < @max_retries ->
        retry_with_backoff(
          fn -> rest_request(path, retry_count: retry_count + 1) end,
          retry_count,
          status
        )

      response ->
        response
    end
  rescue
    error ->
      handle_request_error(
        error,
        fn -> rest_request(path, retry_count: opts[:retry_count] || 0 + 1) end,
        opts[:retry_count] || 0
      )
  end

  @doc """
  Make a GraphQL API request.
  """
  def graphql_request(query) do
    case github_token() do
      token when token in [nil, ""] ->
        {:error, :no_token}

      token ->
        do_graphql_request(query, token)
    end
  end

  @doc """
  Handle HTTP response status codes uniformly.
  """
  def handle_response({:ok, %{status: 200, body: body}}, parser) when is_function(parser, 1) do
    {:ok, parser.(body)}
  end

  def handle_response({:ok, %{status: 200, body: body}}, :raw) do
    {:ok, body}
  end

  def handle_response({:ok, %{status: 401}}, _parser), do: {:error, :unauthorized}
  def handle_response({:ok, %{status: 403}}, _parser), do: {:error, :rate_limited}
  def handle_response({:ok, %{status: 404}}, _parser), do: {:error, :not_found}

  def handle_response({:ok, %{status: status}}, _parser) do
    Logger.error("GitHub API returned unexpected status: #{status}")
    {:error, {:unexpected_status, status}}
  end

  def handle_response({:error, reason}, _parser) do
    Logger.error("GitHub API request failed: #{ErrorSanitizer.sanitize(reason)}")
    {:error, reason}
  end

  @doc """
  Handle empty list response specifically.
  """
  def handle_list_response({:ok, %{status: 200, body: []}}, _parser), do: {:error, :empty}

  def handle_list_response({:ok, %{status: 200, body: [first | _]}}, parser),
    do: {:ok, parser.(first)}

  def handle_list_response(response, _parser), do: handle_response(response, :raw)

  # Private

  defp build_rest_headers do
    base = [
      {"accept", "application/vnd.github.v3+json"},
      {"user-agent", "droodotfoo"}
    ]

    case github_token() do
      token when token in [nil, ""] -> base
      token -> [{"authorization", "Bearer #{token}"} | base]
    end
  end

  defp do_graphql_request(query, token) do
    headers = [
      {~c"Content-Type", ~c"application/json"},
      {~c"User-Agent", ~c"droo.foo-terminal"},
      {~c"Authorization", String.to_charlist("Bearer #{token}")}
    ]

    body = Jason.encode!(%{query: query})

    case :httpc.request(
           :post,
           {String.to_charlist(@github_graphql_url), headers, ~c"application/json",
            String.to_charlist(body)},
           [],
           []
         ) do
      {:ok, {{_, 200, _}, _headers, response_body}} ->
        {:ok, List.to_string(response_body)}

      {:ok, {{_, status, _}, _headers, _response_body}} ->
        Logger.error("GitHub GraphQL API returned status #{status}")
        {:error, "GitHub API error: #{status}"}

      {:error, reason} ->
        {:error, "HTTP request failed: #{ErrorSanitizer.sanitize(reason)}"}
    end
  end

  defp github_token do
    case System.get_env("GITHUB_TOKEN") do
      token when token not in [nil, ""] -> token
      _ -> Application.get_env(:droodotfoo, :github_token)
    end
  end

  defp retry_with_backoff(retry_fn, retry_count, status) do
    backoff_ms = (:math.pow(2, retry_count) * 1000) |> round()

    Logger.warning(
      "GitHub API returned #{status}, retrying in #{backoff_ms}ms (attempt #{retry_count + 1}/#{@max_retries})"
    )

    Process.sleep(backoff_ms)
    retry_fn.()
  end

  defp handle_request_error(error, retry_fn, retry_count) do
    if retry_count < @max_retries do
      backoff_ms = (:math.pow(2, retry_count) * 1000) |> round()

      Logger.warning(
        "GitHub request failed: #{inspect(error)}, retrying in #{backoff_ms}ms (attempt #{retry_count + 1}/#{@max_retries})"
      )

      Process.sleep(backoff_ms)
      retry_fn.()
    else
      Logger.error("GitHub request failed after #{retry_count} retries: #{inspect(error)}")
      {:error, :request_failed}
    end
  end
end
