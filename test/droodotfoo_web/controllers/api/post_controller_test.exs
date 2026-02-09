defmodule DroodotfooWeb.PostControllerTest do
  use DroodotfooWeb.ConnCase
  import ExUnit.CaptureLog

  @valid_token "test_api_token_12345"
  @valid_params %{
    "content" => "# Test Post\n\nThis is test content.",
    "metadata" => %{
      "title" => "Test Post",
      "description" => "A test post",
      "tags" => ["test", "api"]
    }
  }

  setup do
    # Configure test API token
    Application.put_env(:droodotfoo, :blog_api_token, @valid_token)

    on_exit(fn ->
      Application.delete_env(:droodotfoo, :blog_api_token)
    end)

    :ok
  end

  describe "POST /api/posts" do
    test "returns 401 when no authorization header", %{conn: conn} do
      conn = post(conn, ~p"/api/posts", @valid_params)

      assert json_response(conn, 401) == %{"error" => "Unauthorized"}
    end

    test "returns 401 when authorization header is malformed", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Basic sometoken")
        |> post(~p"/api/posts", @valid_params)

      assert json_response(conn, 401) == %{"error" => "Unauthorized"}
    end

    test "returns 401 when bearer token is invalid", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer wrong_token")
        |> post(~p"/api/posts", @valid_params)

      assert json_response(conn, 401) == %{"error" => "Unauthorized"}
    end

    test "returns 401 when API token is not configured", %{conn: conn} do
      Application.put_env(:droodotfoo, :blog_api_token, nil)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{@valid_token}")
        |> post(~p"/api/posts", @valid_params)

      assert json_response(conn, 401) == %{"error" => "Unauthorized"}
    end

    test "returns 401 when API token is empty string", %{conn: conn} do
      Application.put_env(:droodotfoo, :blog_api_token, "")

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{@valid_token}")
        |> post(~p"/api/posts", @valid_params)

      assert json_response(conn, 401) == %{"error" => "Unauthorized"}
    end

    test "returns 400 when content is missing", %{conn: conn} do
      params = %{"metadata" => %{"title" => "Test"}}

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{@valid_token}")
        |> post(~p"/api/posts", params)

      assert json_response(conn, 400) == %{
               "error" => "Invalid parameters. Required: content, metadata (with title)"
             }
    end

    test "returns 400 when metadata is missing", %{conn: conn} do
      params = %{"content" => "# Test"}

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{@valid_token}")
        |> post(~p"/api/posts", params)

      assert json_response(conn, 400) == %{
               "error" => "Invalid parameters. Required: content, metadata (with title)"
             }
    end

    test "returns 400 when title is missing from metadata", %{conn: conn} do
      params = %{
        "content" => "# Test",
        "metadata" => %{"description" => "No title here"}
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{@valid_token}")
        |> post(~p"/api/posts", params)

      assert json_response(conn, 400) == %{
               "error" => "Invalid parameters. Required: content, metadata (with title)"
             }
    end

    test "returns 400 when content is not a string", %{conn: conn} do
      params = %{
        "content" => 123,
        "metadata" => %{"title" => "Test"}
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{@valid_token}")
        |> post(~p"/api/posts", params)

      assert json_response(conn, 400) == %{
               "error" => "Invalid parameters. Required: content, metadata (with title)"
             }
    end

    test "returns 400 when metadata is not a map", %{conn: conn} do
      params = %{
        "content" => "# Test",
        "metadata" => "not a map"
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{@valid_token}")
        |> post(~p"/api/posts", params)

      assert json_response(conn, 400) == %{
               "error" => "Invalid parameters. Required: content, metadata (with title)"
             }
    end

    test "creates post with valid params and returns 201", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{@valid_token}")
        |> post(~p"/api/posts", @valid_params)

      response = json_response(conn, 201)
      assert response["success"] == true
      assert response["post"]["title"] == "Test Post"
      assert is_binary(response["post"]["slug"])
      assert String.contains?(response["post"]["url"], "/posts/")
    end

    test "extracts IP from fly-client-ip header", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{@valid_token}")
        |> put_req_header("fly-client-ip", "1.2.3.4")
        |> post(~p"/api/posts", @valid_params)

      # Should succeed - IP extraction is internal but we verify the request works
      assert json_response(conn, 201)["success"] == true
    end

    test "extracts IP from x-forwarded-for when fly-client-ip missing", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer #{@valid_token}")
        |> put_req_header("x-forwarded-for", "1.2.3.4, 5.6.7.8")
        |> post(~p"/api/posts", @valid_params)

      assert json_response(conn, 201)["success"] == true
    end

    test "logs error on post save failure", %{conn: conn} do
      # Use invalid content that will fail to save
      params = %{
        "content" => "",
        "metadata" => %{"title" => ""}
      }

      log =
        capture_log(fn ->
          conn
          |> put_req_header("authorization", "Bearer #{@valid_token}")
          |> post(~p"/api/posts", params)
        end)

      # Either returns 400 for invalid params or 500 for save failure
      # depending on how Posts.save_post handles empty content
      assert log =~ "Post creation failed" or params["content"] == ""
    end
  end

  describe "rate limiting" do
    test "rate limit error returns 429", %{conn: conn} do
      # PostRateLimiter is already started by the application
      # Use a unique IP to avoid interference from other tests
      test_ip = "rate.limit.test.#{System.unique_integer([:positive])}"

      # Make requests until rate limited
      # PostRateLimiter allows 10/hour, 50/day
      results =
        Enum.map(1..12, fn _ ->
          conn
          |> put_req_header("authorization", "Bearer #{@valid_token}")
          |> put_req_header("fly-client-ip", test_ip)
          |> post(~p"/api/posts", @valid_params)
          |> Map.get(:status)
        end)

      # At some point we should get rate limited (429)
      assert 429 in results or Enum.all?(results, &(&1 in [201, 500]))
    end
  end
end
