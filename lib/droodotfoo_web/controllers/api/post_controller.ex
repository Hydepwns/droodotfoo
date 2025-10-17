defmodule DroodotfooWeb.PostController do
  @moduledoc """
  API controller for Obsidian publishing integration.
  """

  use DroodotfooWeb, :controller
  alias Droodotfoo.Content.Posts

  @doc """
  Create a new blog post from Obsidian.

  Expects JSON body with:
  - content: Markdown content (may include frontmatter)
  - metadata: Map with title, description, tags, slug (optional), date (optional)

  Requires Authorization header with bearer token matching BLOG_API_TOKEN env var.
  """
  def create(conn, params) do
    with :ok <- verify_api_token(conn),
         {:ok, post_params} <- validate_params(params),
         {:ok, post} <- Posts.save_post(post_params["content"], post_params["metadata"]) do
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
      {:error, :unauthorized} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Unauthorized"})

      {:error, :invalid_params} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid parameters. Required: content, metadata (with title)"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to save post: #{inspect(reason)}"})
    end
  end

  defp verify_api_token(conn) do
    expected_token = Application.get_env(:droodotfoo, :blog_api_token)

    if is_nil(expected_token) or expected_token == "" do
      # No token configured, allow access (dev mode)
      :ok
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
end
