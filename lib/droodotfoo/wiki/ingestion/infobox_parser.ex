defmodule Droodotfoo.Wiki.Ingestion.InfoboxParser do
  @moduledoc """
  Extracts structured data from MediaWiki wikitext infoboxes.

  OSRS Wiki uses templates like `{{Infobox Item}}` and `{{Infobox Monster}}`
  with key-value parameters.
  """

  @type infobox :: %{String.t() => String.t()}

  @doc """
  Parse wikitext and extract the first infobox found.

  Returns the infobox type and all parameters as a map.
  """
  @spec parse(String.t()) :: {:ok, infobox()} | {:error, :no_infobox}
  def parse(wikitext) when is_binary(wikitext) do
    case extract_infobox(wikitext) do
      nil -> {:error, :no_infobox}
      infobox -> {:ok, parse_infobox(infobox)}
    end
  end

  @doc """
  Parse wikitext and extract all infoboxes.
  """
  @spec parse_all(String.t()) :: [infobox()]
  def parse_all(wikitext) when is_binary(wikitext) do
    wikitext
    |> extract_all_infoboxes()
    |> Enum.map(&parse_infobox/1)
  end

  @doc """
  Extract specific fields from wikitext.
  """
  @spec extract_fields(String.t(), [String.t()]) :: %{String.t() => String.t() | nil}
  def extract_fields(wikitext, fields) when is_binary(wikitext) and is_list(fields) do
    case parse(wikitext) do
      {:ok, infobox} ->
        Map.take(infobox, fields)

      {:error, _} ->
        Map.new(fields, &{&1, nil})
    end
  end

  @infobox_start_pattern ~r/\{\{Infobox\s+(\w+)/i

  defp extract_infobox(wikitext) do
    case Regex.run(@infobox_start_pattern, wikitext, return: :index) do
      [{start, _len} | _] ->
        extract_balanced_template(wikitext, start)

      nil ->
        nil
    end
  end

  defp extract_all_infoboxes(wikitext) do
    extract_all_infoboxes(wikitext, 0, [])
  end

  defp extract_all_infoboxes(wikitext, offset, acc) do
    remaining = String.slice(wikitext, offset..-1//1)

    case Regex.run(@infobox_start_pattern, remaining, return: :index) do
      [{start, _len} | _] ->
        abs_start = offset + start

        case extract_balanced_template(wikitext, abs_start) do
          nil ->
            Enum.reverse(acc)

          template ->
            template_len = String.length(template)
            extract_all_infoboxes(wikitext, abs_start + template_len, [template | acc])
        end

      nil ->
        Enum.reverse(acc)
    end
  end

  defp extract_balanced_template(wikitext, start) do
    rest = String.slice(wikitext, start..-1//1)
    find_closing_braces(rest, 0, 0, [])
  end

  defp find_closing_braces(<<>>, _depth, _pos, _acc), do: nil

  defp find_closing_braces(<<"{{", rest::binary>>, depth, pos, acc) do
    find_closing_braces(rest, depth + 1, pos + 2, ["{{" | acc])
  end

  defp find_closing_braces(<<"}}", _rest::binary>>, 1, _pos, acc) do
    ["}}" | acc] |> Enum.reverse() |> IO.iodata_to_binary()
  end

  defp find_closing_braces(<<"}}", rest::binary>>, depth, pos, acc) when depth > 1 do
    find_closing_braces(rest, depth - 1, pos + 2, ["}}" | acc])
  end

  defp find_closing_braces(<<char::utf8, rest::binary>>, depth, pos, acc) do
    find_closing_braces(rest, depth, pos + 1, [<<char::utf8>> | acc])
  end

  defp parse_infobox(template) do
    type =
      case Regex.run(~r/\{\{Infobox\s+(\w+)/i, template) do
        [_, type] -> type
        _ -> "Unknown"
      end

    content =
      template
      |> String.replace(~r/^\{\{Infobox\s+\w+\s*/i, "")
      |> String.replace(~r/\}\}$/, "")

    params =
      content
      |> split_parameters()
      |> Enum.map(&parse_parameter/1)
      |> Enum.reject(&is_nil/1)
      |> Map.new()

    Map.put(params, "infobox_type", type)
  end

  defp split_parameters(content) do
    split_parameters(content, 0, [], [])
  end

  defp split_parameters(<<>>, _depth, current, acc) do
    param = current |> Enum.reverse() |> IO.iodata_to_binary() |> String.trim()

    if param == "" do
      Enum.reverse(acc)
    else
      Enum.reverse([param | acc])
    end
  end

  defp split_parameters(<<"{{", rest::binary>>, depth, current, acc) do
    split_parameters(rest, depth + 1, ["}}", "{" | current], acc)
  end

  defp split_parameters(<<"}}", rest::binary>>, depth, current, acc) when depth > 0 do
    split_parameters(rest, depth - 1, ["}}" | current], acc)
  end

  defp split_parameters(<<"[[", rest::binary>>, depth, current, acc) do
    split_parameters(rest, depth + 1, ["[[" | current], acc)
  end

  defp split_parameters(<<"]]", rest::binary>>, depth, current, acc) when depth > 0 do
    split_parameters(rest, depth - 1, ["]]" | current], acc)
  end

  defp split_parameters(<<"|", rest::binary>>, 0, current, acc) do
    param = current |> Enum.reverse() |> IO.iodata_to_binary() |> String.trim()

    if param == "" do
      split_parameters(rest, 0, [], acc)
    else
      split_parameters(rest, 0, [], [param | acc])
    end
  end

  defp split_parameters(<<char::utf8, rest::binary>>, depth, current, acc) do
    split_parameters(rest, depth, [<<char::utf8>> | current], acc)
  end

  defp parse_parameter(param) do
    case String.split(param, "=", parts: 2) do
      [key, value] ->
        {clean_key(key), clean_value(value)}

      _ ->
        nil
    end
  end

  defp clean_key(key) do
    key
    |> String.trim()
    |> String.downcase()
    |> String.replace(~r/\s+/, "_")
  end

  defp clean_value(value) do
    value
    |> String.trim()
    |> strip_wiki_markup()
  end

  defp strip_wiki_markup(value) do
    value
    |> String.replace(~r/\[\[(File|Image):[^\]]+\]\]/i, "")
    |> String.replace(~r/\[\[[^\]|]+\|([^\]]+)\]\]/, "\\1")
    |> String.replace(~r/\[\[([^\]]+)\]\]/, "\\1")
    |> String.replace(~r/\{\{[^{}]+\}\}/, "")
    |> String.replace(~r/<[^>]+>/, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
