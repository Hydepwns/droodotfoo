defmodule Wiki.Parts do
  @moduledoc """
  Context for auto parts catalog.

  Manages parts, vehicles, and fitment relationships.
  """

  import Ecto.Query

  alias Wiki.Parts.{Part, Vehicle, PartFitment}
  alias Wiki.Repo

  # ===========================================================================
  # Parts
  # ===========================================================================

  @doc "List all parts with optional filtering."
  @spec list_parts(map()) :: [Part.t()]
  def list_parts(params \\ %{}) do
    Part
    |> filter_parts(params)
    |> order_by([p], asc: p.name)
    |> Repo.all()
  end

  @doc "Get a part by ID."
  @spec get_part(integer()) :: Part.t() | nil
  def get_part(id), do: Repo.get(Part, id)

  @doc "Get a part by part number."
  @spec get_part_by_number(String.t()) :: Part.t() | nil
  def get_part_by_number(number) do
    Repo.get_by(Part, part_number: number)
  end

  @doc "Get a part with vehicles preloaded."
  @spec get_part_with_vehicles(integer()) :: Part.t() | nil
  def get_part_with_vehicles(id) do
    Part
    |> where([p], p.id == ^id)
    |> preload(:vehicles)
    |> Repo.one()
  end

  @doc "Create a new part."
  @spec create_part(map()) :: {:ok, Part.t()} | {:error, Ecto.Changeset.t()}
  def create_part(attrs) do
    %Part{}
    |> Part.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Update an existing part."
  @spec update_part(Part.t(), map()) :: {:ok, Part.t()} | {:error, Ecto.Changeset.t()}
  def update_part(%Part{} = part, attrs) do
    part
    |> Part.changeset(attrs)
    |> Repo.update()
  end

  @doc "Delete a part."
  @spec delete_part(Part.t()) :: {:ok, Part.t()} | {:error, Ecto.Changeset.t()}
  def delete_part(%Part{} = part) do
    Repo.delete(part)
  end

  @doc "Return a changeset for a part."
  @spec change_part(Part.t(), map()) :: Ecto.Changeset.t()
  def change_part(%Part{} = part, attrs \\ %{}) do
    Part.changeset(part, attrs)
  end

  @doc "Search parts by name, part number, or OEM numbers."
  @spec search_parts(String.t(), keyword()) :: [Part.t()]
  def search_parts(query, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    pattern = "%#{query}%"

    Part
    |> where([p], ilike(p.name, ^pattern))
    |> or_where([p], ilike(p.part_number, ^pattern))
    |> or_where([p], ilike(p.manufacturer, ^pattern))
    |> or_where([p], fragment("? && ARRAY[?]", p.oem_numbers, ^query))
    |> limit(^limit)
    |> order_by([p], asc: p.name)
    |> Repo.all()
  end

  defp filter_parts(query, params) do
    Enum.reduce(params, query, fn
      {"category", cat}, q when is_binary(cat) ->
        where(q, [p], p.category == ^String.to_existing_atom(cat))

      {"manufacturer", mfr}, q when is_binary(mfr) ->
        where(q, [p], ilike(p.manufacturer, ^"%#{mfr}%"))

      {"search", term}, q when is_binary(term) and term != "" ->
        pattern = "%#{term}%"

        q
        |> where([p], ilike(p.name, ^pattern) or ilike(p.part_number, ^pattern))

      {"limit", n}, q when is_integer(n) ->
        limit(q, ^n)

      _, q ->
        q
    end)
  end

  # ===========================================================================
  # Vehicles
  # ===========================================================================

  @doc "List all vehicles with optional filtering."
  @spec list_vehicles(map()) :: [Vehicle.t()]
  def list_vehicles(params \\ %{}) do
    Vehicle
    |> filter_vehicles(params)
    |> order_by([v], desc: v.year, asc: v.make, asc: v.model)
    |> Repo.all()
  end

  @doc "Get a vehicle by ID."
  @spec get_vehicle(integer()) :: Vehicle.t() | nil
  def get_vehicle(id), do: Repo.get(Vehicle, id)

  @doc "Get or create a vehicle by attributes."
  @spec get_or_create_vehicle(map()) :: {:ok, Vehicle.t()} | {:error, Ecto.Changeset.t()}
  def get_or_create_vehicle(attrs) do
    case find_vehicle(attrs) do
      %Vehicle{} = v -> {:ok, v}
      nil -> create_vehicle(attrs)
    end
  end

  @doc "Find a vehicle by year/make/model/engine/trim."
  @spec find_vehicle(map()) :: Vehicle.t() | nil
  def find_vehicle(%{year: year, make: make, model: model} = attrs) do
    Vehicle
    |> where([v], v.year == ^year and v.make == ^make and v.model == ^model)
    |> maybe_filter_engine(attrs[:engine])
    |> maybe_filter_trim(attrs[:trim])
    |> Repo.one()
  end

  @doc "Create a new vehicle."
  @spec create_vehicle(map()) :: {:ok, Vehicle.t()} | {:error, Ecto.Changeset.t()}
  def create_vehicle(attrs) do
    %Vehicle{}
    |> Vehicle.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Return a changeset for a vehicle."
  @spec change_vehicle(Vehicle.t(), map()) :: Ecto.Changeset.t()
  def change_vehicle(%Vehicle{} = vehicle, attrs \\ %{}) do
    Vehicle.changeset(vehicle, attrs)
  end

  @doc "List distinct makes."
  @spec list_makes() :: [String.t()]
  def list_makes do
    Vehicle
    |> select([v], v.make)
    |> distinct(true)
    |> order_by([v], asc: v.make)
    |> Repo.all()
  end

  @doc "List distinct models for a make."
  @spec list_models(String.t()) :: [String.t()]
  def list_models(make) do
    Vehicle
    |> where([v], v.make == ^make)
    |> select([v], v.model)
    |> distinct(true)
    |> order_by([v], asc: v.model)
    |> Repo.all()
  end

  @doc "List distinct years for a make/model."
  @spec list_years(String.t(), String.t()) :: [integer()]
  def list_years(make, model) do
    Vehicle
    |> where([v], v.make == ^make and v.model == ^model)
    |> select([v], v.year)
    |> distinct(true)
    |> order_by([v], desc: v.year)
    |> Repo.all()
  end

  defp filter_vehicles(query, params) do
    Enum.reduce(params, query, fn
      {"year", year}, q when is_integer(year) ->
        where(q, [v], v.year == ^year)

      {"make", make}, q when is_binary(make) ->
        where(q, [v], v.make == ^make)

      {"model", model}, q when is_binary(model) ->
        where(q, [v], v.model == ^model)

      {"limit", n}, q when is_integer(n) ->
        limit(q, ^n)

      _, q ->
        q
    end)
  end

  defp maybe_filter_engine(query, nil), do: query
  defp maybe_filter_engine(query, ""), do: query
  defp maybe_filter_engine(query, engine), do: where(query, [v], v.engine == ^engine)

  defp maybe_filter_trim(query, nil), do: query
  defp maybe_filter_trim(query, ""), do: query
  defp maybe_filter_trim(query, trim), do: where(query, [v], v.trim == ^trim)

  # ===========================================================================
  # Fitments
  # ===========================================================================

  @doc "Add a vehicle fitment to a part."
  @spec add_fitment(Part.t(), Vehicle.t(), map()) ::
          {:ok, PartFitment.t()} | {:error, Ecto.Changeset.t()}
  def add_fitment(%Part{id: part_id}, %Vehicle{id: vehicle_id}, attrs \\ %{}) do
    attrs
    |> Map.merge(%{part_id: part_id, vehicle_id: vehicle_id})
    |> PartFitment.changeset()
    |> Repo.insert(on_conflict: :nothing)
  end

  @doc "Remove a vehicle fitment from a part."
  @spec remove_fitment(Part.t(), Vehicle.t()) :: :ok
  def remove_fitment(%Part{id: part_id}, %Vehicle{id: vehicle_id}) do
    PartFitment
    |> where([f], f.part_id == ^part_id and f.vehicle_id == ^vehicle_id)
    |> Repo.delete_all()

    :ok
  end

  @doc "List all fitments for a part."
  @spec list_fitments(Part.t()) :: [PartFitment.t()]
  def list_fitments(%Part{id: part_id}) do
    PartFitment
    |> where([f], f.part_id == ^part_id)
    |> preload(:vehicle)
    |> Repo.all()
  end

  @doc "Find parts that fit a vehicle."
  @spec find_parts_for_vehicle(Vehicle.t(), keyword()) :: [Part.t()]
  def find_parts_for_vehicle(%Vehicle{id: vehicle_id}, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)
    category = Keyword.get(opts, :category)

    Part
    |> join(:inner, [p], f in PartFitment, on: f.part_id == p.id)
    |> where([p, f], f.vehicle_id == ^vehicle_id)
    |> maybe_filter_category(category)
    |> limit(^limit)
    |> order_by([p], asc: p.category, asc: p.name)
    |> Repo.all()
  end

  defp maybe_filter_category(query, nil), do: query
  defp maybe_filter_category(query, cat), do: where(query, [p], p.category == ^cat)

  # ===========================================================================
  # Import / Browser Clipper
  # ===========================================================================

  @doc """
  Import a part from browser clipper data.

  Expects a map with part info and optional vehicle fitment data.
  """
  @spec import_from_clipper(map()) :: {:ok, Part.t()} | {:error, term()}
  def import_from_clipper(data) do
    Repo.transaction(fn ->
      with {:ok, part} <- create_or_update_part(data),
           :ok <- import_fitments(part, data["vehicles"] || []) do
        part
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp create_or_update_part(data) do
    part_number = data["part_number"] || data["partNumber"]

    attrs = %{
      part_number: part_number,
      name: data["name"] || data["title"] || part_number,
      description: data["description"],
      category: parse_category(data["category"]),
      manufacturer: data["manufacturer"] || data["brand"],
      oem_numbers: data["oem_numbers"] || data["oemNumbers"] || [],
      cross_references: data["cross_references"] || [],
      notes: data["notes"],
      source_url: data["source_url"] || data["url"],
      price_cents: parse_price(data["price"])
    }

    case get_part_by_number(part_number) do
      nil -> create_part(attrs)
      existing -> update_part(existing, attrs)
    end
  end

  defp import_fitments(part, vehicles) when is_list(vehicles) do
    results =
      for v <- vehicles,
          {:ok, vehicle} <- [get_or_create_vehicle(normalize_vehicle(v))],
          do: add_fitment(part, vehicle)

    case Enum.filter(results, &match?({:error, _}, &1)) do
      [] -> :ok
      errors -> {:error, {:fitment_errors, errors}}
    end
  end

  defp normalize_vehicle(v) when is_map(v) do
    %{
      year: v["year"] || v[:year],
      make: v["make"] || v[:make],
      model: v["model"] || v[:model],
      engine: v["engine"] || v[:engine],
      trim: v["trim"] || v[:trim]
    }
  end

  defp parse_category(cat) when is_binary(cat) do
    normalized = String.downcase(cat)

    Part.categories()
    |> Enum.find(:other, &(to_string(&1) == normalized))
  end

  defp parse_category(_), do: :other

  defp parse_price(nil), do: nil
  defp parse_price(cents) when is_integer(cents), do: cents

  defp parse_price(str) when is_binary(str) do
    case Float.parse(String.replace(str, ~r/[^0-9.]/, "")) do
      {dollars, _} -> trunc(dollars * 100)
      :error -> nil
    end
  end

  defp parse_price(_), do: nil
end
