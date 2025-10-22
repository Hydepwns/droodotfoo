defmodule DroodotfooWeb.ContactLive do
  @moduledoc """
  LiveView for contact form with real-time validation and email integration.
  """

  use DroodotfooWeb, :live_view
  require Logger
  alias Droodotfoo.Contact.{RateLimiter, Validator}
  alias Droodotfoo.Email.ContactMailer
  alias Droodotfoo.Forms.Constants
  import DroodotfooWeb.ContentComponents

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
  # render_submission_status now uses status_message component from ContentComponents

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
    <.page_layout
      page_title="Contact"
      page_description="Get in touch via the form below"
    >
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
            class="visually-hidden"
            tabindex="-1"
            autocomplete="off"
          />

          <.form_input
            id="contact_name"
            name="contact[name]"
            label="Name"
            value={@form_data.name}
            error={@form_errors[:name]}
            placeholder="Your full name"
            required
          />

          <.form_input
            id="contact_email"
            name="contact[email]"
            label="Email"
            type="email"
            value={@form_data.email}
            error={@form_errors[:email]}
            placeholder="your.email@example.com"
            required
          />

          <.form_input
            id="contact_subject"
            name="contact[subject]"
            label="Subject"
            value={@form_data.subject}
            error={@form_errors[:subject]}
            placeholder="What's this about?"
            required
          />

          <.form_textarea
            id="contact_message"
            name="contact[message]"
            label="Message"
            value={@form_data.message}
            error={@form_errors[:message]}
            placeholder="Tell me about your project, idea, or just say hello!"
            rows={6}
            required
          />

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

        <%= if @submission_status do %>
          <.status_message type={elem(@submission_status, 0)} message={elem(@submission_status, 1)} />
        <% end %>

        {render_rate_limit_info(@rate_limit_status)}
      </div>
    </.page_layout>
    """
  end
end
