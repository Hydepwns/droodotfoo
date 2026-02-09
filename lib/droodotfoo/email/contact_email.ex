defmodule Droodotfoo.Email.ContactEmail do
  @moduledoc """
  Email templates for contact form submissions.
  """

  import Swoosh.Email
  alias Droodotfoo.Core.Config

  @doc """
  Sends notification email to admin about new contact form submission.
  """
  def contact_notification_email(contact_data) do
    new()
    |> to(Config.admin_email())
    |> from(Config.noreply_email())
    |> subject("New Contact Form Submission - #{contact_data.subject}")
    |> html_body(contact_notification_html(contact_data))
    |> text_body(contact_notification_text(contact_data))
  end

  @doc """
  Sends confirmation email to the person who submitted the form.
  """
  def contact_confirmation_email(contact_data) do
    new()
    |> to(contact_data.email)
    |> from(Config.noreply_email())
    |> subject("Thank you for contacting DROO")
    |> html_body(contact_confirmation_html(contact_data))
    |> text_body(contact_confirmation_text(contact_data))
  end

  def contact_notification_html(contact_data) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>New Contact Form Submission</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #1a1a1a; color: #00ff00; padding: 20px; text-align: center; }
        .content { background: #f9f9f9; padding: 20px; }
        .field { margin-bottom: 15px; }
        .label { font-weight: bold; color: #666; }
        .value { margin-top: 5px; }
        .message { background: #fff; padding: 15px; border-left: 4px solid #00ff00; }
        .footer { background: #1a1a1a; color: #00ff00; padding: 15px; text-align: center; font-size: 12px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Contact Form Submission</h1>
        </div>
        <div class="content">
          <div class="field">
            <div class="label">Name:</div>
            <div class="value">#{escape_html(contact_data.name)}</div>
          </div>
          <div class="field">
            <div class="label">Email:</div>
            <div class="value">#{escape_html(contact_data.email)}</div>
          </div>
          <div class="field">
            <div class="label">Subject:</div>
            <div class="value">#{escape_html(contact_data.subject)}</div>
          </div>
          <div class="field">
            <div class="label">Message:</div>
            <div class="message">#{escape_html(contact_data.message) |> String.replace("\n", "<br>")}</div>
          </div>
          <div class="field">
            <div class="label">Submitted:</div>
            <div class="value">#{DateTime.utc_now() |> DateTime.to_string()}</div>
          </div>
        </div>
        <div class="footer">
          <p>This email was sent from the droo.foo contact form</p>
        </div>
      </div>
    </body>
    </html>
    """
  end

  def contact_notification_text(contact_data) do
    """
    CONTACT FORM SUBMISSION
    ===========================
    Name: #{contact_data.name}
    Email: #{contact_data.email}
    Subject: #{contact_data.subject}
    Message:
    #{contact_data.message}
    Submitted: #{DateTime.utc_now() |> DateTime.to_string()}
    ---
    This email was sent from the droo.foo contact form
    """
  end

  def contact_confirmation_html(contact_data) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Thank you for contacting droo.foo</title>
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #1a1a1a; color: #00ff00; padding: 20px; text-align: center; }
        .content { background: #f9f9f9; padding: 20px; }
        .footer { background: #1a1a1a; color: #00ff00; padding: 15px; text-align: center; font-size: 12px; }
        .terminal { background: #000; color: #00ff00; padding: 15px; font-family: monospace; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Message Received</h1>
        </div>
        <div class="content">
          <p>Hi #{escape_html(contact_data.name)},</p>
          
          <p>Thank you for reaching out! Your message has been received and I'll get back to you as soon as possible.</p>
          
          <div class="terminal">
            <div>droo.foo:~$ echo "Message received successfully"</div>
            <div>Message received successfully</div>
            <div>droo.foo:~$ _</div>
          </div>
          
          <p><strong>Your message:</strong></p>
          <p>#{escape_html(contact_data.subject)}</p>
          
          <p>Best regards,<br>Droo</p>
        </div>
        <div class="footer">
          <p>Visit <a href="https://droo.foo" style="color: #00ff00;">droo.foo</a> for more information</p>
        </div>
      </div>
    </body>
    </html>
    """
  end

  def contact_confirmation_text(contact_data) do
    """
    MESSAGE RECEIVED
    ===============
    Hi #{contact_data.name},
    Your message has been received.
    Subject: #{contact_data.subject}
    - DROO
    ---
    https://droo.foo
    """
  end

  defp escape_html(text) do
    text
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end
end
