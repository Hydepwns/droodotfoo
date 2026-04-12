defmodule Swoosh.Adapters.Resend do
  @moduledoc """
  Swoosh adapter for Resend (https://resend.com).
  """

  use Swoosh.Adapter, required_config: [:api_key]

  @base_url "https://api.resend.com"

  @impl true
  def deliver(%Swoosh.Email{} = email, config) do
    body = prepare_body(email)
    api_key = config[:api_key]

    case Req.post("#{@base_url}/emails",
           json: body,
           headers: [{"authorization", "Bearer #{api_key}"}]
         ) do
      {:ok, %{status: status, body: resp_body}} when status in 200..299 ->
        {:ok, %{id: resp_body["id"]}}

      {:ok, %{status: status, body: resp_body}} ->
        {:error, {status, resp_body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp prepare_body(email) do
    %{
      from: format_address(email.from),
      to: Enum.map(email.to, &format_address/1),
      subject: email.subject
    }
    |> maybe_put(:html, email.html_body)
    |> maybe_put(:text, email.text_body)
    |> maybe_put(:cc, format_addresses(email.cc))
    |> maybe_put(:bcc, format_addresses(email.bcc))
    |> maybe_put(:reply_to, format_reply_to(email.reply_to))
  end

  defp format_address({name, email}) when is_binary(name) and name != "" do
    "#{name} <#{email}>"
  end

  defp format_address({_name, email}), do: email
  defp format_address(email) when is_binary(email), do: email

  defp format_addresses([]), do: nil
  defp format_addresses(addresses), do: Enum.map(addresses, &format_address/1)

  defp format_reply_to(nil), do: nil
  defp format_reply_to({_name, email}), do: email
  defp format_reply_to(email) when is_binary(email), do: email

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, []), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)
end
