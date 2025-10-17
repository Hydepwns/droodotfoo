defmodule Droodotfoo.Forms.Constants do
  @moduledoc """
  Centralized constants for all form-related functionality.
  Similar to email constants but for forms, validation, and rate limiting.
  """

  # Contact Form Constants
  @contact_form_name "contact"
  @contact_form_id "contact-form"
  @contact_form_csrf_token "contact_csrf_token"

  # Field Validation Constants
  @max_name_length 100
  @max_subject_length 200
  @max_message_length 2000
  @min_message_length 10
  @email_regex ~r/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/

  # Rate Limiting Constants
  @rate_limit_table_name :contact_rate_limit
  # 5 minutes
  @rate_limit_cleanup_interval 300_000
  @max_submissions_per_hour 3
  @max_submissions_per_day 10
  @rate_limit_window_hours 1
  @rate_limit_window_days 1

  # Spam Protection Constants
  @honeypot_field_name "honeypot"
  @spam_keywords [
    "buy now",
    "crypto",
    "forex",
    "investment",
    "nigerian prince",
    "viagra",
    "casino",
    "lottery",
    "winner"
  ]
  @blocked_domains [
    "tempmail.com",
    "10minutemail.com",
    "guerrillamail.com"
  ]

  # Form Field Names
  @form_fields [:name, :email, :subject, :message, :honeypot]
  @required_fields [:name, :email, :subject, :message]

  # Error Messages
  @error_messages %{
    required: "This field is required",
    email_format: "must be a valid email address",
    name_too_long: "Name must be less than #{@max_name_length} characters",
    subject_too_long: "Subject must be less than #{@max_subject_length} characters",
    message_too_short: "Message must be at least #{@min_message_length} characters",
    message_too_long: "Message must be less than #{@max_message_length} characters",
    spam_detected: "Spam content detected",
    honeypot_triggered: "Spam detected",
    rate_limited: "Too many submissions. Please try again later.",
    blocked_domain: "This email domain is not allowed"
  }

  # Success Messages
  @success_messages %{
    form_submitted: "Your message has been sent successfully!",
    form_validated: "Form validation passed"
  }

  # Form Status Constants
  @form_statuses %{
    :idle => "idle",
    :validating => "validating",
    :submitting => "submitting",
    :success => "success",
    :error => "error",
    :rate_limited => "rate_limited"
  }

  # Export all constants as functions for easy access
  def contact_form_name, do: @contact_form_name
  def contact_form_id, do: @contact_form_id
  def contact_form_csrf_token, do: @contact_form_csrf_token

  def max_name_length, do: @max_name_length
  def max_subject_length, do: @max_subject_length
  def max_message_length, do: @max_message_length
  def min_message_length, do: @min_message_length
  def email_regex, do: @email_regex

  def rate_limit_table_name, do: @rate_limit_table_name
  def rate_limit_cleanup_interval, do: @rate_limit_cleanup_interval
  def max_submissions_per_hour, do: @max_submissions_per_hour
  def max_submissions_per_day, do: @max_submissions_per_day
  def rate_limit_window_hours, do: @rate_limit_window_hours
  def rate_limit_window_days, do: @rate_limit_window_days

  def honeypot_field_name, do: @honeypot_field_name
  def spam_keywords, do: @spam_keywords
  def blocked_domains, do: @blocked_domains

  def form_fields, do: @form_fields
  def required_fields, do: @required_fields

  def error_messages, do: @error_messages
  def success_messages, do: @success_messages
  def form_statuses, do: @form_statuses

  # Helper functions for common operations
  def get_error_message(key), do: Map.get(@error_messages, key, "Unknown error")
  def get_success_message(key), do: Map.get(@success_messages, key, "Success")
  def get_form_status(key), do: Map.get(@form_statuses, key, "unknown")

  def spam_keyword?(text) do
    text_lower = String.downcase(text)
    Enum.any?(@spam_keywords, &String.contains?(text_lower, &1))
  end

  def blocked_domain?(email) do
    domain = email |> String.split("@") |> List.last()
    domain in @blocked_domains
  end

  def validate_field_length(field, value) when field in [:name, :subject, :message] do
    case field do
      :name ->
        String.length(value) <= @max_name_length

      :subject ->
        String.length(value) <= @max_subject_length

      :message ->
        String.length(value) >= @min_message_length and
          String.length(value) <= @max_message_length
    end
  end

  def validate_email_format(email) do
    Regex.match?(@email_regex, email)
  end
end
