defmodule Droodotfoo.Web3.IPFS do
  @moduledoc """
  IPFS gateway integration for fetching and rendering decentralized content.

  Supports multiple public gateways with automatic fallback.
  """

  require Logger

  @type cid :: String.t()
  @type content :: %{
          cid: String.t(),
          content_type: String.t(),
          size: integer(),
          data: binary() | String.t(),
          gateway: String.t()
        }

  @type directory_entry :: %{
          name: String.t(),
          type: :file | :directory,
          size: integer() | nil,
          cid: String.t()
        }

  # Public IPFS gateways (no API key required)
  @gateways [
    "https://cloudflare-ipfs.com/ipfs/",
    "https://ipfs.io/ipfs/",
    "https://gateway.pinata.cloud/ipfs/",
    "https://dweb.link/ipfs/"
  ]

  # Maximum content size to fetch (10MB)
  @max_content_size 10_485_760

  @doc """
  Fetch content from IPFS by CID.

  ## Parameters

  - `cid`: IPFS Content Identifier (CIDv0 or CIDv1)
  - `opts`: Keyword list of options
    - `:gateway` - Specific gateway URL to use
    - `:timeout` - Request timeout in milliseconds (default: 30_000)

  ## Examples

      iex> Droodotfoo.Web3.IPFS.cat("QmHash...")
      {:ok, %{cid: "QmHash...", content_type: "text/plain", data: "..."}}

  """
  @spec cat(cid(), keyword()) :: {:ok, content()} | {:error, atom()}
  def cat(cid, opts \\ []) do
    if valid_cid?(cid) do
      gateway = Keyword.get(opts, :gateway)
      timeout = Keyword.get(opts, :timeout, 30_000)

      fetch_with_fallback(cid, gateway, timeout)
    else
      {:error, :invalid_cid}
    end
  end

  @doc """
  List directory contents from IPFS CID.

  ## Examples

      iex> Droodotfoo.Web3.IPFS.ls("QmHash...")
      {:ok, [%{name: "file.txt", type: :file, size: 1024, cid: "QmHash..."}]}

  """
  @spec ls(cid(), keyword()) :: {:ok, [directory_entry()]} | {:error, atom()}
  def ls(cid, _opts \\ []) do
    if valid_cid?(cid) do
      # For now, return error - full directory listing requires IPFS API
      # This would normally use /api/v0/ls endpoint
      {:error, :not_implemented}
    else
      {:error, :invalid_cid}
    end
  end

  @doc """
  Get metadata about IPFS content without downloading it.

  ## Examples

      iex> Droodotfoo.Web3.IPFS.stat("QmHash...")
      {:ok, %{cid: "QmHash...", size: 1024, type: "text/plain"}}

  """
  @spec stat(cid()) :: {:ok, map()} | {:error, atom()}
  def stat(cid) do
    if valid_cid?(cid) do
      # For now, we'd need to fetch headers only
      # This would use HEAD request to gateway
      {:error, :not_implemented}
    else
      {:error, :invalid_cid}
    end
  end

  @doc """
  Generate gateway URL for a CID.

  ## Examples

      iex> Droodotfoo.Web3.IPFS.gateway_url("QmHash...")
      "https://cloudflare-ipfs.com/ipfs/QmHash..."

  """
  @spec gateway_url(cid(), String.t() | nil) :: String.t()
  def gateway_url(cid, gateway \\ nil) do
    base = gateway || List.first(@gateways)
    "#{base}#{cid}"
  end

  @doc """
  Validate IPFS CID format.

  Supports both CIDv0 (Qm...) and CIDv1 (b...).

  ## Examples

      iex> Droodotfoo.Web3.IPFS.valid_cid?("QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG")
      true

  """
  @spec valid_cid?(String.t()) :: boolean()
  def valid_cid?(cid) when is_binary(cid) do
    # CIDv0: Qm followed by 44 base58 characters
    # CIDv1: b followed by base32/base58 characters
    cond do
      String.match?(cid, ~r/^Qm[1-9A-HJ-NP-Za-km-z]{44}$/) -> true
      String.match?(cid, ~r/^b[a-z2-7]{58,}$/) -> true
      String.match?(cid, ~r/^bafy[a-z2-7]{50,}$/) -> true
      true -> false
    end
  end

  def valid_cid?(_), do: false

  @doc """
  Format content for terminal display.

  Handles text, JSON, and binary content with appropriate formatting.
  """
  @spec format_content(content(), keyword()) :: String.t()
  def format_content(content, opts \\ []) do
    max_lines = Keyword.get(opts, :max_lines, 50)

    case content.content_type do
      "application/json" ->
        format_json(content.data, max_lines)

      "text/" <> _ ->
        format_text(content.data, max_lines)

      "image/" <> _ ->
        format_image_info(content)

      _ ->
        format_binary_info(content)
    end
  end

  ## Private Functions

  defp fetch_with_fallback(cid, nil, timeout) do
    # Try all gateways until one succeeds
    Enum.reduce_while(@gateways, {:error, :all_gateways_failed}, fn gateway, _acc ->
      case fetch_from_gateway(cid, gateway, timeout) do
        {:ok, content} -> {:halt, {:ok, content}}
        {:error, _} -> {:cont, {:error, :all_gateways_failed}}
      end
    end)
  end

  defp fetch_with_fallback(cid, gateway, timeout) do
    fetch_from_gateway(cid, gateway, timeout)
  end

  defp fetch_from_gateway(cid, gateway, timeout) do
    url = "#{gateway}#{cid}"

    case http_get(url, timeout) do
      {:ok, {content_type, body}} ->
        {:ok,
         %{
           cid: cid,
           content_type: content_type,
           size: byte_size(body),
           data: body,
           gateway: gateway
         }}

      {:error, reason} ->
        Logger.debug("Failed to fetch from #{gateway}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp http_get(url, timeout) do
    # Use consolidated HttpClient for consistent error handling
    client =
      Droodotfoo.HttpClient.new(
        url,
        [
          {"Accept", "application/octet-stream, text/plain, application/json, */*"}
        ],
        timeout: timeout
      )

    case Droodotfoo.HttpClient.get(client, "") do
      {:ok, %{body: body, headers: response_headers}} ->
        # Check content size
        if byte_size(body) > @max_content_size do
          {:error, :content_too_large}
        else
          content_type = get_content_type(response_headers)
          {:ok, {content_type, body}}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp get_content_type(headers) do
    case List.keyfind(headers, ~c"content-type", 0) do
      {~c"content-type", content_type} ->
        content_type
        |> to_string()
        |> String.split(";")
        |> List.first()
        |> String.trim()

      nil ->
        "application/octet-stream"
    end
  end

  defp format_json(data, max_lines) when is_binary(data) do
    case Jason.decode(data) do
      {:ok, json} ->
        formatted =
          json
          |> Jason.encode!(pretty: true)
          |> String.split("\n")
          |> Enum.take(max_lines)
          |> Enum.join("\n")

        if String.split(data, "\n") |> length() > max_lines do
          formatted <> "\n\n... (truncated)"
        else
          formatted
        end

      {:error, _} ->
        format_text(data, max_lines)
    end
  end

  defp format_json(data, _max_lines), do: inspect(data)

  defp format_text(data, max_lines) when is_binary(data) do
    lines = String.split(data, "\n")
    line_count = length(lines)

    formatted =
      lines
      |> Enum.take(max_lines)
      |> Enum.join("\n")

    if line_count > max_lines do
      formatted <> "\n\n... (#{line_count - max_lines} more lines)"
    else
      formatted
    end
  end

  defp format_text(data, _max_lines), do: inspect(data)

  defp format_image_info(content) do
    """
    [Image File]
    Type: #{content.content_type}
    Size: #{format_bytes(content.size)}
    Gateway URL: #{gateway_url(content.cid, content.gateway)}

    Note: Image display not supported in terminal mode.
    Open the gateway URL in a browser to view.
    """
  end

  defp format_binary_info(content) do
    """
    [Binary Content]
    Type: #{content.content_type}
    Size: #{format_bytes(content.size)}
    Gateway URL: #{gateway_url(content.cid, content.gateway)}

    Binary content cannot be displayed in terminal.
    """
  end

  defp format_bytes(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_bytes(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 2)} KB"

  defp format_bytes(bytes) when bytes < 1_073_741_824,
    do: "#{Float.round(bytes / 1_048_576, 2)} MB"

  defp format_bytes(bytes), do: "#{Float.round(bytes / 1_073_741_824, 2)} GB"
end
