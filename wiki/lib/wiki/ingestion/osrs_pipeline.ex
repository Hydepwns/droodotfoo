defmodule Wiki.Ingestion.OSRSPipeline do
  @moduledoc """
  Pipeline for ingesting OSRS Wiki content.

  Fetches pages from the OSRS Wiki API, processes them,
  stores content in MinIO, and creates/updates article records.
  """

  require Logger

  alias Wiki.Content.Article
  alias Wiki.Ingestion.{MediaWikiClient, InfoboxParser}
  alias Wiki.Repo
  alias Wiki.Storage

  import Ecto.Query

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
         {:ok, article} <- upsert_article(page) do
      article
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
    titles
    |> Enum.map(fn title ->
      {title, process_page(title)}
    end)
    |> Map.new()
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
        {:ok, aggregate_stats(results)}

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
        {:ok, aggregate_stats(results)}

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
    content_hash = hash_content(page.html)

    existing =
      Repo.one(
        from a in Article,
          where: a.source == @source and a.slug == ^slug
      )

    cond do
      is_nil(existing) ->
        create_article(page, slug, content_hash)

      existing.upstream_hash != content_hash ->
        update_article(existing, page, content_hash)

      true ->
        {:unchanged, existing}
    end
  end

  defp create_article(page, slug, content_hash) do
    with {:ok, html_key} <- Storage.put_html(@source, slug, page.html),
         {:ok, raw_key} <- maybe_store_raw(page, slug) do
      attrs = %{
        source: @source,
        slug: slug,
        title: page.title,
        extracted_text: extract_text(page.html),
        rendered_html_key: html_key,
        raw_content_key: raw_key,
        upstream_url: upstream_url(page.title),
        upstream_hash: content_hash,
        status: :synced,
        license: @license,
        metadata: extract_metadata(page),
        synced_at: DateTime.utc_now()
      }

      case Repo.insert(Article.changeset(attrs)) do
        {:ok, article} ->
          Logger.info("Created article: #{page.title}")
          {:created, article}

        {:error, changeset} ->
          {:error, {:insert_failed, changeset}}
      end
    end
  end

  defp update_article(existing, page, content_hash) do
    slug = existing.slug

    with {:ok, html_key} <- Storage.put_html(@source, slug, page.html),
         {:ok, raw_key} <- maybe_store_raw(page, slug) do
      attrs = %{
        title: page.title,
        extracted_text: extract_text(page.html),
        rendered_html_key: html_key,
        raw_content_key: raw_key,
        upstream_hash: content_hash,
        status: :synced,
        metadata: extract_metadata(page),
        synced_at: DateTime.utc_now()
      }

      case Repo.update(Article.changeset(existing, attrs)) do
        {:ok, article} ->
          Logger.info("Updated article: #{page.title}")
          {:updated, article}

        {:error, changeset} ->
          {:error, {:update_failed, changeset}}
      end
    end
  end

  defp maybe_store_raw(%{wikitext: nil}, _slug), do: {:ok, nil}
  defp maybe_store_raw(%{wikitext: ""}, _slug), do: {:ok, nil}
  defp maybe_store_raw(%{wikitext: wikitext}, slug), do: Storage.put_raw(@source, slug, wikitext)

  defp upsert_item(page, infobox) do
    alias Wiki.OSRS.Item

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
    alias Wiki.OSRS.Monster

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
    title
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/, "-")
    |> String.trim("-")
  end

  defp hash_content(html) do
    :crypto.hash(:sha256, html) |> Base.encode16(case: :lower)
  end

  defp upstream_url(title) do
    @upstream_base <> URI.encode(title, &URI.char_unreserved?/1)
  end

  defp extract_text(html) do
    html
    |> Floki.parse_document!()
    |> Floki.text(sep: " ")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
    |> String.slice(0, 100_000)
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

  defp aggregate_stats(results) do
    Enum.reduce(results, %{created: 0, updated: 0, unchanged: 0, errors: 0}, fn
      {_title, {:created, _}}, acc -> Map.update!(acc, :created, &(&1 + 1))
      {_title, {:updated, _}}, acc -> Map.update!(acc, :updated, &(&1 + 1))
      {_title, {:unchanged, _}}, acc -> Map.update!(acc, :unchanged, &(&1 + 1))
      {_title, {:error, _}}, acc -> Map.update!(acc, :errors, &(&1 + 1))
    end)
  end
end
