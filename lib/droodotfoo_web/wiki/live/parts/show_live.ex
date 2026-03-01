defmodule DroodotfooWeb.Wiki.Parts.ShowLive do
  @moduledoc """
  Part detail view with vehicle fitment.
  """

  use Phoenix.LiveView, layout: false

  alias DroodotfooWeb.Wiki.Layouts
  alias Droodotfoo.Wiki.Parts
  alias Droodotfoo.Wiki.Parts.{Part, Vehicle}

  import Phoenix.Component

  @impl true
  def mount(%{"number" => number}, _session, socket) do
    case Parts.get_part_by_number(number) do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Part not found")
         |> push_navigate(to: "/parts")}

      part ->
        part = Parts.get_part_with_vehicles(part.id)
        fitments = Parts.list_fitments(part)
        breadcrumbs = [{"Home", "/"}, {"Parts", "/parts"}, {part.name, "/parts/#{number}"}]

        {:ok,
         socket
         |> assign(page_title: part.name)
         |> assign(current_path: "/parts/#{number}")
         |> assign(breadcrumbs: breadcrumbs)
         |> assign(part: part)
         |> assign(fitments: fitments)}
    end
  end

  @impl true
  def handle_event("delete", _params, socket) do
    case Parts.delete_part(socket.assigns.part) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Part deleted")
         |> push_navigate(to: "/parts")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete part")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path}>
      <Layouts.breadcrumbs items={@breadcrumbs} />

      <div class="max-w-4xl mx-auto px-4 py-8">
        <header class="flex items-start justify-between mb-6">
          <div>
            <h1 class="text-2xl font-mono font-bold">{@part.name}</h1>
            <p class="text-lg text-zinc-400 font-mono">{@part.part_number}</p>
          </div>

          <div class="flex gap-2">
            <.link
              navigate={"/parts/add?clipper=1&part_number=#{@part.part_number}"}
              class="btn-secondary text-sm"
            >
              Edit
            </.link>
            <button
              phx-click="delete"
              data-confirm="Delete this part?"
              class="btn-danger text-sm"
            >
              Delete
            </button>
          </div>
        </header>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
          <div class="lg:col-span-2 space-y-6">
            <section :if={@part.description} class="prose prose-invert max-w-none">
              <p>{@part.description}</p>
            </section>

            <section :if={@part.notes}>
              <h2 class="text-sm font-mono font-bold text-zinc-400 mb-2">Notes</h2>
              <p class="text-zinc-300">{@part.notes}</p>
            </section>

            <section :if={@fitments != []}>
              <h2 class="text-sm font-mono font-bold text-zinc-400 mb-3">Fits These Vehicles</h2>
              <div class="space-y-2">
                <div
                  :for={fitment <- @fitments}
                  class="flex items-center justify-between bg-zinc-800/50 rounded px-3 py-2"
                >
                  <span class="font-mono text-sm">
                    {Vehicle.display_name(fitment.vehicle)}
                  </span>
                  <span :if={fitment.verified} class="text-green-400 text-xs">Verified</span>
                </div>
              </div>
            </section>
          </div>

          <aside class="space-y-4">
            <div class="border border-zinc-800 rounded-lg p-4">
              <dl class="space-y-3 text-sm">
                <div :if={@part.category}>
                  <dt class="text-zinc-500 font-mono">Category</dt>
                  <dd class="font-mono">{format_category(@part.category)}</dd>
                </div>

                <div :if={@part.manufacturer}>
                  <dt class="text-zinc-500 font-mono">Manufacturer</dt>
                  <dd class="font-mono">{@part.manufacturer}</dd>
                </div>

                <div :if={@part.price_cents}>
                  <dt class="text-zinc-500 font-mono">Price</dt>
                  <dd class="font-mono text-lg">{Part.format_price(@part)}</dd>
                </div>

                <div :if={@part.oem_numbers != []}>
                  <dt class="text-zinc-500 font-mono">OEM Numbers</dt>
                  <dd class="font-mono">
                    <span
                      :for={oem <- @part.oem_numbers}
                      class="inline-block bg-zinc-800 rounded px-2 py-0.5 mr-1 mb-1 text-xs"
                    >
                      {oem}
                    </span>
                  </dd>
                </div>

                <div :if={@part.cross_references != []}>
                  <dt class="text-zinc-500 font-mono">Cross References</dt>
                  <dd class="font-mono">
                    <span
                      :for={xref <- @part.cross_references}
                      class="inline-block bg-zinc-800 rounded px-2 py-0.5 mr-1 mb-1 text-xs"
                    >
                      {xref}
                    </span>
                  </dd>
                </div>

                <div :if={@part.source_url}>
                  <dt class="text-zinc-500 font-mono">Source</dt>
                  <dd>
                    <a
                      href={@part.source_url}
                      target="_blank"
                      rel="noopener"
                      class="text-blue-400 hover:underline font-mono text-xs break-all"
                    >
                      {URI.parse(@part.source_url).host}
                    </a>
                  </dd>
                </div>
              </dl>
            </div>

            <div class="text-xs text-zinc-600 font-mono">
              Added: {Calendar.strftime(@part.inserted_at, "%Y-%m-%d")}
            </div>
          </aside>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp format_category(cat) do
    cat
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end
end
