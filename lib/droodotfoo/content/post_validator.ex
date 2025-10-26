defmodule Droodotfoo.Content.PostValidator do
  @moduledoc """
  Validation for blog post content and metadata.
  Prevents malicious input, path traversal, and oversized content.
  """

  @max_content_size 1_048_576
  @max_title_length 200
  @max_description_length 500
  @max_tag_count 20
  @max_tag_length 50

  @doc """
  Validates post content and metadata before saving.

  Returns {:ok, sanitized_params} or {:error, reason}.
  """
  def validate(content, metadata) when is_binary(content) and is_map(metadata) do
    with :ok <- validate_content_size(content),
         :ok <- validate_title(metadata),
         {:ok, sanitized_metadata} <- validate_and_sanitize_metadata(metadata) do
      {:ok, content, sanitized_metadata}
    end
  end

  def validate(_content, _metadata), do: {:error, "Invalid parameters"}

  defp validate_content_size(content) do
    size = byte_size(content)

    if size > @max_content_size do
      {:error, "Content too large: #{size} bytes (max #{@max_content_size})"}
    else
      :ok
    end
  end

  defp validate_title(%{"title" => title}) when is_binary(title) and title != "" do
    if String.length(title) > @max_title_length do
      {:error, "Title too long (max #{@max_title_length} characters)"}
    else
      :ok
    end
  end

  defp validate_title(_), do: {:error, "Title is required"}

  defp validate_and_sanitize_metadata(metadata) do
    with {:ok, metadata} <- validate_slug(metadata),
         {:ok, metadata} <- validate_description(metadata),
         {:ok, metadata} <- validate_tags(metadata),
         {:ok, metadata} <- validate_optional_fields(metadata) do
      {:ok, metadata}
    end
  end

  defp validate_slug(%{"slug" => slug} = metadata) when is_binary(slug) do
    # Reject path traversal attempts
    cond do
      String.contains?(slug, "..") ->
        {:error, "Invalid slug: path traversal not allowed"}

      String.contains?(slug, "/") ->
        {:error, "Invalid slug: slashes not allowed"}

      String.contains?(slug, "\\") ->
        {:error, "Invalid slug: backslashes not allowed"}

      not Regex.match?(~r/^[a-z0-9-]+$/, slug) ->
        {:error, "Invalid slug: only lowercase letters, numbers, and hyphens allowed"}

      String.length(slug) > 100 ->
        {:error, "Slug too long (max 100 characters)"}

      true ->
        {:ok, metadata}
    end
  end

  defp validate_slug(metadata), do: {:ok, metadata}

  defp validate_description(%{"description" => desc} = metadata)
       when is_binary(desc) do
    if String.length(desc) > @max_description_length do
      {:error, "Description too long (max #{@max_description_length} characters)"}
    else
      {:ok, metadata}
    end
  end

  defp validate_description(metadata), do: {:ok, metadata}

  defp validate_tags(%{"tags" => tags} = metadata) when is_list(tags) do
    cond do
      length(tags) > @max_tag_count ->
        {:error, "Too many tags (max #{@max_tag_count})"}

      not Enum.all?(tags, &is_binary/1) ->
        {:error, "All tags must be strings"}

      not Enum.all?(tags, &(String.length(&1) <= @max_tag_length)) ->
        {:error, "Tag too long (max #{@max_tag_length} characters)"}

      true ->
        {:ok, metadata}
    end
  end

  defp validate_tags(%{"tags" => _}), do: {:error, "Tags must be a list"}
  defp validate_tags(metadata), do: {:ok, metadata}

  defp validate_optional_fields(metadata) do
    # Validate date if present
    metadata =
      case Map.get(metadata, "date") do
        nil -> metadata
        date when is_binary(date) -> validate_date_string(metadata, date)
        _ -> metadata
      end

    # Validate series_order if present
    metadata =
      case Map.get(metadata, "series_order") do
        nil -> metadata
        order when is_integer(order) and order >= 0 -> metadata
        order when is_binary(order) -> validate_series_order(metadata, order)
        _ -> Map.delete(metadata, "series_order")
      end

    {:ok, sanitize_strings(metadata)}
  end

  defp validate_date_string(metadata, date) do
    case Date.from_iso8601(date) do
      {:ok, _} -> metadata
      _ -> Map.delete(metadata, "date")
    end
  end

  defp validate_series_order(metadata, order_str) do
    case Integer.parse(order_str) do
      {order, ""} when order >= 0 -> Map.put(metadata, "series_order", order)
      _ -> Map.delete(metadata, "series_order")
    end
  end

  defp sanitize_strings(metadata) do
    Enum.reduce(metadata, %{}, fn {key, value}, acc ->
      sanitized_value =
        case value do
          str when is_binary(str) -> sanitize_string(str)
          list when is_list(list) -> Enum.map(list, &sanitize_if_string/1)
          other -> other
        end

      Map.put(acc, key, sanitized_value)
    end)
  end

  defp sanitize_if_string(value) when is_binary(value), do: sanitize_string(value)
  defp sanitize_if_string(value), do: value

  defp sanitize_string(str) do
    str
    |> String.trim()
    # Remove null bytes
    |> String.replace(<<0>>, "")
    # Remove control characters except newlines and tabs
    |> String.replace(~r/[\x00-\x08\x0B-\x0C\x0E-\x1F\x7F]/, "")
  end
end
