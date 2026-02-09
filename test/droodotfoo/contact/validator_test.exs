defmodule Droodotfoo.Contact.ValidatorTest do
  use ExUnit.Case, async: false

  alias Droodotfoo.Contact.Validator
  alias Droodotfoo.Forms.Constants

  # Define types for changeset casting
  @types %{
    name: :string,
    email: :string,
    subject: :string,
    message: :string,
    honeypot: :string
  }

  describe "validate_contact_form/1" do
    setup do
      valid_params = %{
        "name" => "John Doe",
        "email" => "john@example.com",
        "subject" => "Test Subject",
        "message" => "This is a test message that meets the minimum length requirement.",
        "honeypot" => ""
      }

      {:ok, valid_params: valid_params}
    end

    test "accepts valid form data", %{valid_params: params} do
      changeset = Validator.validate_contact_form(params)
      assert changeset.valid?
    end

    test "rejects missing required fields" do
      changeset = Validator.validate_contact_form(%{})
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset, :name)
      assert "can't be blank" in errors_on(changeset, :email)
      assert "can't be blank" in errors_on(changeset, :subject)
      assert "can't be blank" in errors_on(changeset, :message)
    end

    test "rejects invalid email format" do
      changeset =
        Validator.validate_contact_form(%{
          "name" => "John",
          "email" => "not-an-email",
          "subject" => "Test",
          "message" => "This is a valid message."
        })

      refute changeset.valid?
      assert Constants.get_error_message(:email_format) in errors_on(changeset, :email)
    end

    test "accepts valid email formats" do
      valid_emails = [
        "user@example.com",
        "user.name@example.com",
        "user+tag@example.co.uk",
        "user123@test-domain.com"
      ]

      for email <- valid_emails do
        changeset =
          Validator.validate_contact_form(%{
            "name" => "John",
            "email" => email,
            "subject" => "Test",
            "message" => "Valid message here."
          })

        assert changeset.valid?, "Email #{email} should be valid"
      end
    end

    test "rejects name exceeding max length" do
      long_name = String.duplicate("a", Constants.max_name_length() + 1)

      changeset =
        Validator.validate_contact_form(%{
          "name" => long_name,
          "email" => "test@example.com",
          "subject" => "Test",
          "message" => "Valid message."
        })

      refute changeset.valid?

      assert "should be at most #{Constants.max_name_length()} character(s)" in errors_on(
               changeset,
               :name
             )
    end

    test "rejects subject exceeding max length" do
      long_subject = String.duplicate("a", Constants.max_subject_length() + 1)

      changeset =
        Validator.validate_contact_form(%{
          "name" => "John",
          "email" => "test@example.com",
          "subject" => long_subject,
          "message" => "Valid message."
        })

      refute changeset.valid?

      assert "should be at most #{Constants.max_subject_length()} character(s)" in errors_on(
               changeset,
               :subject
             )
    end

    test "rejects message shorter than minimum length" do
      short_message = String.duplicate("a", Constants.min_message_length() - 1)

      changeset =
        Validator.validate_contact_form(%{
          "name" => "John",
          "email" => "test@example.com",
          "subject" => "Test",
          "message" => short_message
        })

      refute changeset.valid?

      assert "should be at least #{Constants.min_message_length()} character(s)" in errors_on(
               changeset,
               :message
             )
    end

    test "rejects message exceeding max length" do
      long_message = String.duplicate("a", Constants.max_message_length() + 1)

      changeset =
        Validator.validate_contact_form(%{
          "name" => "John",
          "email" => "test@example.com",
          "subject" => "Test",
          "message" => long_message
        })

      refute changeset.valid?

      assert "should be at most #{Constants.max_message_length()} character(s)" in errors_on(
               changeset,
               :message
             )
    end

    test "rejects blocked email domains" do
      for domain <- Constants.blocked_domains() do
        changeset =
          Validator.validate_contact_form(%{
            "name" => "John",
            "email" => "user@#{domain}",
            "subject" => "Test",
            "message" => "Valid message."
          })

        refute changeset.valid?, "Domain #{domain} should be blocked"
        assert Constants.get_error_message(:blocked_domain) in errors_on(changeset, :email)
      end
    end

    test "accepts valid email domains", %{valid_params: params} do
      changeset = Validator.validate_contact_form(params)
      assert changeset.valid?
    end

    test "rejects messages with spam keywords" do
      for keyword <- Constants.spam_keywords() do
        changeset =
          Validator.validate_contact_form(%{
            "name" => "John",
            "email" => "test@example.com",
            "subject" => "Test #{keyword} here",
            "message" => "Valid message length."
          })

        refute changeset.valid?, "Keyword '#{keyword}' should be detected as spam"
        assert Constants.get_error_message(:spam_detected) in errors_on(changeset, :message)
      end
    end

    test "detects spam keywords case-insensitively" do
      changeset =
        Validator.validate_contact_form(%{
          "name" => "John",
          "email" => "test@example.com",
          "subject" => "BUY NOW!",
          "message" => "NIGERIAN PRINCE needs help"
        })

      refute changeset.valid?
      assert Constants.get_error_message(:spam_detected) in errors_on(changeset, :message)
    end
  end

  describe "validate_honeypot/1" do
    test "accepts empty honeypot field" do
      changeset = Ecto.Changeset.cast({%{}, @types}, %{"honeypot" => ""}, [:honeypot])
      result = Validator.validate_honeypot(changeset)
      assert result.valid?
    end

    test "accepts nil honeypot field" do
      changeset = Ecto.Changeset.cast({%{}, @types}, %{}, [:honeypot])
      result = Validator.validate_honeypot(changeset)
      assert result.valid?
    end

    test "rejects filled honeypot field" do
      changeset =
        Ecto.Changeset.cast({%{}, @types}, %{"honeypot" => "bot filled this"}, [:honeypot])

      result = Validator.validate_honeypot(changeset)
      refute result.valid?
      assert Constants.get_error_message(:honeypot_triggered) in errors_on(result, :honeypot)
    end
  end

  describe "validate_spam_content/1" do
    test "accepts clean content" do
      changeset =
        Ecto.Changeset.cast(
          {%{}, @types},
          %{"subject" => "Hello", "message" => "Clean message"},
          [
            :subject,
            :message
          ]
        )

      result = Validator.validate_spam_content(changeset)
      assert result.valid?
    end

    test "detects spam in message" do
      changeset =
        Ecto.Changeset.cast(
          {%{}, @types},
          %{"subject" => "Hello", "message" => "Buy now special offer"},
          [:subject, :message]
        )

      result = Validator.validate_spam_content(changeset)
      refute result.valid?
      assert Constants.get_error_message(:spam_detected) in errors_on(result, :message)
    end

    test "detects spam in subject" do
      changeset =
        Ecto.Changeset.cast(
          {%{}, @types},
          %{"subject" => "Win the lottery!", "message" => "Click here"},
          [:subject, :message]
        )

      result = Validator.validate_spam_content(changeset)
      refute result.valid?
      assert Constants.get_error_message(:spam_detected) in errors_on(result, :message)
    end

    test "combines subject and message for spam detection" do
      changeset =
        Ecto.Changeset.cast(
          {%{}, @types},
          %{"subject" => "Special", "message" => "investment opportunity"},
          [:subject, :message]
        )

      result = Validator.validate_spam_content(changeset)
      refute result.valid?
      assert Constants.get_error_message(:spam_detected) in errors_on(result, :message)
    end
  end

  describe "validate_email_domain/1" do
    test "accepts valid email domain" do
      changeset =
        Ecto.Changeset.cast({%{}, @types}, %{"email" => "user@example.com"}, [:email])

      result = Validator.validate_email_domain(changeset)
      assert result.valid?
    end

    test "rejects blocked domains" do
      changeset =
        Ecto.Changeset.cast({%{}, @types}, %{"email" => "user@tempmail.com"}, [:email])

      result = Validator.validate_email_domain(changeset)
      refute result.valid?
      assert Constants.get_error_message(:blocked_domain) in errors_on(result, :email)
    end

    test "handles missing email gracefully" do
      changeset = Ecto.Changeset.cast({%{}, @types}, %{}, [:email])
      result = Validator.validate_email_domain(changeset)
      assert result.valid?
    end
  end

  # Rate limiting is now handled by Droodotfoo.Contact.RateLimiter GenServer
  # See test/droodotfoo/rate_limiter_test.exs for rate limiting tests

  # Helper function to extract error messages from changeset
  defp errors_on(changeset, field) do
    Keyword.get_values(changeset.errors, field)
    |> Enum.map(fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
