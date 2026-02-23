defmodule WikiWeb.ArticleLive do
  @moduledoc """
  Single LiveView for all wiki sources.
  Terminal aesthetic styling matching droo.foo.
  """

  use WikiWeb, :live_view

  alias Wiki.Content
  alias Wiki.CrossLinks

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       article: nil,
       html: "",
       loading: true,
       error: nil,
       related: [],
       show_edit_form: false,
       edit_form: nil,
       edit_submitting: false
     )}
  end

  @impl true
  def handle_params(params, uri, socket) do
    {source, slug} = source_and_slug_from_uri(uri, params)

    current_path = URI.parse(uri).path

    socket =
      socket
      |> assign(source: source, slug: slug, loading: true, error: nil, related: [])
      |> assign(page_title: format_title(slug), current_path: current_path)

    if connected?(socket) do
      send(self(), {:load_article, source, slug})
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:load_article, source, slug}, socket) do
    case Content.get_article(source, slug) do
      {:ok, article, html} ->
        related = CrossLinks.get_related(article, limit: 5)

        {:noreply,
         socket
         |> assign(article: article, html: html, loading: false, related: related)
         |> assign(page_title: String.upcase(article.title))}

      {:error, :not_found} ->
        {:noreply, assign(socket, loading: false, error: :not_found)}
    end
  end

  @impl true
  def handle_event("show_edit_form", _params, socket) do
    form =
      %{"suggested_content" => socket.assigns.html, "reason" => "", "submitter_email" => ""}
      |> to_form()

    {:noreply, assign(socket, show_edit_form: true, edit_form: form)}
  end

  def handle_event("hide_edit_form", _params, socket) do
    {:noreply, assign(socket, show_edit_form: false, edit_form: nil)}
  end

  def handle_event(
        "validate_edit",
        %{"suggested_content" => _, "reason" => _, "submitter_email" => _} = params,
        socket
      ) do
    {:noreply, assign(socket, edit_form: to_form(params))}
  end

  def handle_event("submit_edit", params, socket) do
    ip = get_client_ip(socket)

    attrs = %{
      article_id: socket.assigns.article.id,
      suggested_content: params["suggested_content"],
      reason: params["reason"],
      submitter_email: params["submitter_email"],
      submitter_ip: ip
    }

    case Content.create_pending_edit(attrs) do
      {:ok, _edit} ->
        {:noreply,
         socket
         |> put_flash(:info, "Edit suggestion submitted. Thank you!")
         |> assign(show_edit_form: false, edit_form: nil)}

      {:error, :rate_limited} ->
        {:noreply,
         socket
         |> put_flash(:error, "Rate limit reached. Please try again later.")
         |> assign(edit_submitting: false)}

      {:error, changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to submit: #{format_errors(changeset)}")
         |> assign(edit_submitting: false)}
    end
  end

  defp format_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {k, v} -> "#{k}: #{Enum.join(v, ", ")}" end)
    |> Enum.join("; ")
  end

  defp get_client_ip(socket) do
    case get_connect_info(socket, :peer_data) do
      %{address: addr} -> :inet.ntoa(addr) |> to_string()
      _ -> "unknown"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_path={@current_path}>
      <div class="flex gap-4">
        <article role="article" aria-label={@slug} class="flex-1 min-w-0">
          <section class="section-spaced">
            <p><.source_badge source={@source} /></p>

            <h2 class="section-header-bordered">
              {if @article, do: String.upcase(@article.title), else: format_title(@slug)}
            </h2>

            <.loading :if={@loading} />

            <.not_found :if={@error == :not_found} source={@source} slug={@slug} />

            <div
              :if={@article && !@loading}
              id="article-content"
              class="article-body"
            >
              {raw(@html)}
            </div>

            <.article_meta :if={@article} article={@article} />
          </section>
        </article>

        <.related_sidebar :if={@related != []} related={@related} />
      </div>

      <.edit_modal :if={@show_edit_form} form={@edit_form} submitting={@edit_submitting} />
    </Layouts.app>
    """
  end

  defp related_sidebar(assigns) do
    ~H"""
    <aside class="w-64 flex-shrink-0 hidden-mobile">
      <div class="sidebar">
        <h2 class="sidebar-title">RELATED ARTICLES</h2>
        <ul>
          <li :for={rel <- @related} class="mb-2">
            <.link
              navigate={article_path(rel.source, rel.slug)}
              class="block p-1"
            >
              <div class="flex items-center gap-1 mb-1">
                <.mini_source_badge source={rel.source} />
                <span class="truncate">{rel.title}</span>
              </div>
              <div class="flex items-center gap-1 text-xs text-muted">
                <span>{format_relationship(rel.relationship)}</span>
                <span>|</span>
                <span>{format_confidence(rel.confidence)}</span>
              </div>
            </.link>
          </li>
        </ul>
      </div>
    </aside>
    """
  end

  defp mini_source_badge(assigns) do
    labels = %{
      osrs: "OS",
      nlab: "NL",
      wikipedia: "WP",
      vintage_machinery: "VM",
      wikiart: "AR"
    }

    assigns = assign(assigns, :label, Map.get(labels, assigns.source, "?"))

    ~H"""
    <span class="badge text-xs">
      {@label}
    </span>
    """
  end

  defp source_badge(assigns) do
    labels = %{
      osrs: "OSRS WIKI",
      nlab: "NLAB",
      wikipedia: "WIKIPEDIA",
      vintage_machinery: "VINTAGE MACHINERY",
      wikiart: "WIKIART"
    }

    class =
      case assigns.source do
        :osrs -> "source-badge source-badge-osrs"
        :nlab -> "source-badge source-badge-nlab"
        :wikipedia -> "source-badge source-badge-wikipedia"
        _ -> "source-badge"
      end

    assigns =
      assigns
      |> assign(:label, Map.get(labels, assigns.source, to_string(assigns.source)))
      |> assign(:class, class)

    ~H"""
    <span class={@class}>
      {@label}
    </span>
    """
  end

  defp loading(assigns) do
    ~H"""
    <div class="text-muted loading">
      Loading article
    </div>
    """
  end

  defp not_found(assigns) do
    upstream_url = upstream_url(assigns.source, assigns.slug)
    assigns = assign(assigns, :upstream_url, upstream_url)

    ~H"""
    <div class="text-muted py-4">
      <p>Article not found in local cache.</p>
      <p :if={@upstream_url} class="mt-2">
        <a href={@upstream_url} target="_blank" rel="noopener noreferrer">
          [VIEW ON SOURCE WIKI ->]
        </a>
      </p>
    </div>
    """
  end

  defp article_meta(assigns) do
    ~H"""
    <footer class="mt-4 pt-2 border-t text-sm text-muted">
      <div class="flex flex-wrap items-center gap-2">
        <span :if={@article.license}>License: {@article.license}</span>
        <span :if={@article.synced_at}>
          Last synced: {Calendar.strftime(@article.synced_at, "%Y-%m-%d %H:%M UTC")}
        </span>
        <a
          :if={@article.upstream_url}
          href={@article.upstream_url}
          target="_blank"
          rel="noopener noreferrer"
        >
          [VIEW ORIGINAL]
        </a>
        <span>|</span>
        <button phx-click="show_edit_form" class="cursor-pointer">
          [SUGGEST EDIT]
        </button>
      </div>
    </footer>
    """
  end

  defp edit_modal(assigns) do
    ~H"""
    <div
      id="edit-modal"
      class="modal-backdrop"
      phx-click="hide_edit_form"
    >
      <div class="modal" onclick="event.stopPropagation()">
        <div class="modal-header">
          <h2 class="modal-title">SUGGEST EDIT</h2>
          <button phx-click="hide_edit_form" class="modal-close">
            [X]
          </button>
        </div>

        <form phx-submit="submit_edit" phx-change="validate_edit" class="modal-body">
          <div class="mb-2">
            <label class="block text-xs text-muted mb-1">
              Edited content:
            </label>
            <textarea
              name="suggested_content"
              rows="12"
              required
              class="w-full text-sm"
            >{@form[:suggested_content].value}</textarea>
          </div>

          <div class="mb-2">
            <label class="block text-xs text-muted mb-1">
              Reason for edit (optional):
            </label>
            <textarea
              name="reason"
              rows="2"
              maxlength="2000"
              class="w-full text-sm"
              placeholder="Why are you suggesting this change?"
            >{@form[:reason].value}</textarea>
          </div>

          <div class="mb-2">
            <label class="block text-xs text-muted mb-1">
              Email (optional, for attribution):
            </label>
            <input
              type="email"
              name="submitter_email"
              value={@form[:submitter_email].value}
              class="w-full text-sm"
              placeholder="your@email.com"
            />
          </div>

          <div class="flex justify-end gap-2 mt-4">
            <button type="button" phx-click="hide_edit_form" class="btn">
              CANCEL
            </button>
            <button type="submit" disabled={@submitting} class="btn">
              {if @submitting, do: "SUBMITTING...", else: "SUBMIT"}
            </button>
          </div>
        </form>
      </div>
    </div>
    """
  end

  @path_to_source %{
    "/osrs/" => :osrs,
    "/nlab/" => :nlab,
    "/wikipedia/" => :wikipedia,
    "/machines/" => :vintage_machinery,
    "/art/" => :wikiart
  }

  defp source_and_slug_from_uri(uri, params) do
    path = URI.parse(uri).path
    slug = params["slug"] || "unknown"

    source =
      @path_to_source
      |> Enum.find_value(:osrs, fn {prefix, source} ->
        if String.starts_with?(path, prefix), do: source
      end)

    {source, slug}
  end

  defp format_title(slug) do
    slug
    |> String.replace(~r/[-_]/, " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
    |> String.upcase()
  end

  defp article_path(:osrs, slug), do: ~p"/osrs/#{slug}"
  defp article_path(:nlab, slug), do: ~p"/nlab/#{slug}"
  defp article_path(:wikipedia, slug), do: ~p"/wikipedia/#{slug}"
  defp article_path(:vintage_machinery, slug), do: ~p"/machines/#{slug}"
  defp article_path(:wikiart, slug), do: ~p"/art/#{slug}"
  defp article_path(_source, slug), do: "/#{slug}"

  defp format_relationship(:same_topic), do: "Same topic"
  defp format_relationship(:related), do: "Related"
  defp format_relationship(:see_also), do: "See also"
  defp format_relationship(r), do: to_string(r)

  defp format_confidence(nil), do: ""
  defp format_confidence(c) when c >= 0.8, do: "High"
  defp format_confidence(c) when c >= 0.5, do: "Medium"
  defp format_confidence(_), do: "Low"

  defp upstream_url(:osrs, slug), do: "https://oldschool.runescape.wiki/w/#{URI.encode(slug)}"
  defp upstream_url(:nlab, slug), do: "https://ncatlab.org/nlab/show/#{URI.encode(slug)}"
  defp upstream_url(:wikipedia, slug), do: "https://en.wikipedia.org/wiki/#{URI.encode(slug)}"

  defp upstream_url(:vintage_machinery, slug),
    do: "https://vintagemachinery.org/#{String.replace(slug, "__", "/")}"

  defp upstream_url(:wikiart, slug),
    do: "https://www.wikiart.org/en/#{String.replace(slug, "__", "/")}"

  defp upstream_url(_, _), do: nil
end
