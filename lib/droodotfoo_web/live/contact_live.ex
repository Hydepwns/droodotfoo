defmodule DroodotfooWeb.ContactLive do
  @moduledoc """
  LiveView for contact form with real-time validation and email integration.
  """

  use DroodotfooWeb, :live_view
  require Logger
  alias Droodotfoo.Contact.{RateLimiter, Validator}
  alias Droodotfoo.Email.ContactMailer
  alias Droodotfoo.Forms.Constants

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> initialize_form()
    |> then(&{:ok, &1})
  end

  defp initialize_form(socket) do
    socket
    |> assign(:form_data, create_empty_form())
    |> assign(:form_errors, %{})
    |> assign(:is_submitting, false)
    |> assign(:submission_status, nil)
    |> assign(:rate_limit_status, nil)
  end

  defp create_empty_form do
    Constants.form_fields()
    |> Enum.map(fn field -> {field, ""} end)
    |> Enum.into(%{})
  end

  @impl true
  def handle_event("validate", %{"contact" => params}, socket) do
    socket
    |> assign(:form_data, params)
    |> assign(:form_errors, extract_errors(Validator.validate_contact_form(params)))
    |> assign(:submission_status, nil)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_event("submit", %{"contact" => params}, socket) do
    socket
    |> get_client_ip()
    |> check_rate_limit()
    |> handle_rate_limit_result(socket, params)
  end

  @impl true
  def handle_event("check_rate_limit", _params, socket) do
    socket
    |> get_client_ip()
    |> RateLimiter.get_status()
    |> handle_rate_limit_status(socket)
  end

  @impl true
  def handle_event("clear_form", _params, socket) do
    socket
    |> assign(:form_data, create_empty_form())
    |> assign(:form_errors, %{})
    |> assign(:submission_status, nil)
    |> assign(:is_submitting, false)
    |> then(&{:noreply, &1})
  end

  defp check_rate_limit(client_ip) do
    RateLimiter.check_rate_limit(client_ip)
  end

  defp handle_rate_limit_result({:ok, :allowed}, socket, params) do
    submit_form(params, socket)
  end

  defp handle_rate_limit_result({:error, reason}, socket, _params) do
    socket
    |> assign(:submission_status, {:error, reason})
    |> assign(:is_submitting, false)
    |> then(&{:noreply, &1})
  end

  defp handle_rate_limit_status({:ok, status}, socket) do
    socket
    |> assign(:rate_limit_status, status)
    |> then(&{:noreply, &1})
  end

  defp handle_rate_limit_status({:error, _reason}, socket) do
    {:noreply, socket}
  end

  defp submit_form(params, socket) do
    socket
    |> assign(:is_submitting, true)
    |> validate_and_submit(params)
  end

  defp validate_and_submit(socket, params) do
    changeset = Validator.validate_contact_form(params)

    case changeset.valid? do
      true ->
        socket
        |> send_emails_and_record(params)
        |> handle_email_result()

      false ->
        socket
        |> handle_validation_errors(changeset)
    end
  end

  defp send_emails_and_record(socket, params) do
    client_ip = get_client_ip(socket)
    email_result = ContactMailer.send_contact_emails(params)

    case email_result do
      {:ok, :emails_sent} ->
        RateLimiter.record_submission(client_ip)
        {socket, email_result}

      {:error, _reason} ->
        {socket, email_result}
    end
  end

  defp handle_email_result({socket, {:ok, :emails_sent}}) do
    socket
    |> assign(:submission_status, {:success, Constants.get_success_message(:form_submitted)})
    |> assign(:is_submitting, false)
    |> reset_form()
    |> assign(:form_errors, %{})
    |> then(&{:noreply, &1})
  end

  defp handle_email_result({socket, {:error, reason}}) do
    socket
    |> assign(:submission_status, {:error, "Failed to send message: #{reason}"})
    |> assign(:is_submitting, false)
    |> then(&{:noreply, &1})
  end

  defp handle_validation_errors(socket, changeset) do
    form_errors = extract_errors(changeset)

    socket
    |> assign(:form_errors, form_errors)
    |> assign(:submission_status, {:error, "Please fix the errors below"})
    |> assign(:is_submitting, false)
    |> then(&{:noreply, &1})
  end

  defp extract_errors(changeset) do
    changeset.errors
    |> Enum.into(%{}, fn {field, {message, _}} -> {field, message} end)
  end

  defp reset_form(socket) do
    empty_form =
      Constants.form_fields()
      |> Enum.map(fn field -> {field, ""} end)
      |> Enum.into(%{})

    assign(socket, :form_data, empty_form)
  end

  # Template helper functions
  defp render_submission_status(nil), do: ""

  defp render_submission_status({status, message}) do
    assigns = %{status: status, message: message}

    ~H"""
    <div class={["submission-status", @status]}>
      <div class={[@status, "-message"]}>
        {@message}
      </div>
    </div>
    """
  end

  defp render_rate_limit_info(nil), do: ""

  defp render_rate_limit_info(status) do
    assigns = %{status: status}

    ~H"""
    <div class="rate-limit-info">
      <small>
        Submissions: {@status.hourly_submissions}/{@status.hourly_limit} (hourly)
      </small>
    </div>
    """
  end

  defp get_client_ip(socket) do
    # Get client IP from connection
    case socket.private[:connect_info] do
      %{peer_data: %{address: {a, b, c, d}}} ->
        "#{a}.#{b}.#{c}.#{d}"

      _ ->
        # Fallback for development
        "127.0.0.1"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="contact-form-container">
      <div class="contact-header">
        <h1>Contact</h1>
      </div>

      <div class="contact-form">
        <.form
          for={%{}}
          id="contact-form"
          phx-submit="submit"
          phx-change="validate"
          class="contact-form-inner"
        >
          <!-- Honeypot field (hidden from users) -->
          <input
            type="text"
            name="contact[honeypot]"
            value={@form_data.honeypot}
            style="display: none;"
            tabindex="-1"
            autocomplete="off"
          />

          <div class="form-group">
            <label for="contact_name" class="form-label">Name *</label>
            <input
              type="text"
              id="contact_name"
              name="contact[name]"
              value={@form_data.name}
              class={["form-input", @form_errors[:name] && "error"]}
              placeholder="Your full name"
              required
            />
            <%= if @form_errors[:name] do %>
              <div class="error-message">{@form_errors[:name]}</div>
            <% end %>
          </div>

          <div class="form-group">
            <label for="contact_email" class="form-label">Email *</label>
            <input
              type="email"
              id="contact_email"
              name="contact[email]"
              value={@form_data.email}
              class={["form-input", @form_errors[:email] && "error"]}
              placeholder="your.email@example.com"
              required
            />
            <%= if @form_errors[:email] do %>
              <div class="error-message">{@form_errors[:email]}</div>
            <% end %>
          </div>

          <div class="form-group">
            <label for="contact_subject" class="form-label">Subject *</label>
            <input
              type="text"
              id="contact_subject"
              name="contact[subject]"
              value={@form_data.subject}
              class={["form-input", @form_errors[:subject] && "error"]}
              placeholder="What's this about?"
              required
            />
            <%= if @form_errors[:subject] do %>
              <div class="error-message">{@form_errors[:subject]}</div>
            <% end %>
          </div>

          <div class="form-group">
            <label for="contact_message" class="form-label">Message *</label>
            <textarea
              id="contact_message"
              name="contact[message]"
              value={@form_data.message}
              class={["form-textarea", @form_errors[:message] && "error"]}
              placeholder="Tell me about your project, idea, or just say hello!"
              rows="6"
              required
            >{@form_data.message}</textarea>
            <%= if @form_errors[:message] do %>
              <div class="error-message">{@form_errors[:message]}</div>
            <% end %>
          </div>

          <div class="form-actions">
            <button
              type="submit"
              class={["submit-button", @is_submitting && "submitting"]}
              disabled={@is_submitting}
            >
              <%= if @is_submitting do %>
                <span class="spinner"></span> Sending...
              <% else %>
                Send
              <% end %>
            </button>

            <button
              type="button"
              phx-click="clear_form"
              class="clear-button"
              disabled={@is_submitting}
            >
              Clear Form
            </button>
          </div>
        </.form>

        {render_submission_status(@submission_status)}

        {render_rate_limit_info(@rate_limit_status)}
      </div>
    </div>
    """
  end
end
