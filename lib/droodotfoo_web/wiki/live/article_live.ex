defmodule DroodotfooWeb.Wiki.ArticleLive do
  @moduledoc """
  Single LiveView for all wiki sources.
  Terminal aesthetic styling matching droo.foo.
  """

  use Phoenix.LiveView, layout: false

  alias DroodotfooWeb.Wiki.{Helpers, Layouts}
  alias DroodotfooWeb.Wiki.Helpers.{HTML, TOC}
  alias Droodotfoo.Wiki.Content
  alias Droodotfoo.Wiki.CrossLinks

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       article: nil,
       html: "",
       headings: [],
       word_count: 0,
       reading_time: 0,
       loading: true,
       error: nil,
       related: [],
       show_edit_form: false,
       edit_form: nil,
       edit_submitting: false
     ), temporary_assigns: [html: ""]}
  end

  @impl true
  def handle_params(params, uri, socket) do
    {source, slug} = source_and_slug_from_uri(uri, params)

    current_path = URI.parse(uri).path

    breadcrumbs = [
      {"Home", "/"},
      {Helpers.source_label_full(source), Helpers.source_index_path(source)},
      {format_title(slug), current_path}
    ]

    socket =
      socket
      |> assign(source: source, slug: slug, loading: true, error: nil, related: [])
      |> assign(page_title: format_title(slug), current_path: current_path)
      |> assign(breadcrumbs: breadcrumbs)

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
        description = extract_description(article)
        current_path = socket.assigns.current_path

        # Extract headings for TOC and enhance HTML
        headings = TOC.extract_headings(html)

        enhanced_html =
          html
          |> TOC.add_heading_anchors()
          |> HTML.enhance_images()

        # Calculate reading stats
        word_count = HTML.word_count(html)
        reading_time = HTML.reading_time(word_count)

        breadcrumbs = [
          {"Home", "/"},
          {Helpers.source_label_full(article.source), Helpers.source_index_path(article.source)},
          {article.title, current_path}
        ]

        json_ld = build_json_ld(article, description, breadcrumbs, current_path, word_count)

        {:noreply,
         socket
         |> assign(article: article, html: enhanced_html, loading: false, related: related)
         |> assign(headings: headings, word_count: word_count, reading_time: reading_time)
         |> assign(page_title: String.upcase(article.title), breadcrumbs: breadcrumbs)
         |> assign(
           og_type: "article",
           og_title: article.title,
           og_description: description,
           meta_description: description,
           article_section: Helpers.source_label_full(article.source),
           modified_time: format_iso8601(article.synced_at),
           json_ld: json_ld
         )}

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
         |> put_flash(:error, "Failed to submit: #{Helpers.format_changeset_errors(changeset)}")
         |> assign(edit_submitting: false)}
    end
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
      <Layouts.breadcrumbs items={@breadcrumbs} />

      <div class="article-layout">
        <article role="article" aria-label={@slug} class="article-main">
          <section class="section-spaced">
            <p><.source_badge source={@source} /></p>

            <h1 class="section-header-bordered">
              {if @article, do: String.upcase(@article.title), else: format_title(@slug)}
            </h1>

            <.loading :if={@loading} />

            <.not_found :if={@error == :not_found} source={@source} slug={@slug} />

            <Layouts.table_of_contents :if={@article && !@loading} headings={@headings} />

            <div
              :if={@article && !@loading}
              id="article-content"
              class="article-body"
            >
              {Phoenix.HTML.raw(@html)}
            </div>

            <.article_meta
              :if={@article}
              article={@article}
              word_count={@word_count}
              reading_time={@reading_time}
            />
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
    <aside class="article-sidebar">
      <div class="sidebar">
        <h2 class="sidebar-title">RELATED ARTICLES</h2>
        <ul>
          <li :for={rel <- @related} class="mb-2">
            <.link
              navigate={Helpers.article_path(rel.source, rel.slug)}
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
    assigns = assign(assigns, :label, Helpers.source_label_mini(assigns.source))

    ~H"""
    <span class="badge text-xs">
      {@label}
    </span>
    """
  end

  defp source_badge(assigns) do
    assigns =
      assigns
      |> assign(:label, Helpers.source_label_full(assigns.source))
      |> assign(:class, Helpers.source_badge_class(assigns.source))

    ~H"""
    <span class={@class}>
      {@label}
    </span>
    """
  end

  defp loading(assigns) do
    ~H"""
    <div class="wiki-loading">
      <div class="loading-indicator">
        <span class="spinner"></span>
        <span>Loading article...</span>
      </div>
      <div class="skeleton-lines">
        <div class="skeleton-line width-100"></div>
        <div class="skeleton-line width-80"></div>
        <div class="skeleton-line width-90"></div>
        <div class="skeleton-line width-70"></div>
      </div>
    </div>
    """
  end

  defp not_found(assigns) do
    assigns = assign(assigns, :upstream_url, Helpers.upstream_url(assigns.source, assigns.slug))

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
    <footer class="article-footer mt-4 pt-2 border-t text-sm text-muted">
      <div class="flex flex-wrap items-center gap-2 mb-2">
        <span :if={@word_count > 0}>{@word_count} words</span>
        <span :if={@word_count > 0}>|</span>
        <span :if={@reading_time > 0}>{@reading_time} min read</span>
      </div>
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
      phx-window-keydown="hide_edit_form"
      phx-key="Escape"
      phx-hook="ModalScrollLock"
      role="dialog"
      aria-modal="true"
      aria-labelledby="edit-modal-title"
    >
      <div class="modal" phx-click-away="hide_edit_form">
        <div class="modal-header">
          <h2 id="edit-modal-title" class="modal-title">SUGGEST EDIT</h2>
          <button
            type="button"
            phx-click="hide_edit_form"
            class="modal-close"
            aria-label="Close dialog"
          >
            [X]
          </button>
        </div>

        <form
          phx-submit="submit_edit"
          phx-change="validate_edit"
          class="modal-body"
          aria-label="Edit suggestion form"
        >
          <div class="mb-2">
            <label for="suggested-content" class="block text-xs text-muted mb-1">
              Edited content:
            </label>
            <textarea
              id="suggested-content"
              name="suggested_content"
              rows="12"
              required
              aria-required="true"
              class="w-full text-sm"
            >{@form[:suggested_content].value}</textarea>
          </div>

          <div class="mb-2">
            <label for="edit-reason" class="block text-xs text-muted mb-1">
              Reason for edit (optional):
            </label>
            <textarea
              id="edit-reason"
              name="reason"
              rows="2"
              maxlength="2000"
              class="w-full text-sm"
              placeholder="Why are you suggesting this change?"
              aria-describedby="reason-hint"
            >{@form[:reason].value}</textarea>
            <span id="reason-hint" class="visually-hidden">
              Briefly explain why this edit improves the article
            </span>
          </div>

          <div class="mb-2">
            <label for="submitter-email" class="block text-xs text-muted mb-1">
              Email (optional, for attribution):
            </label>
            <input
              id="submitter-email"
              type="email"
              name="submitter_email"
              value={@form[:submitter_email].value}
              class="w-full text-sm"
              placeholder="your@email.com"
              aria-describedby="email-hint"
            />
            <span id="email-hint" class="visually-hidden">
              Your email for attribution if the edit is accepted
            </span>
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

  defp format_relationship(:same_topic), do: "Same topic"
  defp format_relationship(:related), do: "Related"
  defp format_relationship(:see_also), do: "See also"
  defp format_relationship(r), do: to_string(r)

  defp format_confidence(nil), do: ""
  defp format_confidence(c) when c >= 0.8, do: "High"
  defp format_confidence(c) when c >= 0.5, do: "Medium"
  defp format_confidence(_), do: "Low"

  defp extract_description(article) do
    text = article.extracted_text || article.title || ""

    text
    |> String.slice(0, 160)
    |> String.trim()
    |> then(fn s -> if String.length(s) == 160, do: s <> "...", else: s end)
  end

  defp format_iso8601(nil), do: nil

  defp format_iso8601(%DateTime{} = dt) do
    DateTime.to_iso8601(dt)
  end

  # JSON-LD structured data generation

  defp build_json_ld(article, description, breadcrumbs, current_path, word_count) do
    url = "https://wiki.droo.foo#{current_path}"

    [
      build_article_schema(article, description, url, word_count),
      build_breadcrumb_schema(breadcrumbs)
    ]
  end

  defp build_article_schema(article, description, url, word_count) do
    %{
      "@context" => "https://schema.org",
      "@type" => "Article",
      "headline" => article.title,
      "description" => description,
      "url" => url,
      "dateModified" => format_iso8601(article.synced_at),
      "author" => %{
        "@type" => "Organization",
        "name" => Helpers.source_label_full(article.source),
        "url" => article.upstream_url
      },
      "publisher" => %{
        "@type" => "Organization",
        "name" => "WIKI.DROO.FOO",
        "url" => "https://wiki.droo.foo"
      },
      "mainEntityOfPage" => %{
        "@type" => "WebPage",
        "@id" => url
      },
      "isPartOf" => %{
        "@type" => "WebSite",
        "name" => "WIKI.DROO.FOO",
        "url" => "https://wiki.droo.foo"
      }
    }
    |> maybe_add_word_count(word_count)
    |> maybe_add_license(article.license)
    |> Jason.encode!()
  end

  defp maybe_add_word_count(schema, 0), do: schema
  defp maybe_add_word_count(schema, count), do: Map.put(schema, "wordCount", count)

  defp maybe_add_license(schema, nil), do: schema
  defp maybe_add_license(schema, ""), do: schema
  defp maybe_add_license(schema, license), do: Map.put(schema, "license", license)

  defp build_breadcrumb_schema(breadcrumbs) do
    items =
      breadcrumbs
      |> Enum.with_index(1)
      |> Enum.map(fn {{name, path}, position} ->
        %{
          "@type" => "ListItem",
          "position" => position,
          "name" => name,
          "item" => "https://wiki.droo.foo#{path}"
        }
      end)

    %{
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" => items
    }
    |> Jason.encode!()
  end
end
