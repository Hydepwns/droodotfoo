defmodule DroodotfooWeb.ContactLive do
  @moduledoc """
  LiveView for contact form with real-time validation and email integration.
  """

  use DroodotfooWeb, :live_view
  require Logger
  alias Droodotfoo.Contact.{RateLimiter, Validator}
  alias Droodotfoo.Email.ContactMailer
  alias Droodotfoo.Forms.Constants
  alias DroodotfooWeb.Plugs.ClientIP
  alias DroodotfooWeb.SEO.JsonLD
  import DroodotfooWeb.ContentComponents

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> initialize_form()
    |> assign_page_meta(
      "Contact",
      "/contact",
      breadcrumb_json_ld("Contact", "/contact", [JsonLD.person_schema()])
    )
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
    |> push_event("focus", %{target: "contact_name"})
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
    first_error_field = get_first_error_field(changeset)

    socket
    |> assign(:form_errors, form_errors)
    |> assign(:submission_status, {:error, "Please fix the errors below"})
    |> assign(:is_submitting, false)
    |> push_event("focus", %{target: first_error_field})
    |> then(&{:noreply, &1})
  end

  defp get_first_error_field(changeset) do
    # Return the first field with an error, in form field order
    field_order = [:name, :email, :subject, :message]

    Enum.find(field_order, :name, fn field ->
      Keyword.has_key?(changeset.errors, field)
    end)
    |> then(&"contact_#{&1}")
  end

  defp extract_errors(changeset) do
    changeset.errors
    |> Enum.into(%{}, fn {field, {message, _}} -> {field, message} end)
  end

  defp reset_form(socket) do
    assign(socket, :form_data, create_empty_form())
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

  defp get_client_ip(socket), do: ClientIP.from_socket(socket)

  @impl true
  def render(assigns) do
    ~H"""
    <.page_layout page_title="Contact">
      <section class="section-spaced">
        <h2 class="section-header-bordered">CONNECT</h2>
        <div class="social-links">
          <a href="https://github.com/DROOdotFOO" target="_blank" rel="noopener" aria-label="GitHub">
            <svg viewBox="0 0 24 24" width="24" height="24" fill="currentColor" aria-hidden="true">
              <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z" />
            </svg>
          </a>
          <a href="https://x.com/DROOdotFOO" target="_blank" rel="noopener" aria-label="X (Twitter)">
            <svg viewBox="0 0 24 24" width="24" height="24" fill="currentColor" aria-hidden="true">
              <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z" />
            </svg>
          </a>
          <a
            href="https://www.linkedin.com/in/droodotfoo"
            target="_blank"
            rel="noopener"
            aria-label="LinkedIn"
          >
            <svg viewBox="0 0 24 24" width="24" height="24" fill="currentColor" aria-hidden="true">
              <path d="M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z" />
            </svg>
          </a>
          <a href="https://t.me/DROOdotFOO" target="_blank" rel="noopener" aria-label="Telegram">
            <svg viewBox="0 0 24 24" width="24" height="24" fill="currentColor" aria-hidden="true">
              <path d="M11.944 0A12 12 0 0 0 0 12a12 12 0 0 0 12 12 12 12 0 0 0 12-12A12 12 0 0 0 12 0a12 12 0 0 0-.056 0zm4.962 7.224c.1-.002.321.023.465.14a.506.506 0 0 1 .171.325c.016.093.036.306.02.472-.18 1.898-.962 6.502-1.36 8.627-.168.9-.499 1.201-.82 1.23-.696.065-1.225-.46-1.9-.902-1.056-.693-1.653-1.124-2.678-1.8-1.185-.78-.417-1.21.258-1.91.177-.184 3.247-2.977 3.307-3.23.007-.032.014-.15-.056-.212s-.174-.041-.249-.024c-.106.024-1.793 1.14-5.061 3.345-.48.33-.913.49-1.302.48-.428-.008-1.252-.241-1.865-.44-.752-.245-1.349-.374-1.297-.789.027-.216.325-.437.893-.663 3.498-1.524 5.83-2.529 6.998-3.014 3.332-1.386 4.025-1.627 4.476-1.635z" />
            </svg>
          </a>
          <a href="mailto:drew@axol.io" aria-label="Email">
            <svg viewBox="0 0 24 24" width="24" height="24" fill="currentColor" aria-hidden="true">
              <path d="M20 4H4c-1.1 0-1.99.9-1.99 2L2 18c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 4l-8 5-8-5V6l8 5 8-5v2z" />
            </svg>
          </a>
          <a
            href="https://discord.com/users/droodotfoo"
            target="_blank"
            rel="noopener"
            aria-label="Discord"
          >
            <svg viewBox="0 0 24 24" width="24" height="24" fill="currentColor" aria-hidden="true">
              <path d="M20.317 4.37a19.791 19.791 0 0 0-4.885-1.515.074.074 0 0 0-.079.037c-.21.375-.444.864-.608 1.25a18.27 18.27 0 0 0-5.487 0 12.64 12.64 0 0 0-.617-1.25.077.077 0 0 0-.079-.037A19.736 19.736 0 0 0 3.677 4.37a.07.07 0 0 0-.032.027C.533 9.046-.32 13.58.099 18.057a.082.082 0 0 0 .031.057 19.9 19.9 0 0 0 5.993 3.03.078.078 0 0 0 .084-.028 14.09 14.09 0 0 0 1.226-1.994.076.076 0 0 0-.041-.106 13.107 13.107 0 0 1-1.872-.892.077.077 0 0 1-.008-.128 10.2 10.2 0 0 0 .372-.292.074.074 0 0 1 .077-.01c3.928 1.793 8.18 1.793 12.062 0a.074.074 0 0 1 .078.01c.12.098.246.198.373.292a.077.077 0 0 1-.006.127 12.299 12.299 0 0 1-1.873.892.077.077 0 0 0-.041.107c.36.698.772 1.362 1.225 1.993a.076.076 0 0 0 .084.028 19.839 19.839 0 0 0 6.002-3.03.077.077 0 0 0 .032-.054c.5-5.177-.838-9.674-3.549-13.66a.061.061 0 0 0-.031-.03zM8.02 15.33c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.956-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.956 2.418-2.157 2.418zm7.975 0c-1.183 0-2.157-1.085-2.157-2.419 0-1.333.955-2.419 2.157-2.419 1.21 0 2.176 1.096 2.157 2.42 0 1.333-.946 2.418-2.157 2.418z" />
            </svg>
          </a>
        </div>
      </section>

      <hr />

      <section class="section-spaced">
        <h2 class="section-header-bordered">XOCHI NETWORKS</h2>
        <p class="text-muted mb-2">
          <a href="https://xochi.fi" target="_blank" rel="noopener">xochi.fi</a>
          -- private execution infrastructure. Live on 5 chains.
        </p>
        <div class="network-status">
          <div class="network-item">
            <img
              src={~p"/images/icons/blockchain/ethereum.svg"}
              width="24"
              height="24"
              alt=""
              aria-hidden="true"
            />
            <span>Ethereum</span>
            <span class="status-live">live</span>
          </div>
          <div class="network-item">
            <img
              src={~p"/images/icons/blockchain/arbitrum.svg"}
              width="24"
              height="24"
              alt=""
              aria-hidden="true"
            />
            <span>Arbitrum</span>
            <span class="status-live">live</span>
          </div>
          <div class="network-item">
            <img
              src={~p"/images/icons/blockchain/optimism.svg"}
              width="24"
              height="24"
              alt=""
              aria-hidden="true"
            />
            <span>Optimism</span>
            <span class="status-live">live</span>
          </div>
          <div class="network-item">
            <img
              src={~p"/images/icons/blockchain/base.svg"}
              width="24"
              height="24"
              alt=""
              aria-hidden="true"
            />
            <span>Base</span>
            <span class="status-live">live</span>
          </div>
          <div class="network-item">
            <img
              src={~p"/images/icons/blockchain/polygon.svg"}
              width="24"
              height="24"
              alt=""
              aria-hidden="true"
            />
            <span>Polygon</span>
            <span class="status-live">live</span>
          </div>
          <div class="network-item">
            <img
              src={~p"/images/icons/blockchain/aztec.svg"}
              width="24"
              height="24"
              alt=""
              aria-hidden="true"
            />
            <span>Aztec</span>
            <span class="status-pending">pending</span>
          </div>
        </div>
      </section>

      <hr />

      <section class="section-spaced">
        <h2 class="section-header-bordered">MESSAGE</h2>
        <div class="contact-form">
          <.form
            for={%{}}
            id="contact-form"
            phx-submit="submit"
            phx-change="validate"
            phx-hook="FocusHook"
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
              autofocus
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
              placeholder="What's on your mind?"
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

          <%= case @submission_status do %>
            <% {type, message} -> %>
              <.status_message type={type} message={message} />
            <% nil -> %>
          <% end %>

          {render_rate_limit_info(@rate_limit_status)}
        </div>
      </section>
    </.page_layout>
    """
  end
end
