defmodule Droodotfoo.Wiki.Ingestion.OSRSPipeline do
  @moduledoc """
  Pipeline for ingesting OSRS Wiki content.

  Fetches pages from the OSRS Wiki API, processes them,
  stores content in MinIO, and creates/updates article records.
  """

  require Logger

  alias Droodotfoo.Wiki.Content.Article
  alias Droodotfoo.Wiki.Ingestion.{Common, MediaWikiClient, InfoboxParser}
  alias Droodotfoo.Repo
  alias Droodotfoo.Wiki.Storage

  @source :osrs
  @license "CC BY-NC-SA 3.0"
  @upstream_base "https://oldschool.runescape.wiki/w/"

  @type result :: {:created | :updated | :unchanged, Article.t()} | {:error, term()}

  @doc """
  Process a single page by title.

  Fetches the page, stores content, and creates/updates the article record.
  """
  @spec process_page(String.t()) :: result()
  def process_page(title) do
    with {:ok, page} <- MediaWikiClient.get_page(title),
         {status, article} when status in [:created, :updated, :unchanged] <- upsert_article(page) do
      {status, article}
    else
      {:error, :not_found} ->
        Logger.debug("Page not found: #{title}")
        {:error, :not_found}

      {:error, reason} = error ->
        Logger.error("Failed to process #{title}: #{inspect(reason)}")
        error
    end
  end

  @doc """
  Process multiple pages by title.

  Returns a map of results keyed by title.
  """
  @spec process_pages([String.t()]) :: %{String.t() => result()}
  def process_pages(titles) when is_list(titles) do
    Common.process_pages_sequential(titles, &process_page/1)
  end

  @doc """
  Sync recent changes since a given timestamp.

  Returns stats about pages processed.
  """
  @spec sync_recent_changes(DateTime.t() | nil) ::
          {:ok,
           %{created: integer(), updated: integer(), unchanged: integer(), errors: integer()}}
          | {:error, term()}
  def sync_recent_changes(since \\ nil) do
    case MediaWikiClient.recent_changes(since, limit: 500) do
      {:ok, changes} ->
        titles = changes |> Enum.map(& &1.title) |> Enum.uniq()
        results = process_pages(titles)
        {:ok, Common.aggregate_stats(results)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Full sync of a category.

  Fetches all pages in the category and processes them.
  """
  @spec sync_category(String.t(), keyword()) ::
          {:ok,
           %{created: integer(), updated: integer(), unchanged: integer(), errors: integer()}}
          | {:error, term()}
  def sync_category(category, opts \\ []) do
    limit = Keyword.get(opts, :limit, 5000)

    case MediaWikiClient.category_members(category, limit: limit) do
      {:ok, titles} ->
        Logger.info("Processing #{length(titles)} pages from #{category}")
        results = process_pages(titles)
        {:ok, Common.aggregate_stats(results)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Extract OSRS item from page content and upsert to osrs_items table.
  """
  @spec process_item_page(String.t()) :: {:ok, map()} | {:error, term()}
  def process_item_page(title) do
    with {:ok, page} <- MediaWikiClient.get_page(title),
         {:ok, infobox} <- InfoboxParser.parse(page.wikitext || ""),
         true <- infobox["infobox_type"] == "Item" do
      upsert_item(page, infobox)
    else
      false -> {:error, :not_an_item}
      {:error, :no_infobox} -> {:error, :no_infobox}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Extract OSRS monster from page content and upsert to osrs_monsters table.
  """
  @spec process_monster_page(String.t()) :: {:ok, map()} | {:error, term()}
  def process_monster_page(title) do
    with {:ok, page} <- MediaWikiClient.get_page(title),
         {:ok, infobox} <- InfoboxParser.parse(page.wikitext || ""),
         true <- infobox["infobox_type"] == "Monster" do
      upsert_monster(page, infobox)
    else
      false -> {:error, :not_a_monster}
      {:error, :no_infobox} -> {:error, :no_infobox}
      {:error, reason} -> {:error, reason}
    end
  end

  # Private functions

  defp upsert_article(page) do
    slug = slugify(page.title)
    content_hash = Common.hash_content(page.html)

    @source
    |> Common.find_article(slug)
    |> do_upsert(page, slug, content_hash)
  end

  defp do_upsert(nil, page, slug, content_hash) do
    save_article(:insert, nil, page, slug, content_hash)
  end

  defp do_upsert(%Article{upstream_hash: hash} = existing, _page, _slug, hash) do
    {:unchanged, existing}
  end

  defp do_upsert(existing, page, slug, content_hash) do
    save_article(:update, existing, page, slug, content_hash)
  end

  defp save_article(operation, existing, page, slug, content_hash) do
    with {:ok, html_key} <- Storage.put_html(@source, slug, page.html),
         {:ok, raw_key} <- maybe_store_raw(page, slug),
         attrs = build_article_attrs(operation, page, slug, html_key, raw_key, content_hash),
         {:ok, article} <- Common.persist_article(operation, existing, attrs) do
      Droodotfoo.Wiki.Cache.invalidate(@source, slug)
      log_operation(operation, page.title)
      {Common.operation_result(operation), article}
    else
      {:error, changeset} -> {:error, {:"#{operation}_failed", changeset}}
    end
  end

  defp build_article_attrs(:insert, page, slug, html_key, raw_key, content_hash) do
    %{
      source: @source,
      slug: slug,
      title: page.title,
      extracted_text: Common.extract_text(page.html),
      rendered_html_key: html_key,
      raw_content_key: raw_key,
      upstream_url: Common.upstream_url(@upstream_base, page.title),
      upstream_hash: content_hash,
      status: :synced,
      license: @license,
      metadata: extract_metadata(page),
      synced_at: DateTime.utc_now()
    }
  end

  defp build_article_attrs(:update, page, _slug, html_key, raw_key, content_hash) do
    %{
      title: page.title,
      extracted_text: Common.extract_text(page.html),
      rendered_html_key: html_key,
      raw_content_key: raw_key,
      upstream_hash: content_hash,
      status: :synced,
      metadata: extract_metadata(page),
      synced_at: DateTime.utc_now()
    }
  end

  defp log_operation(:insert, title), do: Logger.info("Created OSRS article: #{title}")
  defp log_operation(:update, title), do: Logger.info("Updated OSRS article: #{title}")

  defp maybe_store_raw(%{wikitext: nil}, _slug), do: {:ok, nil}
  defp maybe_store_raw(%{wikitext: ""}, _slug), do: {:ok, nil}
  defp maybe_store_raw(%{wikitext: wikitext}, slug), do: Storage.put_raw(@source, slug, wikitext)

  defp upsert_item(page, infobox) do
    alias Droodotfoo.Wiki.OSRS.Item

    item_id = parse_int(infobox["id"])

    attrs = %{
      item_id: item_id,
      name: infobox["name"] || page.title,
      members: parse_bool(infobox["members"]),
      tradeable: parse_bool(infobox["tradeable"]),
      equipable: parse_bool(infobox["equipable"]),
      stackable: parse_bool(infobox["stackable"]),
      buy_limit: parse_int(infobox["buy_limit"]),
      high_alch: parse_int(infobox["highalch"]),
      low_alch: parse_int(infobox["lowalch"]),
      value: parse_int(infobox["value"]),
      weight: parse_float(infobox["weight"]),
      examine: infobox["examine"],
      release_date: parse_date(infobox["release"]),
      wiki_slug: slugify(page.title),
      equipment_stats: extract_equipment_stats(infobox)
    }

    on_conflict = [set: Enum.reject(attrs, fn {k, _v} -> k == :item_id end) |> Enum.to_list()]

    case Repo.insert(
           Item.changeset(attrs),
           on_conflict: on_conflict,
           conflict_target: :item_id,
           returning: true
         ) do
      {:ok, item} -> {:ok, item}
      {:error, changeset} -> {:error, {:upsert_failed, changeset}}
    end
  end

  defp upsert_monster(page, infobox) do
    alias Droodotfoo.Wiki.OSRS.Monster

    monster_id = parse_int(infobox["id"])

    attrs = %{
      monster_id: monster_id,
      name: infobox["name"] || page.title,
      combat_level: parse_int(infobox["combat"]),
      hitpoints: parse_int(infobox["hitpoints"]),
      max_hit: parse_int(infobox["max_hit"]),
      attack_style: infobox["attack_style"],
      slayer_level: parse_int(infobox["slayer_level"]),
      slayer_xp: parse_float(infobox["slayer_xp"]),
      locations: parse_locations(infobox["location"]),
      wiki_slug: slugify(page.title)
    }

    on_conflict = [set: Enum.reject(attrs, fn {k, _v} -> k == :monster_id end) |> Enum.to_list()]

    case Repo.insert(
           Monster.changeset(attrs),
           on_conflict: on_conflict,
           conflict_target: :monster_id,
           returning: true
         ) do
      {:ok, monster} -> {:ok, monster}
      {:error, changeset} -> {:error, {:upsert_failed, changeset}}
    end
  end

  # Helpers

  defp slugify(title) do
    slug =
      title
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/, "-")
      |> String.trim("-")

    # Handle titles that are only special characters (e.g., "!", "%", "(+)")
    if slug == "" do
      title
      |> URI.encode()
      |> String.downcase()
      |> String.replace("%", "pct")
    else
      slug
    end
  end

  defp extract_metadata(page) do
    %{
      "pageid" => page.pageid,
      "revid" => page.revid
    }
  end

  defp extract_equipment_stats(infobox) do
    stats = %{
      "attack_stab" => parse_int(infobox["astab"]),
      "attack_slash" => parse_int(infobox["aslash"]),
      "attack_crush" => parse_int(infobox["acrush"]),
      "attack_magic" => parse_int(infobox["amagic"]),
      "attack_ranged" => parse_int(infobox["arange"]),
      "defence_stab" => parse_int(infobox["dstab"]),
      "defence_slash" => parse_int(infobox["dslash"]),
      "defence_crush" => parse_int(infobox["dcrush"]),
      "defence_magic" => parse_int(infobox["dmagic"]),
      "defence_ranged" => parse_int(infobox["drange"]),
      "strength" => parse_int(infobox["str"]),
      "ranged_strength" => parse_int(infobox["rstr"]),
      "magic_damage" => parse_int(infobox["mdmg"]),
      "prayer" => parse_int(infobox["prayer"])
    }

    # Only include non-nil values
    Enum.reject(stats, fn {_k, v} -> is_nil(v) end) |> Map.new()
  end

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil

  defp parse_int(str) when is_binary(str) do
    str
    |> String.replace(~r/[^\d-]/, "")
    |> Integer.parse()
    |> case do
      {n, _} -> n
      :error -> nil
    end
  end

  defp parse_float(nil), do: nil
  defp parse_float(""), do: nil

  defp parse_float(str) when is_binary(str) do
    str
    |> String.replace(~r/[^\d.-]/, "")
    |> Float.parse()
    |> case do
      {n, _} -> n
      :error -> nil
    end
  end

  defp parse_bool(nil), do: false
  defp parse_bool("Yes"), do: true
  defp parse_bool("yes"), do: true
  defp parse_bool("true"), do: true
  defp parse_bool("1"), do: true
  defp parse_bool(_), do: false

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil

  defp parse_date(str) when is_binary(str) do
    case Date.from_iso8601(str) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_locations(nil), do: []
  defp parse_locations(""), do: []

  defp parse_locations(str) when is_binary(str) do
    str
    |> String.split(~r/[,;]/)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end
end
