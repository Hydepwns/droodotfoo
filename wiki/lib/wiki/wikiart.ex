defmodule Wiki.WikiArt do
  @moduledoc """
  Context for WikiArt content.

  WikiArt articles are manually curated - we add specific artworks
  that are relevant to our other content (e.g., mathematical art
  related to nLab topics, historical imagery for VintageMachinery).

  Unlike other sources, this is not automated ingestion but
  deliberate curation of public domain artworks.
  """

  import Ecto.Query

  alias Wiki.Content.Article
  alias Wiki.{Cache, Repo, Storage}

  require Logger

  @source :wikiart
  @license "Public domain"

  @type artwork :: %{
          slug: String.t(),
          title: String.t(),
          artist: String.t(),
          year: integer() | nil,
          style: String.t() | nil,
          genre: String.t() | nil,
          description: String.t() | nil,
          image_url: String.t(),
          wikiart_url: String.t()
        }

  # ===========================================================================
  # Queries
  # ===========================================================================

  @doc "List all curated artworks."
  @spec list_artworks(keyword()) :: [Article.t()]
  def list_artworks(opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    from(a in Article,
      where: a.source == @source,
      order_by: [desc: a.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc "Get an artwork by slug."
  @spec get_artwork(String.t()) :: Article.t() | nil
  def get_artwork(slug) do
    Repo.get_by(Article, source: @source, slug: slug)
  end

  @doc "Search artworks by title, artist, or style."
  @spec search(String.t(), keyword()) :: [Article.t()]
  def search(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    pattern = "%#{query}%"

    from(a in Article,
      where: a.source == @source,
      where:
        ilike(a.title, ^pattern) or
          ilike(fragment("metadata->>'artist'"), ^pattern) or
          ilike(fragment("metadata->>'style'"), ^pattern),
      order_by: [desc: a.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  @doc "List artworks by artist."
  @spec by_artist(String.t()) :: [Article.t()]
  def by_artist(artist) do
    from(a in Article,
      where: a.source == @source,
      where: fragment("metadata->>'artist' = ?", ^artist),
      order_by: [asc: fragment("(metadata->>'year')::int")]
    )
    |> Repo.all()
  end

  @doc "List distinct artists."
  @spec list_artists() :: [String.t()]
  def list_artists do
    from(a in Article,
      where: a.source == @source,
      select: fragment("DISTINCT metadata->>'artist'"),
      order_by: fragment("metadata->>'artist'")
    )
    |> Repo.all()
    |> Enum.reject(&is_nil/1)
  end

  @doc "List distinct styles."
  @spec list_styles() :: [String.t()]
  def list_styles do
    from(a in Article,
      where: a.source == @source,
      select: fragment("DISTINCT metadata->>'style'"),
      order_by: fragment("metadata->>'style'")
    )
    |> Repo.all()
    |> Enum.reject(&is_nil/1)
  end

  # ===========================================================================
  # Curation
  # ===========================================================================

  @doc """
  Add an artwork to the curated collection.

  This is the primary way to add WikiArt content - manual entry
  with verified public domain status.
  """
  @spec add_artwork(artwork()) :: {:ok, Article.t()} | {:error, term()}
  def add_artwork(artwork) do
    html = build_artwork_html(artwork)
    content_hash = hash_content(html)

    with {:ok, html_key} <- Storage.put_html(@source, artwork.slug, html),
         attrs = build_article_attrs(artwork, html_key, content_hash),
         {:ok, article} <- Repo.insert(Article.changeset(attrs)) do
      Logger.info("Added WikiArt artwork: #{artwork.title} by #{artwork.artist}")
      {:ok, article}
    end
  end

  @doc """
  Update an existing artwork.
  """
  @spec update_artwork(Article.t(), map()) :: {:ok, Article.t()} | {:error, term()}
  def update_artwork(%Article{source: @source} = article, attrs) do
    merged_metadata = Map.merge(article.metadata || %{}, normalize_metadata(attrs))

    article
    |> Article.changeset(%{
      title: attrs[:title] || article.title,
      metadata: merged_metadata,
      synced_at: DateTime.utc_now()
    })
    |> Repo.update()
    |> tap(fn
      {:ok, _} -> Cache.invalidate(@source, article.slug)
      _ -> :ok
    end)
  end

  @doc """
  Remove an artwork from the collection.
  """
  @spec remove_artwork(Article.t()) :: {:ok, Article.t()} | {:error, term()}
  def remove_artwork(%Article{source: @source} = article) do
    Storage.delete_article(@source, article.slug)
    Repo.delete(article)
  end

  @doc """
  Import artwork from a WikiArt URL.

  Parses the URL to extract the slug and fetches basic metadata.
  The actual content must still be manually verified.
  """
  @spec import_from_url(String.t(), map()) :: {:ok, Article.t()} | {:error, term()}
  def import_from_url(url, overrides \\ %{}) do
    with {:ok, slug} <- parse_wikiart_url(url) do
      artwork =
        %{
          slug: slug,
          title: overrides[:title] || humanize_slug(slug),
          artist: overrides[:artist] || extract_artist_from_slug(slug),
          year: overrides[:year],
          style: overrides[:style],
          genre: overrides[:genre],
          description: overrides[:description],
          image_url: overrides[:image_url] || "",
          wikiart_url: url
        }

      add_artwork(artwork)
    end
  end

  # ===========================================================================
  # Private
  # ===========================================================================

  defp build_artwork_html(artwork) do
    """
    <article class="wikiart-artwork">
      <header>
        <h1>#{escape(artwork.title)}</h1>
        <p class="artist">by #{escape(artwork.artist)}</p>
        #{if artwork.year, do: "<p class=\"year\">#{artwork.year}</p>", else: ""}
      </header>

      #{if artwork.image_url && artwork.image_url != "",
      do: """
      <figure>
        <img src="#{escape(artwork.image_url)}" alt="#{escape(artwork.title)}" loading="lazy" />
      </figure>
      """,
      else: ""}

      #{if artwork.description,
      do: """
      <section class="description">
        <p>#{escape(artwork.description)}</p>
      </section>
      """,
      else: ""}

      <dl class="metadata">
        #{if artwork.style, do: "<dt>Style</dt><dd>#{escape(artwork.style)}</dd>", else: ""}
        #{if artwork.genre, do: "<dt>Genre</dt><dd>#{escape(artwork.genre)}</dd>", else: ""}
      </dl>

      <footer>
        <a href="#{escape(artwork.wikiart_url)}" rel="noopener" target="_blank">
          View on WikiArt
        </a>
      </footer>
    </article>
    """
  end

  defp build_article_attrs(artwork, html_key, content_hash) do
    %{
      source: @source,
      slug: artwork.slug,
      title: artwork.title,
      extracted_text: artwork.description || "",
      rendered_html_key: html_key,
      upstream_url: artwork.wikiart_url,
      upstream_hash: content_hash,
      status: :synced,
      license: @license,
      metadata: normalize_metadata(artwork),
      synced_at: DateTime.utc_now()
    }
  end

  defp normalize_metadata(artwork) when is_map(artwork) do
    keys = ~w(artist year style genre image_url)

    for key <- keys,
        value = artwork[String.to_atom(key)] || artwork[key],
        not is_nil(value),
        into: %{},
        do: {key, value}
  end

  defp parse_wikiart_url(url) do
    case URI.parse(url) do
      %{host: host, path: path} when host in ["wikiart.org", "www.wikiart.org"] ->
        slug =
          path
          |> String.trim_leading("/en/")
          |> String.split("/")
          |> Enum.join("__")

        {:ok, slug}

      _ ->
        {:error, :invalid_wikiart_url}
    end
  end

  defp extract_artist_from_slug(slug) do
    slug
    |> String.split("__")
    |> List.first()
    |> humanize_slug()
  end

  defp humanize_slug(slug) do
    slug
    |> String.replace(~r/[-_]/, " ")
    |> String.split(" ")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp escape(nil), do: ""

  defp escape(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end

  defp hash_content(html) do
    :crypto.hash(:sha256, html) |> Base.encode16(case: :lower)
  end
end
