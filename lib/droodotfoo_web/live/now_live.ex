defmodule DroodotfooWeb.NowLive do
  @moduledoc """
  Now page showing current focus and activities.
  Inspired by Derek Sivers' /now page movement (nownownow.com).
  Updated manually to reflect current status.
  """

  use DroodotfooWeb, :live_view
  alias Droodotfoo.Resume.ResumeData
  import DroodotfooWeb.ContentComponents

  @impl true
  def mount(_params, _session, socket) do
    resume = ResumeData.get_resume_data()
    last_updated = ~D[2025-01-23]

    socket
    |> assign(:resume, resume)
    |> assign(:last_updated, last_updated)
    |> assign(:page_title, "Now")
    |> assign(:current_path, "/now")
    |> then(&{:ok, &1})
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.page_layout page_title="Now" page_description="What I'm currently focused on" current_path={@current_path}>
      <section class="about-section">
        <p class="text-muted mb-2">
          Last updated: {Date.to_string(@last_updated)}
        </p>

        <h3 class="mt-2">Building</h3>
        <p>
          Leading <strong>axol.io</strong>, developing production-grade FOSS blockchain infrastructure:
        </p>
        <ul>
          <li>
            <strong>mana</strong> - Ethereum client implementation in Elixir
          </li>
          <li>
            <strong>raxol</strong> - Terminal UI framework for LiveView applications
          </li>
          <li>
            <strong>riddler</strong> - Cross-protocol bridge rebalancing bot (Across Protocol, Wormhole)
          </li>
        </ul>

        <h3 class="mt-2">Learning</h3>
        <p>Currently deep-diving into:</p>
        <ul>
          <li>Ethereum protocol internals and EVM optimization</li>
          <li>Cosmos SDK and IBC protocol design</li>
          <li>Cross-chain bridge architecture and security</li>
          <li>Functional programming patterns in Elixir/Erlang/OTP</li>
        </ul>

        <h3 class="mt-2">Location</h3>
        <p>
          Based in <strong>{@resume.personal_info.location}</strong> ({@resume.personal_info.timezone}).
          Working remotely on blockchain infrastructure, splitting time between protocol research,
          open-source development, and validator operations.
        </p>

        <%= if @resume.availability == "open_to_consulting" do %>
          <h3 class="mt-2">Availability</h3>
          <p>
            Currently <strong>open to consulting</strong> for blockchain infrastructure projects.
            Specializing in Cosmos SDK, Ethereum protocol, and validator operations.
          </p>
        <% end %>

        <hr class="section-divider" />

        <p class="text-muted">
          This page follows the <a
            href="https://nownownow.com/about"
            target="_blank"
            rel="noopener"
          >/now page movement</a>
          by Derek Sivers. It's manually updated whenever my focus significantly shifts.
        </p>
      </section>
    </.page_layout>
    """
  end
end
