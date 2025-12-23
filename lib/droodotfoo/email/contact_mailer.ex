defmodule Droodotfoo.Email.ContactMailer do
  @moduledoc """
  Email mailer for contact form submissions.
  """

  use Swoosh.Mailer, otp_app: :droodotfoo
  import Swoosh.Email
  require Logger

  alias Droodotfoo.Email.ContactEmail
  alias Droodotfoo.ErrorSanitizer

  @doc """
  Sends both notification and confirmation emails for a contact form submission.
  """
  def send_contact_emails(contact_data) do
    # Send notification to admin
    notification_result = contact_notification_email(contact_data) |> deliver()

    # Send confirmation to user
    confirmation_result = contact_confirmation_email(contact_data) |> deliver()

    case {notification_result, confirmation_result} do
      {{:ok, _}, {:ok, _}} ->
        Logger.info("Contact form emails sent successfully for #{contact_data.email}")
        {:ok, :emails_sent}

      {{:error, reason}, _} ->
        Logger.error("Failed to send notification email: #{ErrorSanitizer.sanitize(reason)}")
        {:error, "Failed to send notification email"}

      {_, {:error, reason}} ->
        Logger.error("Failed to send confirmation email: #{ErrorSanitizer.sanitize(reason)}")
        {:error, "Failed to send confirmation email"}
    end
  rescue
    error ->
      Logger.error("Error sending contact emails: #{ErrorSanitizer.sanitize(error)}")
      {:error, "Email service temporarily unavailable"}
  end

  @doc """
  Sends only the notification email to admin.
  """
  def send_notification_email(contact_data) do
    contact_notification_email(contact_data) |> deliver()
  rescue
    error ->
      Logger.error("Error sending notification email: #{ErrorSanitizer.sanitize(error)}")
      {:error, "Failed to send notification email"}
  end

  @doc """
  Sends only the confirmation email to the user.
  """
  def send_confirmation_email(contact_data) do
    contact_confirmation_email(contact_data) |> deliver()
  rescue
    error ->
      Logger.error("Error sending confirmation email: #{ErrorSanitizer.sanitize(error)}")
      {:error, "Failed to send confirmation email"}
  end

  @doc """
  Tests email configuration by sending a test email.
  """
  def test_email_configuration do
    test_data = %{
      name: "Test User",
      email: "test@example.com",
      subject: "Test Email",
      message: "This is a test email to verify email configuration."
    }

    try do
      contact_notification_email(test_data) |> deliver()
    rescue
      error ->
        Logger.error("Email configuration test failed: #{ErrorSanitizer.sanitize(error)}")
        {:error, "Email configuration test failed"}
    end
  end

  @doc """
  Gets email delivery status for debugging.
  """
  def get_delivery_status do
    # This would typically check with the email service provider
    # For now, we'll return a mock status
    %{
      service: "configured",
      last_delivery: DateTime.utc_now(),
      pending_emails: 0,
      failed_emails: 0
    }
  end

  # Private helper functions
  defp contact_notification_email(contact_data) do
    new()
    |> to("drew@axol.io")
    |> from("no-reply@droo.foo")
    |> subject("New Contact Form Submission - #{contact_data.subject}")
    |> html_body(ContactEmail.contact_notification_html(contact_data))
    |> text_body(ContactEmail.contact_notification_text(contact_data))
  end

  defp contact_confirmation_email(contact_data) do
    new()
    |> to(contact_data.email)
    |> from("no-reply@droo.foo")
    |> subject("Thank you for contacting droo.foo")
    |> html_body(ContactEmail.contact_confirmation_html(contact_data))
    |> text_body(ContactEmail.contact_confirmation_text(contact_data))
  end
end
