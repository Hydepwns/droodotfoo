defmodule Wiki.OSRS do
  @moduledoc """
  Context for OSRS game data.

  Provides access to structured item and monster data extracted
  from the OSRS Wiki during ingestion. Used by the GEX API.
  """

  import Ecto.Query

  alias Wiki.OSRS.{Item, Monster}
  alias Wiki.Repo

  # ===========================================================================
  # Items
  # ===========================================================================

  @doc """
  List items with optional filtering and pagination.

  ## Options

  - `:members` - Filter by members status (boolean)
  - `:tradeable` - Filter by tradeable status (boolean)
  - `:equipable` - Filter by equipable status (boolean)
  - `:name` - Filter by name (partial match, case-insensitive)
  - `:limit` - Max results (default 100, max 500)
  - `:offset` - Pagination offset (default 0)

  ## Examples

      Wiki.OSRS.list_items()
      Wiki.OSRS.list_items(members: true, tradeable: true, limit: 50)
      Wiki.OSRS.list_items(name: "whip")

  """
  @spec list_items(keyword()) :: [Item.t()]
  def list_items(opts \\ []) do
    limit = opts |> Keyword.get(:limit, 100) |> min(500)
    offset = Keyword.get(opts, :offset, 0)

    Item
    |> apply_item_filters(opts)
    |> order_by([i], asc: i.name)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  @doc """
  Get a single item by item_id.
  """
  @spec get_item(integer()) :: Item.t() | nil
  def get_item(item_id) when is_integer(item_id) do
    Repo.get_by(Item, item_id: item_id)
  end

  @doc """
  Get a single item by wiki slug.
  """
  @spec get_item_by_slug(String.t()) :: Item.t() | nil
  def get_item_by_slug(slug) when is_binary(slug) do
    Repo.get_by(Item, wiki_slug: slug)
  end

  @doc """
  Count items matching filters.
  """
  @spec count_items(keyword()) :: integer()
  def count_items(opts \\ []) do
    Item
    |> apply_item_filters(opts)
    |> Repo.aggregate(:count)
  end

  @doc """
  Search items by name.
  """
  @spec search_items(String.t(), keyword()) :: [Item.t()]
  def search_items(query, opts \\ []) when is_binary(query) do
    limit = opts |> Keyword.get(:limit, 20) |> min(100)

    Item
    |> where([i], ilike(i.name, ^"%#{query}%"))
    |> order_by([i], asc: i.name)
    |> limit(^limit)
    |> Repo.all()
  end

  defp apply_item_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:members, value}, q when is_boolean(value) ->
        where(q, [i], i.members == ^value)

      {:tradeable, value}, q when is_boolean(value) ->
        where(q, [i], i.tradeable == ^value)

      {:equipable, value}, q when is_boolean(value) ->
        where(q, [i], i.equipable == ^value)

      {:stackable, value}, q when is_boolean(value) ->
        where(q, [i], i.stackable == ^value)

      {:name, value}, q when is_binary(value) ->
        where(q, [i], ilike(i.name, ^"%#{value}%"))

      _, q ->
        q
    end)
  end

  # ===========================================================================
  # Monsters
  # ===========================================================================

  @doc """
  List monsters with optional filtering and pagination.

  ## Options

  - `:members` - Filter by members status (boolean)
  - `:name` - Filter by name (partial match, case-insensitive)
  - `:min_combat` - Minimum combat level
  - `:max_combat` - Maximum combat level
  - `:slayer_level` - Filter by required slayer level
  - `:limit` - Max results (default 100, max 500)
  - `:offset` - Pagination offset (default 0)

  """
  @spec list_monsters(keyword()) :: [Monster.t()]
  def list_monsters(opts \\ []) do
    limit = opts |> Keyword.get(:limit, 100) |> min(500)
    offset = Keyword.get(opts, :offset, 0)

    Monster
    |> apply_monster_filters(opts)
    |> order_by([m], asc: m.name)
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  @doc """
  Get a single monster by monster_id.
  """
  @spec get_monster(integer()) :: Monster.t() | nil
  def get_monster(monster_id) when is_integer(monster_id) do
    Repo.get_by(Monster, monster_id: monster_id)
  end

  @doc """
  Get a single monster by wiki slug.
  """
  @spec get_monster_by_slug(String.t()) :: Monster.t() | nil
  def get_monster_by_slug(slug) when is_binary(slug) do
    Repo.get_by(Monster, wiki_slug: slug)
  end

  @doc """
  Count monsters matching filters.
  """
  @spec count_monsters(keyword()) :: integer()
  def count_monsters(opts \\ []) do
    Monster
    |> apply_monster_filters(opts)
    |> Repo.aggregate(:count)
  end

  @doc """
  Search monsters by name.
  """
  @spec search_monsters(String.t(), keyword()) :: [Monster.t()]
  def search_monsters(query, opts \\ []) when is_binary(query) do
    limit = opts |> Keyword.get(:limit, 20) |> min(100)

    Monster
    |> where([m], ilike(m.name, ^"%#{query}%"))
    |> order_by([m], asc: m.name)
    |> limit(^limit)
    |> Repo.all()
  end

  defp apply_monster_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:members, value}, q when is_boolean(value) ->
        where(q, [m], m.members == ^value)

      {:name, value}, q when is_binary(value) ->
        where(q, [m], ilike(m.name, ^"%#{value}%"))

      {:min_combat, value}, q when is_integer(value) ->
        where(q, [m], m.combat_level >= ^value)

      {:max_combat, value}, q when is_integer(value) ->
        where(q, [m], m.combat_level <= ^value)

      {:slayer_level, value}, q when is_integer(value) ->
        where(q, [m], m.slayer_level == ^value)

      _, q ->
        q
    end)
  end

  # ===========================================================================
  # Upserts (used by ingestion)
  # ===========================================================================

  @doc """
  Upsert an item. Used during ingestion.
  """
  @spec upsert_item(map()) :: {:ok, Item.t()} | {:error, Ecto.Changeset.t()}
  def upsert_item(%{item_id: item_id} = attrs) when not is_nil(item_id) do
    case get_item(item_id) do
      nil ->
        %Item{}
        |> Item.changeset(attrs)
        |> Repo.insert()

      existing ->
        existing
        |> Item.changeset(attrs)
        |> Repo.update()
    end
  end

  @doc """
  Upsert a monster. Used during ingestion.
  """
  @spec upsert_monster(map()) :: {:ok, Monster.t()} | {:error, Ecto.Changeset.t()}
  def upsert_monster(%{monster_id: monster_id} = attrs) when not is_nil(monster_id) do
    case get_monster(monster_id) do
      nil ->
        %Monster{}
        |> Monster.changeset(attrs)
        |> Repo.insert()

      existing ->
        existing
        |> Monster.changeset(attrs)
        |> Repo.update()
    end
  end
end
