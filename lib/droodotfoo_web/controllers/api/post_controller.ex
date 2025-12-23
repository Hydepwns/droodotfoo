defmodule DroodotfooWeb.PostController do
  @moduledoc """
  API controller for Obsidian publishing integration.
  """

  use DroodotfooWeb, :controller
  require Logger
  alias Droodotfoo.Content.PostRateLimiter
  alias Droodotfoo.Content.Posts

  @doc """
  Create a new blog post from Obsidian.

  Expects JSON body with:
  - content: Markdown content (may include frontmatter)
  - metadata: Map with title, description, tags, slug (optional), date (optional)

  Requires Authorization header with bearer token matching BLOG_API_TOKEN env var.
  Rate limited to 10 posts/hour, 50 posts/day per IP.
  """
  def create(conn, params) do
    ip_address = get_ip_address(conn)

    with {:ok, :allowed} <- PostRateLimiter.check_rate_limit(ip_address),
         :ok <- verify_api_token(conn),
         {:ok, post_params} <- validate_params(params),
         {:ok, post} <- Posts.save_post(post_params["content"], post_params["metadata"]) do
      PostRateLimiter.record_submission(ip_address)

      conn
      |> put_status(:created)
      |> json(%{
        success: true,
        post: %{
          slug: post.slug,
          title: post.title,
          url: url(~p"/posts/#{post.slug}")
        }
      })
    else
      {:error, rate_limit_msg} when is_binary(rate_limit_msg) ->
        conn
        |> put_status(:too_many_requests)
        |> json(%{error: rate_limit_msg})

      {:error, :unauthorized} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized"})

      {:error, :invalid_params} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid parameters. Required: content, metadata (with title)"})

      {:error, reason} ->
        # Log detailed error internally, return generic message to client
        Logger.error("Post creation failed: #{inspect(reason)}")

        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to save post. Please try again."})
    end
  end

  defp verify_api_token(conn) do
    expected_token = Application.get_env(:droodotfoo, :blog_api_token)

    if is_nil(expected_token) or expected_token == "" do
      # Token MUST be configured - no bypass allowed
      {:error, :unauthorized}
    else
      verify_bearer_token(conn, expected_token)
    end
  end

  defp verify_bearer_token(conn, expected_token) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        if Plug.Crypto.secure_compare(token, expected_token) do
          :ok
        else
          {:error, :unauthorized}
        end

      _ ->
        {:error, :unauthorized}
    end
  end

  defp validate_params(%{"content" => content, "metadata" => metadata})
       when is_binary(content) and is_map(metadata) do
    if Map.has_key?(metadata, "title") do
      {:ok, %{"content" => content, "metadata" => metadata}}
    else
      {:error, :invalid_params}
    end
  end

  defp validate_params(_), do: {:error, :invalid_params}

  defp get_ip_address(conn) do
    # Fly.io sets Fly-Client-IP with verified client IP (can't be spoofed)
    # This prevents IP spoofing via X-Forwarded-For header manipulation
    case get_req_header(conn, "fly-client-ip") do
      [ip | _] ->
        ip |> String.trim()

      [] ->
        # Fallback to X-Forwarded-For (take rightmost IP as it's most trusted)
        # Note: This is less secure than Fly-Client-IP
        case get_req_header(conn, "x-forwarded-for") do
          [ips] ->
            ips
            |> String.split(",")
            |> List.last()
            |> String.trim()

          [] ->
            # Final fallback to remote_ip
            conn.remote_ip |> :inet.ntoa() |> to_string()
        end
    end
  end
end
