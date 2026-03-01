defmodule DroodotfooWeb.Wiki.Helpers do
  @moduledoc """
  Shared helpers for wiki LiveViews and components.

  Consolidates URL building, source labels, and other utilities
  used across ArticleLive, SearchLive, and wiki components.
  """

  @sources [:osrs, :nlab, :wikipedia, :vintage_machinery, :wikiart]

  @doc """
  Generate internal path for an article.

  ## Examples

      iex> Helpers.article_path(:osrs, "Abyssal_whip")
      "/osrs/Abyssal_whip"

      iex> Helpers.article_path(:vintage_machinery, "some_machine")
      "/machines/some_machine"

  """
  @spec article_path(atom(), String.t()) :: String.t()
  def article_path(:osrs, slug), do: "/osrs/#{slug}"
  def article_path(:nlab, slug), do: "/nlab/#{slug}"
  def article_path(:wikipedia, slug), do: "/wikipedia/#{slug}"
  def article_path(:vintage_machinery, slug), do: "/machines/#{slug}"
  def article_path(:wikiart, slug), do: "/art/#{slug}"
  def article_path(_source, slug), do: "/#{slug}"

  @doc """
  Generate index path for a source (browse all articles).
  """
  @spec source_index_path(atom()) :: String.t()
  def source_index_path(:osrs), do: "/osrs"
  def source_index_path(:nlab), do: "/nlab"
  def source_index_path(:wikipedia), do: "/wikipedia"
  def source_index_path(:vintage_machinery), do: "/machines"
  def source_index_path(:wikiart), do: "/art"
  def source_index_path(_), do: "/"

  @doc """
  Generate internal path from an article struct or map with :source and :slug keys.
  """
  @spec article_path(%{source: atom(), slug: String.t()}) :: String.t()
  def article_path(%{source: source, slug: slug}), do: article_path(source, slug)

  @doc """
  Generate upstream URL for viewing on source wiki.

  ## Examples

      iex> Helpers.upstream_url(:osrs, "Abyssal_whip")
      "https://oldschool.runescape.wiki/w/Abyssal_whip"

      iex> Helpers.upstream_url(:wikipedia, "Elixir_(programming_language)")
      "https://en.wikipedia.org/wiki/Elixir_(programming_language)"

  """
  @spec upstream_url(atom(), String.t()) :: String.t() | nil
  def upstream_url(:osrs, slug), do: "https://oldschool.runescape.wiki/w/#{URI.encode(slug)}"
  def upstream_url(:nlab, slug), do: "https://ncatlab.org/nlab/show/#{URI.encode(slug)}"
  def upstream_url(:wikipedia, slug), do: "https://en.wikipedia.org/wiki/#{URI.encode(slug)}"

  def upstream_url(:vintage_machinery, slug),
    do: "https://vintagemachinery.org/#{String.replace(slug, "__", "/")}"

  def upstream_url(:wikiart, slug),
    do: "https://www.wikiart.org/en/#{String.replace(slug, "__", "/")}"

  def upstream_url(_, _), do: nil

  @doc """
  Base URL for a wiki source (home page).

  ## Examples

      iex> Helpers.upstream_base_url(:osrs)
      "https://oldschool.runescape.wiki"

  """
  @spec upstream_base_url(atom()) :: String.t() | nil
  def upstream_base_url(:osrs), do: "https://oldschool.runescape.wiki"
  def upstream_base_url(:nlab), do: "https://ncatlab.org/nlab"
  def upstream_base_url(:wikipedia), do: "https://en.wikipedia.org"
  def upstream_base_url(:vintage_machinery), do: "https://vintagemachinery.org"
  def upstream_base_url(:wikiart), do: "https://www.wikiart.org"
  def upstream_base_url(_), do: nil

  @doc """
  Short label for a source (used in badges and dropdowns).

  ## Examples

      iex> Helpers.source_label(:osrs)
      "OSRS"

      iex> Helpers.source_label(:vintage_machinery)
      "VM"

  """
  @spec source_label(atom()) :: String.t()
  def source_label(:osrs), do: "OSRS"
  def source_label(:nlab), do: "NLAB"
  def source_label(:wikipedia), do: "WIKI"
  def source_label(:vintage_machinery), do: "VM"
  def source_label(:wikiart), do: "ART"
  def source_label(source), do: source |> to_string() |> String.upcase()

  @doc """
  Mini label for compact badges (2 chars).
  """
  @spec source_label_mini(atom()) :: String.t()
  def source_label_mini(:osrs), do: "OS"
  def source_label_mini(:nlab), do: "NL"
  def source_label_mini(:wikipedia), do: "WP"
  def source_label_mini(:vintage_machinery), do: "VM"
  def source_label_mini(:wikiart), do: "AR"
  def source_label_mini(_), do: "?"

  @doc """
  Full label for a source (used in headers).

  ## Examples

      iex> Helpers.source_label_full(:osrs)
      "OSRS WIKI"

  """
  @spec source_label_full(atom()) :: String.t()
  def source_label_full(:osrs), do: "OSRS WIKI"
  def source_label_full(:nlab), do: "NLAB"
  def source_label_full(:wikipedia), do: "WIKIPEDIA"
  def source_label_full(:vintage_machinery), do: "VINTAGE MACHINERY"
  def source_label_full(:wikiart), do: "WIKIART"
  def source_label_full(source), do: source |> to_string() |> String.upcase()

  @doc """
  CSS class for source badge styling.
  """
  @spec source_badge_class(atom()) :: String.t()
  def source_badge_class(:osrs), do: "source-badge source-badge-osrs"
  def source_badge_class(:nlab), do: "source-badge source-badge-nlab"
  def source_badge_class(:wikipedia), do: "source-badge source-badge-wikipedia"
  def source_badge_class(_), do: "source-badge"

  @doc """
  Parse source string to atom.

  ## Examples

      iex> Helpers.parse_source("osrs")
      :osrs

      iex> Helpers.parse_source("invalid")
      nil

  """
  @spec parse_source(String.t() | nil) :: atom() | nil
  def parse_source(""), do: nil
  def parse_source(nil), do: nil
  def parse_source("osrs"), do: :osrs
  def parse_source("nlab"), do: :nlab
  def parse_source("wikipedia"), do: :wikipedia
  def parse_source("vintage_machinery"), do: :vintage_machinery
  def parse_source("wikiart"), do: :wikiart
  def parse_source(_), do: nil

  @doc """
  List of all valid wiki sources.
  """
  @spec sources() :: [atom()]
  def sources, do: @sources

  # --- Date Formatting ---

  @doc "Format datetime as YYYY-MM-DD."
  @spec format_date(DateTime.t() | NaiveDateTime.t()) :: String.t()
  def format_date(datetime), do: Calendar.strftime(datetime, "%Y-%m-%d")

  @doc "Format datetime as YYYY-MM-DD HH:MM."
  @spec format_datetime(DateTime.t() | NaiveDateTime.t()) :: String.t()
  def format_datetime(datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M")

  # --- Changeset Errors ---

  @doc "Format changeset errors as a single string for flash messages."
  @spec format_changeset_errors(Ecto.Changeset.t()) :: String.t()
  def format_changeset_errors(%Ecto.Changeset{} = changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {k, v} -> "#{k}: #{Enum.join(v, ", ")}" end)
    |> Enum.join("; ")
  end
end
