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

  @doc """
  Checks if an IP address is rate limited.
  """
  def check_rate_limit(ip_address) do
    # Check if IP has submitted more than 3 forms in the last hour
    one_hour_ago = DateTime.utc_now() |> DateTime.add(-3600, :second)
    # In a real implementation, you'd check against a database
    # For now, we'll use a simple in-memory check
    case :ets.lookup(:contact_rate_limit, ip_address) do
      [{^ip_address, count, last_submission}]
      when count >= 3 and last_submission > one_hour_ago ->
        {:error, "Rate limit exceeded. Please try again later."}

      _ ->
        {:ok, :allowed}
    end
  end

  @doc """
  Records a form submission for rate limiting.
  """
  def record_submission(ip_address) do
    now = DateTime.utc_now()

    case :ets.lookup(:contact_rate_limit, ip_address) do
      [{^ip_address, count, _last_submission}] ->
        :ets.insert(:contact_rate_limit, {ip_address, count + 1, now})

      [] ->
        :ets.insert(:contact_rate_limit, {ip_address, 1, now})
    end
  end

  @doc """
  Initializes the rate limiting ETS table.
  """
  def init_rate_limit_table do
    :ets.new(:contact_rate_limit, [:named_table, :public, :set])
  end

  @doc """
  Cleans up old rate limit entries.
  """
  def cleanup_rate_limit do
    one_hour_ago = DateTime.utc_now() |> DateTime.add(-3600, :second)

    # Get all entries and filter by timestamp
    all_entries = :ets.tab2list(:contact_rate_limit)

    old_entries =
      Enum.filter(all_entries, fn {_ip_address, _count, timestamp} ->
        DateTime.compare(timestamp, one_hour_ago) == :lt
      end)

    # Remove old entries
    Enum.each(old_entries, fn {ip_address, _count, _timestamp} ->
      :ets.delete(:contact_rate_limit, ip_address)
    end)

    Enum.count(old_entries)
  end
end
