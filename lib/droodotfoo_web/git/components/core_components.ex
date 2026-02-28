defmodule DroodotfooWeb.Git.CoreComponents do
  @moduledoc """
  Core UI components for git.droo.foo.

  Terminal aesthetic: Monaspace fonts, sharp corners (no border-radius),
  2px borders, color inversion on hover.
  """
  use Phoenix.Component
  use Gettext, backend: DroodotfooWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices with terminal styling.
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={["flash", @kind == :info && "flash-info", @kind == :error && "flash-error"]}
      {@rest}
    >
      <div class="flex items-start gap-2">
        <span :if={@kind == :info}>[i]</span>
        <span :if={@kind == :error}>[!]</span>
        <div class="flex-1">
          <p :if={@title} class="font-bold">{@title}</p>
          <p>{msg}</p>
        </div>
        <button type="button" class="flash-close" aria-label={gettext("close")}>
          [x]
        </button>
      </div>
    </div>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js, to: selector, time: 100)
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js, to: selector, time: 100)
  end
end
