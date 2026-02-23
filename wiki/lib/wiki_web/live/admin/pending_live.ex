defmodule WikiWeb.Admin.PendingLive do
  @moduledoc """
  Admin pending review dashboard (Tailnet-only).

  Shows community edit suggestions with diff display.
  Admins can approve or reject edits.
  """

  use WikiWeb, :live_view

  alias Wiki.Content
  alias Wiki.Cache

  @impl true
  def mount(_params, _session, socket) do
    pending_edits = Content.list_pending_edits(status: :pending)
    counts = Content.count_pending_edits_by_status()

    {:ok,
     assign(socket,
       pending_edits: pending_edits,
       counts: counts,
       selected: nil,
       original_html: nil,
       reviewer_note: "",
       page_title: "Pending Review"
     )}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    case Content.get_pending_edit(String.to_integer(id)) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, "Edit not found")
         |> push_navigate(to: ~p"/admin/pending")}

      edit ->
        original_html = load_original_html(edit.article)
        {:noreply, assign(socket, selected: edit, original_html: original_html)}
    end
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, assign(socket, selected: nil, original_html: nil)}
  end

  @impl true
  def handle_event("select", %{"id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/pending/#{id}")}
  end

  def handle_event("update_note", %{"value" => note}, socket) do
    {:noreply, assign(socket, reviewer_note: note)}
  end

  def handle_event("approve", _params, socket) do
    case Content.approve_pending_edit(socket.assigns.selected, socket.assigns.reviewer_note) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Edit approved and applied")
         |> reload_and_clear()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to approve edit")}
    end
  end

  def handle_event("reject", _params, socket) do
    case Content.reject_pending_edit(socket.assigns.selected, socket.assigns.reviewer_note) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Edit rejected")
         |> reload_and_clear()}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to reject edit")}
    end
  end

  def handle_event("back", _params, socket) do
    {:noreply, push_patch(socket, to: ~p"/admin/pending")}
  end

  defp reload_and_clear(socket) do
    pending_edits = Content.list_pending_edits(status: :pending)
    counts = Content.count_pending_edits_by_status()

    socket
    |> assign(pending_edits: pending_edits, counts: counts, selected: nil, reviewer_note: "")
    |> push_patch(to: ~p"/admin/pending")
  end

  defp load_original_html(article) do
    Cache.fetch_html(article)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-7xl mx-auto px-4 py-8">
        <div class="flex items-center justify-between mb-6">
          <h1 class="text-2xl font-mono font-bold">Pending Review</h1>
          <.status_counts counts={@counts} />
        </div>

        <div class="flex gap-6">
          <.queue_list edits={@pending_edits} selected={@selected} />
          <.detail_view
            :if={@selected}
            edit={@selected}
            original_html={@original_html}
            reviewer_note={@reviewer_note}
          />
          <.empty_detail :if={!@selected && @pending_edits != []} />
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp status_counts(assigns) do
    ~H"""
    <div class="flex gap-4 text-sm font-mono">
      <span class="text-yellow-400">
        Pending: {Map.get(@counts, :pending, 0)}
      </span>
      <span class="text-green-400">
        Approved: {Map.get(@counts, :approved, 0)}
      </span>
      <span class="text-red-400">
        Rejected: {Map.get(@counts, :rejected, 0)}
      </span>
    </div>
    """
  end

  defp queue_list(assigns) do
    ~H"""
    <div class="w-80 flex-shrink-0">
      <div class="border border-zinc-800 rounded-lg overflow-hidden">
        <div class="bg-zinc-900 px-4 py-2 border-b border-zinc-800">
          <span class="text-sm font-mono text-zinc-400">Queue ({length(@edits)})</span>
        </div>
        <div :if={@edits == []} class="p-4 text-zinc-500 font-mono text-sm">
          No pending edits.
        </div>
        <ul class="divide-y divide-zinc-800">
          <li
            :for={edit <- @edits}
            phx-click="select"
            phx-value-id={edit.id}
            class={[
              "px-4 py-3 cursor-pointer hover:bg-zinc-800/50 transition-colors",
              @selected && @selected.id == edit.id && "bg-zinc-800"
            ]}
          >
            <div class="font-mono text-sm text-white truncate">
              {edit.article.title}
            </div>
            <div class="flex items-center gap-2 mt-1 text-xs text-zinc-500 font-mono">
              <span>{format_source(edit.article.source)}</span>
              <span class="text-zinc-600">|</span>
              <span>{format_time(edit.inserted_at)}</span>
            </div>
            <div :if={edit.submitter_email} class="mt-1 text-xs text-zinc-500 font-mono truncate">
              {edit.submitter_email}
            </div>
          </li>
        </ul>
      </div>
    </div>
    """
  end

  defp empty_detail(assigns) do
    ~H"""
    <div class="flex-1 border border-zinc-800 rounded-lg p-8 flex items-center justify-center">
      <span class="text-zinc-500 font-mono">Select an edit to review</span>
    </div>
    """
  end

  defp detail_view(assigns) do
    ~H"""
    <div class="flex-1 border border-zinc-800 rounded-lg overflow-hidden">
      <div class="bg-zinc-900 px-4 py-3 border-b border-zinc-800 flex items-center justify-between">
        <div>
          <h2 class="font-mono font-bold text-white">{@edit.article.title}</h2>
          <div class="text-xs text-zinc-500 font-mono mt-1">
            {format_source(@edit.article.source)} | Submitted {format_time(@edit.inserted_at)}
          </div>
        </div>
        <button phx-click="back" class="text-zinc-400 hover:text-white text-sm font-mono">
          [x]
        </button>
      </div>

      <div :if={@edit.reason} class="px-4 py-3 border-b border-zinc-800 bg-zinc-900/50">
        <div class="text-xs text-zinc-500 font-mono mb-1">Reason:</div>
        <div class="text-sm text-zinc-300 font-mono">{@edit.reason}</div>
      </div>

      <div class="px-4 py-3 border-b border-zinc-800">
        <div class="text-xs text-zinc-500 font-mono mb-2">Changes:</div>
        <div class="font-mono text-sm max-h-96 overflow-y-auto bg-zinc-950 rounded p-3">
          <.diff_display original={@original_html} suggested={@edit.suggested_content} />
        </div>
      </div>

      <div class="px-4 py-3 border-b border-zinc-800">
        <label class="text-xs text-zinc-500 font-mono mb-1 block">Reviewer note (optional):</label>
        <textarea
          phx-keyup="update_note"
          value={@reviewer_note}
          rows="2"
          class="w-full bg-zinc-900 border border-zinc-700 rounded px-3 py-2 font-mono text-sm text-white focus:outline-none focus:border-zinc-500"
          placeholder="Add a note..."
        ></textarea>
      </div>

      <div class="px-4 py-3 flex gap-3">
        <button
          phx-click="approve"
          class="px-4 py-2 bg-green-700 hover:bg-green-600 text-white font-mono text-sm rounded transition-colors"
        >
          Approve
        </button>
        <button
          phx-click="reject"
          class="px-4 py-2 bg-red-700 hover:bg-red-600 text-white font-mono text-sm rounded transition-colors"
        >
          Reject
        </button>
      </div>
    </div>
    """
  end

  defp diff_display(assigns) do
    diff = String.myers_difference(assigns.original || "", assigns.suggested || "")
    assigns = assign(assigns, :diff, diff)

    ~H"""
    <pre class="whitespace-pre-wrap"><%= for {op, text} <- @diff do %><span class={diff_class(op)}><%= text %></span><% end %></pre>
    """
  end

  defp diff_class(:eq), do: "text-zinc-400"
  defp diff_class(:del), do: "bg-red-900/50 text-red-300 line-through"
  defp diff_class(:ins), do: "bg-green-900/50 text-green-300"

  defp format_source(:osrs), do: "OSRS"
  defp format_source(:nlab), do: "nLab"
  defp format_source(:wikipedia), do: "Wikipedia"
  defp format_source(:vintage_machinery), do: "Vintage"
  defp format_source(:wikiart), do: "WikiArt"
  defp format_source(s), do: to_string(s)

  defp format_time(datetime) do
    now = DateTime.utc_now()
    diff = DateTime.diff(now, datetime, :second)

    cond do
      diff < 60 -> "just now"
      diff < 3600 -> "#{div(diff, 60)}m ago"
      diff < 86400 -> "#{div(diff, 3600)}h ago"
      true -> Calendar.strftime(datetime, "%Y-%m-%d")
    end
  end
end
