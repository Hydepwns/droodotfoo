defmodule Wiki.Ingestion.WikipediaClient do
  @moduledoc """
  REST API client for Wikipedia.

  Uses the Wikimedia REST API which provides pre-rendered HTML,
  avoiding the need to parse wikitext ourselves.

  ## API Endpoints

  - `/page/html/{title}` - Pre-rendered HTML
  - `/page/summary/{title}` - Summary with extract
  - `/page/mobile-html/{title}` - Mobile-optimized HTML

  ## Configuration

      config :wiki, Wiki.Ingestion.WikipediaClient,
        base_url: "https://en.wikipedia.org/api/rest_v1",
        user_agent: "DrooFoo-WikiMirror/1.0 (https://droo.foo; contact@droo.foo)",
        rate_limit_ms: 1_000

  """

  require Logger

  @type page :: %{
          slug: String.t(),
          title: String.t(),
          html: String.t(),
          extract: String.t(),
          description: String.t() | nil,
          image_url: String.t() | nil,
          last_modified: DateTime.t() | nil
        }

  @doc """
  Fetch a Wikipedia page by title/slug.

  Returns pre-rendered HTML and metadata.
  """
  @spec get_page(String.t()) :: {:ok, page()} | {:error, term()}
  def get_page(slug) do
    with {:ok, summary} <- fetch_summary(slug),
         {:ok, html} <- fetch_html(slug) do
      {:ok, build_page(slug, summary, html)}
    end
  end

  @doc """
  Fetch page summary (extract, thumbnail, description).
  """
  @spec fetch_summary(String.t()) :: {:ok, map()} | {:error, term()}
  def fetch_summary(slug) do
    slug
    |> build_url("/page/summary")
    |> fetch_json()
  end

  @doc """
  Fetch pre-rendered HTML for a page.
  """
  @spec fetch_html(String.t()) :: {:ok, String.t()} | {:error, term()}
  def fetch_html(slug) do
    slug
    |> build_url("/page/html")
    |> fetch_text()
  end

  @doc """
  Search Wikipedia for pages matching a query.

  Returns a list of page summaries.
  """
  @spec search(String.t(), keyword()) :: {:ok, [map()]} | {:error, term()}
  def search(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    url = "#{base_url()}/page/search/#{URI.encode(query)}?limit=#{limit}"

    case fetch_json(url) do
      {:ok, %{"pages" => pages}} -> {:ok, pages}
      {:ok, _} -> {:ok, []}
      error -> error
    end
  end

  @doc """
  Check if a page exists.
  """
  @spec exists?(String.t()) :: boolean()
  def exists?(slug), do: match?({:ok, _}, fetch_summary(slug))

  @doc """
  Get related pages for a given page.
  """
  @spec get_related(String.t(), keyword()) :: {:ok, [map()]} | {:error, term()}
  def get_related(slug, opts \\ []) do
    limit = Keyword.get(opts, :limit, 10)

    url = "#{base_url()}/page/related/#{URI.encode(slug)}"

    case fetch_json(url) do
      {:ok, %{"pages" => pages}} -> {:ok, Enum.take(pages, limit)}
      {:ok, _} -> {:ok, []}
      error -> error
    end
  end

  # Private

  defp build_page(slug, summary, html) do
    %{
      slug: slug,
      title: summary["title"] || humanize_slug(slug),
      html: html,
      extract: summary["extract"] || "",
      description: summary["description"],
      image_url: get_in(summary, ["thumbnail", "source"]),
      last_modified: parse_timestamp(summary["timestamp"])
    }
  end

  defp build_url(slug, endpoint) do
    "#{base_url()}#{endpoint}/#{URI.encode(slug)}"
  end

  defp fetch_json(url) do
    with {:ok, body} <- fetch(url) do
      case body do
        body when is_map(body) -> {:ok, body}
        body when is_binary(body) -> Jason.decode(body)
      end
    end
  end

  defp fetch_text(url), do: fetch(url)

  defp fetch(url) do
    rate_limit()

    url
    |> Req.get(headers: headers(), retry: :transient, max_retries: 2)
    |> handle_response()
  end

  defp handle_response({:ok, %{status: 200, body: body}}), do: {:ok, body}
  defp handle_response({:ok, %{status: 404}}), do: {:error, :not_found}
  defp handle_response({:ok, %{status: status}}), do: {:error, {:http_error, status}}
  defp handle_response({:error, reason}), do: {:error, reason}

  defp headers do
    [
      {"user-agent", config(:user_agent) || "DrooFoo-WikiMirror/1.0"},
      {"accept", "application/json; charset=utf-8"}
    ]
  end

  defp rate_limit do
    ms = config(:rate_limit_ms) || 1_000
    Process.sleep(ms)
  end

  defp parse_timestamp(nil), do: nil

  defp parse_timestamp(ts) when is_binary(ts) do
    case DateTime.from_iso8601(ts) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end

  defp humanize_slug(slug) do
    slug
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp base_url, do: config(:base_url) || "https://en.wikipedia.org/api/rest_v1"

  defp config(key) do
    Application.get_env(:wiki, __MODULE__, [])
    |> Keyword.get(key)
  end
end
