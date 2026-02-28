defmodule DroodotfooWeb.Wiki.Admin.RedirectsLive do
  @moduledoc """
  Admin page for managing wiki redirects.

  Tailnet-only access. Provides CRUD interface for redirects.
  """

  use Phoenix.LiveView, layout: false

  alias DroodotfooWeb.Wiki.Layouts
  alias Droodotfoo.Wiki.Content

  @sources ~w(osrs nlab wikipedia vintage_machinery wikiart)a

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       redirects: Content.list_redirects(),
       source_filter: nil,
       sources: @sources,
       form: to_form(%{"source" => "", "from_slug" => "", "to_slug" => ""}),
       page_title: "Redirect Admin",
       current_path: "/admin/redirects"
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path}>
      <div class="max-w-6xl mx-auto px-4 py-8">
        <div class="flex items-center justify-between mb-8">
          <h1 class="text-2xl font-mono font-bold">Redirect Admin</h1>
          <.link navigate="/admin/sync" class="text-zinc-400 hover:text-white font-mono text-sm">
            {"[<- Dashboard]"}
          </.link>
        </div>

        <section class="mb-10">
          <h2 class="text-lg font-mono font-bold mb-4 text-zinc-400">Add Redirect</h2>
          <.form for={@form} phx-submit="create" class="flex gap-2 items-end flex-wrap">
            <div>
              <label class="block text-sm text-zinc-500 mb-1">Source</label>
              <select name="source" class="bg-zinc-800 border-zinc-700 rounded px-3 py-1.5 font-mono">
                <option :for={source <- @sources} value={source}>{source_label(source)}</option>
              </select>
            </div>
            <div class="flex-1 min-w-[200px]">
              <label class="block text-sm text-zinc-500 mb-1">From Slug</label>
              <input
                type="text"
                name="from_slug"
                placeholder="old-page-name"
                class="w-full bg-zinc-800 border-zinc-700 rounded px-3 py-1.5 font-mono"
                required
              />
            </div>
            <div class="flex-1 min-w-[200px]">
              <label class="block text-sm text-zinc-500 mb-1">To Slug</label>
              <input
                type="text"
                name="to_slug"
                placeholder="new-page-name"
                class="w-full bg-zinc-800 border-zinc-700 rounded px-3 py-1.5 font-mono"
                required
              />
            </div>
            <button
              type="submit"
              class="px-4 py-1.5 bg-blue-600 hover:bg-blue-500 rounded font-mono text-sm"
            >
              Add
            </button>
          </.form>
        </section>

        <section>
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-lg font-mono font-bold text-zinc-400">
              Redirects ({length(@redirects)})
            </h2>
            <div class="flex gap-2">
              <button
                :for={source <- [nil | @sources]}
                phx-click="filter"
                phx-value-source={source || ""}
                class={[
                  "px-2 py-1 rounded font-mono text-xs",
                  @source_filter == source && "bg-zinc-600",
                  @source_filter != source && "bg-zinc-800 hover:bg-zinc-700"
                ]}
              >
                {if source, do: source_label(source), else: "All"}
              </button>
            </div>
          </div>

          <.redirects_table redirects={@redirects} />
        </section>
      </div>
    </Layouts.app>
    """
  end

  defp redirects_table(assigns) do
    ~H"""
    <div class="overflow-x-auto">
      <table class="w-full font-mono text-sm">
        <thead class="text-left text-zinc-500 border-b border-zinc-800">
          <tr>
            <th class="py-2 pr-4">Source</th>
            <th class="py-2 pr-4">From</th>
            <th class="py-2 pr-4">To</th>
            <th class="py-2 pr-4">Created</th>
            <th class="py-2"></th>
          </tr>
        </thead>
        <tbody>
          <tr :for={redirect <- @redirects} class="border-b border-zinc-800/50 hover:bg-zinc-800/30">
            <td class="py-2 pr-4">
              <span class="px-2 py-0.5 bg-zinc-700 rounded text-xs">
                {source_label(redirect.source)}
              </span>
            </td>
            <td class="py-2 pr-4 text-zinc-300">{redirect.from_slug}</td>
            <td class="py-2 pr-4 text-green-400">{redirect.to_slug}</td>
            <td class="py-2 pr-4 text-zinc-500">{format_date(redirect.inserted_at)}</td>
            <td class="py-2 text-right">
              <button
                phx-click="delete"
                phx-value-id={redirect.id}
                data-confirm="Delete this redirect?"
                class="text-red-400 hover:text-red-300 text-xs"
              >
                [delete]
              </button>
            </td>
          </tr>
        </tbody>
      </table>

      <div :if={@redirects == []} class="py-8 text-center text-zinc-500 font-mono">
        No redirects found.
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("create", %{"source" => source, "from_slug" => from, "to_slug" => to}, socket) do
    source_atom = String.to_existing_atom(source)

    case Content.create_redirect(source_atom, from, to) do
      {:ok, _redirect} ->
        {:noreply,
         socket
         |> put_flash(:info, "Redirect created")
         |> assign(redirects: Content.list_redirects(source: socket.assigns.source_filter))}

      {:error, changeset} ->
        {:noreply, put_flash(socket, :error, "Failed: #{inspect(changeset.errors)}")}
    end
  end

  def handle_event("delete", %{"id" => id}, socket) do
    case Content.delete_redirect(String.to_integer(id)) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Redirect deleted")
         |> assign(redirects: Content.list_redirects(source: socket.assigns.source_filter))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete redirect")}
    end
  end

  def handle_event("filter", %{"source" => ""}, socket) do
    {:noreply,
     assign(socket,
       source_filter: nil,
       redirects: Content.list_redirects()
     )}
  end

  def handle_event("filter", %{"source" => source}, socket) do
    source_atom = String.to_existing_atom(source)

    {:noreply,
     assign(socket,
       source_filter: source_atom,
       redirects: Content.list_redirects(source: source_atom)
     )}
  end

  defp source_label(:osrs), do: "OSRS"
  defp source_label(:nlab), do: "nLab"
  defp source_label(:wikipedia), do: "Wikipedia"
  defp source_label(:vintage_machinery), do: "VintageMachinery"
  defp source_label(:wikiart), do: "WikiArt"
  defp source_label(source), do: to_string(source)

  defp format_date(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d")
  end
end
