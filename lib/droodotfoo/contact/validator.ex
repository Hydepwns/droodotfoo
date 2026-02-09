defmodule Droodotfoo.Contact.Validator do
  @moduledoc """
  Contact form validation module with spam protection and rate limiting.
  """

  import Ecto.Changeset
  alias Droodotfoo.Forms.Constants

  @types %{
    name: :string,
    email: :string,
    subject: :string,
    message: :string,
    honeypot: :string
  }

  @doc """
  Validates contact form data with comprehensive checks.
  """
  def validate_contact_form(params) do
    {%{}, @types}
    |> cast(params, Constants.form_fields())
    |> validate_required(Constants.required_fields())
    |> validate_length(:name, max: Constants.max_name_length())
    |> validate_length(:subject, max: Constants.max_subject_length())
    |> validate_length(:message,
      min: Constants.min_message_length(),
      max: Constants.max_message_length()
    )
    |> validate_format(:email, Constants.email_regex(),
      message: Constants.get_error_message(:email_format)
    )
    |> validate_honeypot()
    |> validate_spam_content()
    |> validate_email_domain()
  end

  @doc """
  Validates honeypot field to catch bots.
  """
  def validate_honeypot(changeset) do
    changeset
    |> get_field(:honeypot)
    |> case do
      honeypot when is_binary(honeypot) and honeypot != "" ->
        add_error(changeset, :honeypot, Constants.get_error_message(:honeypot_triggered))

      _ ->
        changeset
    end
  end

  @doc """
  Validates message content for spam indicators.
  """
  def validate_spam_content(changeset) do
    message = get_field(changeset, :message)
    subject = get_field(changeset, :subject)
    content = "#{subject} #{message}" |> String.downcase()

    case Constants.spam_keyword?(content) do
      true -> add_error(changeset, :message, Constants.get_error_message(:spam_detected))
      false -> changeset
    end
  end

  @doc """
  Validates email domain against known disposable email providers.
  """
  def validate_email_domain(changeset) do
    changeset
    |> get_field(:email)
    |> case do
      nil ->
        changeset

      email ->
        case Constants.blocked_domain?(email) do
          true -> add_error(changeset, :email, Constants.get_error_message(:blocked_domain))
          false -> changeset
        end
    end
  end

end
