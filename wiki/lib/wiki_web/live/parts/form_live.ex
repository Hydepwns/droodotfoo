defmodule WikiWeb.Parts.FormLive do
  @moduledoc """
  Form for adding/editing parts.

  Supports manual entry and browser clipper import via URL params.
  """

  use WikiWeb, :live_view

  alias Wiki.Parts
  alias Wiki.Parts.Part

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Add Part")
     |> assign(form: to_form(Parts.change_part(%Part{})))
     |> assign(vehicles: [])
     |> assign(vehicle_form: to_form(%{"year" => "", "make" => "", "model" => ""}))}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    # Support pre-filling from browser clipper
    if Map.has_key?(params, "clipper") do
      form = prefill_from_clipper(params)
      {:noreply, assign(socket, form: form)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"part" => part_params}, socket) do
    changeset =
      %Part{}
      |> Parts.change_part(part_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"part" => part_params}, socket) do
    case Parts.create_part(part_params) do
      {:ok, part} ->
        # Add vehicle fitments
        Enum.each(socket.assigns.vehicles, fn v ->
          with {:ok, vehicle} <- Parts.get_or_create_vehicle(v) do
            Parts.add_fitment(part, vehicle)
          end
        end)

        {:noreply,
         socket
         |> put_flash(:info, "Part created successfully")
         |> push_navigate(to: ~p"/parts/#{part.part_number}")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("add_vehicle", %{"vehicle" => vehicle_params}, socket) do
    vehicle = %{
      year: parse_int(vehicle_params["year"]),
      make: vehicle_params["make"],
      model: vehicle_params["model"],
      engine: vehicle_params["engine"],
      trim: vehicle_params["trim"]
    }

    if vehicle.year && vehicle.make != "" && vehicle.model != "" do
      vehicles = socket.assigns.vehicles ++ [vehicle]

      {:noreply,
       socket
       |> assign(vehicles: vehicles)
       |> assign(vehicle_form: to_form(%{"year" => "", "make" => "", "model" => ""}))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("remove_vehicle", %{"index" => index}, socket) do
    index = String.to_integer(index)
    vehicles = List.delete_at(socket.assigns.vehicles, index)
    {:noreply, assign(socket, vehicles: vehicles)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-2xl mx-auto px-4 py-8">
        <h1 class="text-2xl font-mono font-bold mb-6">Add Part</h1>

        <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-6">
          <div class="grid grid-cols-2 gap-4">
            <.input field={@form[:part_number]} label="Part Number" required />
            <.input field={@form[:name]} label="Name" required />
          </div>

          <.input field={@form[:description]} type="textarea" label="Description" rows="3" />

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-sm font-medium text-zinc-300 mb-1">Category</label>
              <select name="part[category]" class="input w-full">
                <%= for cat <- Part.categories() do %>
                  <option value={cat} selected={to_string(cat) == to_string(@form[:category].value)}>
                    {format_category(cat)}
                  </option>
                <% end %>
              </select>
            </div>
            <.input field={@form[:manufacturer]} label="Manufacturer" />
          </div>

          <div class="grid grid-cols-2 gap-4">
            <.input field={@form[:source_url]} label="Source URL" type="url" />
            <.input field={@form[:price_cents]} label="Price (cents)" type="number" />
          </div>

          <.input field={@form[:notes]} type="textarea" label="Notes" rows="2" />

          <div class="border-t border-zinc-800 pt-6">
            <h2 class="text-lg font-mono font-bold mb-4">Vehicle Fitment</h2>

            <div :if={@vehicles != []} class="mb-4 space-y-2">
              <div
                :for={{v, idx} <- Enum.with_index(@vehicles)}
                class="flex items-center justify-between bg-zinc-800/50 rounded px-3 py-2"
              >
                <span class="font-mono text-sm">
                  {v.year} {v.make} {v.model}
                  <span :if={v.engine} class="text-zinc-500">({v.engine})</span>
                </span>
                <button
                  type="button"
                  phx-click="remove_vehicle"
                  phx-value-index={idx}
                  class="text-red-400 hover:text-red-300"
                >
                  x
                </button>
              </div>
            </div>

            <div class="grid grid-cols-5 gap-2">
              <input
                type="number"
                name="vehicle[year]"
                placeholder="Year"
                class="input"
                min="1900"
                max="2100"
              />
              <input type="text" name="vehicle[make]" placeholder="Make" class="input" />
              <input type="text" name="vehicle[model]" placeholder="Model" class="input" />
              <input type="text" name="vehicle[engine]" placeholder="Engine" class="input" />
              <button
                type="button"
                phx-click="add_vehicle"
                class="btn-secondary"
              >
                Add
              </button>
            </div>
          </div>

          <div class="flex justify-end gap-4 pt-4">
            <.link navigate={~p"/parts"} class="btn-secondary">Cancel</.link>
            <button type="submit" class="btn-primary">Save Part</button>
          </div>
        </.form>
      </div>
    </Layouts.app>
    """
  end

  defp prefill_from_clipper(params) do
    attrs = %{
      "part_number" => params["part_number"] || "",
      "name" => params["name"] || params["title"] || "",
      "description" => params["description"] || "",
      "manufacturer" => params["manufacturer"] || params["brand"] || "",
      "source_url" => params["url"] || "",
      "price_cents" => params["price"] || ""
    }

    %Part{}
    |> Parts.change_part(attrs)
    |> to_form()
  end

  defp format_category(cat) do
    cat
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil

  defp parse_int(str) when is_binary(str) do
    case Integer.parse(str) do
      {n, _} -> n
      :error -> nil
    end
  end
end
