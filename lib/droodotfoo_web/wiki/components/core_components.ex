defmodule DroodotfooWeb.Wiki.CoreComponents do
  @moduledoc """
  Core UI components for wiki.droo.foo / lib.droo.foo.

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

  @doc """
  Renders a button with terminal styling.
  """
  attr :rest, :global, include: ~w(href navigate patch method download name value disabled)
  attr :class, :any, default: nil
  attr :variant, :string, default: nil
  slot :inner_block, required: true

  def button(%{rest: rest} = assigns) do
    base_class = "btn"

    variant_class =
      case assigns[:variant] do
        "primary" -> "bg-accent"
        _ -> ""
      end

    assigns = assign(assigns, :computed_class, [base_class, variant_class, assigns.class])

    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={@computed_class} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      ~H"""
      <button class={@computed_class} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  @doc """
  Renders an input with label and error messages.
  """
  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week hidden)

  attr :field, Phoenix.HTML.FormField,
    doc: "a form field struct retrieved from the form, for example: @form[:email]"

  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :any, default: nil, doc: "the input class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  def input(%{type: "hidden"} = assigns) do
    ~H"""
    <input type="hidden" id={@id} name={@name} value={@value} {@rest} />
    """
  end

  def input(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="mb-2">
      <label :if={@label} class="block text-sm text-muted mb-1">{@label}</label>
      <textarea
        id={@id}
        name={@name}
        class={@class || "w-full"}
        {@rest}
      >{Phoenix.HTML.Form.normalize_value("textarea", @value)}</textarea>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def input(assigns) do
    ~H"""
    <div class="mb-2">
      <label :if={@label} class="block text-sm text-muted mb-1">{@label}</label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={@class || "w-full"}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  defp error(assigns) do
    ~H"""
    <p class="mt-1 text-sm" style="color: #ff4444;">
      [!] {render_slot(@inner_block)}
    </p>
    """
  end

  ## JS Commands

  def show(js \\ %JS{}, selector) do
    JS.show(js, to: selector, time: 100)
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js, to: selector, time: 100)
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(DroodotfooWeb.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(DroodotfooWeb.Gettext, "errors", msg, opts)
    end
  end
end
