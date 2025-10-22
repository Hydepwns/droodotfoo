defmodule Droodotfoo.Resume.PresetManager do
  @moduledoc """
  Manages saved filter presets for resume filtering.

  Provides persistent storage of filter combinations with:
  - Named presets for quick filter access
  - User-defined and system-default presets
  - Import/export functionality
  - Preset validation and updates

  ## Storage

  Presets are stored in ETS for runtime access and can be persisted
  to disk for long-term storage.

  ## Examples

      iex> PresetManager.save_preset("blockchain", %{
      ...>   technologies: ["Elixir", "Rust"],
      ...>   text_search: "blockchain"
      ...> })
      {:ok, "blockchain"}

      iex> PresetManager.load_preset("blockchain")
      {:ok, %{technologies: ["Elixir", "Rust"], text_search: "blockchain"}}

  """

  use GenServer
  require Logger

  @table_name :resume_filter_presets
  @persist_file "priv/resume_presets.json"

  @derive Jason.Encoder
  defstruct [
    :name,
    :description,
    :filters,
    :created_at,
    :updated_at,
    :is_system,
    :tags
  ]

  @type preset :: %__MODULE__{
          name: String.t(),
          description: String.t() | nil,
          filters: map(),
          created_at: DateTime.t(),
          updated_at: DateTime.t(),
          is_system: boolean(),
          tags: list(String.t())
        }

  # Client API

  @doc """
  Starts the PresetManager GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Saves a filter preset with a given name.

  ## Examples

      iex> PresetManager.save_preset("web3", %{technologies: ["Rust", "Solidity"]})
      {:ok, "web3"}

      iex> PresetManager.save_preset("web3", %{technologies: ["Rust"]}, description: "Web3 experience")
      {:ok, "web3"}

  """
  @spec save_preset(String.t(), map(), keyword()) :: {:ok, String.t()} | {:error, String.t()}
  def save_preset(name, filters, opts \\ []) do
    GenServer.call(__MODULE__, {:save_preset, name, filters, opts})
  end

  @doc """
  Loads a filter preset by name.

  ## Examples

      iex> PresetManager.load_preset("blockchain")
      {:ok, %{technologies: ["Elixir", "Rust"]}}

      iex> PresetManager.load_preset("nonexistent")
      {:error, "Preset not found"}

  """
  @spec load_preset(String.t()) :: {:ok, map()} | {:error, String.t()}
  def load_preset(name) do
    GenServer.call(__MODULE__, {:load_preset, name})
  end

  @doc """
  Lists all available presets.

  ## Examples

      iex> PresetManager.list_presets()
      [
        %{name: "blockchain", description: "Blockchain experience", is_system: false},
        %{name: "defense", description: "Defense projects", is_system: true}
      ]

  """
  @spec list_presets() :: list(map())
  def list_presets do
    GenServer.call(__MODULE__, :list_presets)
  end

  @doc """
  Deletes a preset by name.
  System presets cannot be deleted.
  """
  @spec delete_preset(String.t()) :: :ok | {:error, String.t()}
  def delete_preset(name) do
    GenServer.call(__MODULE__, {:delete_preset, name})
  end

  @doc """
  Updates an existing preset.
  """
  @spec update_preset(String.t(), map(), keyword()) :: {:ok, String.t()} | {:error, String.t()}
  def update_preset(name, filters, opts \\ []) do
    GenServer.call(__MODULE__, {:update_preset, name, filters, opts})
  end

  @doc """
  Exports all presets to a JSON file.
  """
  @spec export_presets(String.t()) :: :ok | {:error, String.t()}
  def export_presets(file_path \\ @persist_file) do
    GenServer.call(__MODULE__, {:export_presets, file_path})
  end

  @doc """
  Imports presets from a JSON file.
  """
  @spec import_presets(String.t()) :: {:ok, non_neg_integer()} | {:error, String.t()}
  def import_presets(file_path) do
    GenServer.call(__MODULE__, {:import_presets, file_path})
  end

  @doc """
  Finds presets by tag.

  ## Examples

      iex> PresetManager.find_by_tag("web3")
      [%{name: "blockchain", tags: ["web3", "elixir"]}]

  """
  @spec find_by_tag(String.t()) :: list(map())
  def find_by_tag(tag) do
    GenServer.call(__MODULE__, {:find_by_tag, tag})
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    # Create ETS table for presets
    table = :ets.new(@table_name, [:named_table, :set, :public, read_concurrency: true])

    # Load system presets
    load_system_presets(table)

    # Load persisted user presets
    load_persisted_presets(table)

    {:ok, %{table: table}}
  end

  @impl true
  def handle_call({:save_preset, name, filters, opts}, _from, state) do
    description = Keyword.get(opts, :description)
    tags = Keyword.get(opts, :tags, [])
    is_system = Keyword.get(opts, :is_system, false)

    preset = %__MODULE__{
      name: name,
      description: description,
      filters: filters,
      created_at: DateTime.utc_now(),
      updated_at: DateTime.utc_now(),
      is_system: is_system,
      tags: tags
    }

    :ets.insert(state.table, {name, preset})
    persist_presets(state.table)

    {:reply, {:ok, name}, state}
  end

  @impl true
  def handle_call({:load_preset, name}, _from, state) do
    case :ets.lookup(state.table, name) do
      [{^name, preset}] ->
        {:reply, {:ok, preset.filters}, state}

      [] ->
        {:reply, {:error, "Preset not found: #{name}"}, state}
    end
  end

  @impl true
  def handle_call(:list_presets, _from, state) do
    presets =
      :ets.tab2list(state.table)
      |> Enum.map(fn {_name, preset} ->
        %{
          name: preset.name,
          description: preset.description,
          is_system: preset.is_system,
          tags: preset.tags,
          created_at: preset.created_at,
          updated_at: preset.updated_at
        }
      end)
      |> Enum.sort_by(& &1.name)

    {:reply, presets, state}
  end

  @impl true
  def handle_call({:delete_preset, name}, _from, state) do
    case :ets.lookup(state.table, name) do
      [{^name, %{is_system: true}}] ->
        {:reply, {:error, "Cannot delete system preset: #{name}"}, state}

      [{^name, _preset}] ->
        :ets.delete(state.table, name)
        persist_presets(state.table)
        {:reply, :ok, state}

      [] ->
        {:reply, {:error, "Preset not found: #{name}"}, state}
    end
  end

  @impl true
  def handle_call({:update_preset, name, filters, opts}, _from, state) do
    case :ets.lookup(state.table, name) do
      [{^name, preset}] ->
        if preset.is_system do
          {:reply, {:error, "Cannot update system preset: #{name}"}, state}
        else
          updated_preset = %{
            preset
            | filters: filters,
              description: Keyword.get(opts, :description, preset.description),
              tags: Keyword.get(opts, :tags, preset.tags),
              updated_at: DateTime.utc_now()
          }

          :ets.insert(state.table, {name, updated_preset})
          persist_presets(state.table)
          {:reply, {:ok, name}, state}
        end

      [] ->
        {:reply, {:error, "Preset not found: #{name}"}, state}
    end
  end

  @impl true
  def handle_call({:export_presets, file_path}, _from, state) do
    result = export_to_file(state.table, file_path)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:import_presets, file_path}, _from, state) do
    result = import_from_file(state.table, file_path)
    {:reply, result, state}
  end

  @impl true
  def handle_call({:find_by_tag, tag}, _from, state) do
    presets =
      :ets.tab2list(state.table)
      |> Enum.filter(fn {_name, preset} ->
        tag in preset.tags
      end)
      |> Enum.map(fn {_name, preset} ->
        %{
          name: preset.name,
          description: preset.description,
          tags: preset.tags
        }
      end)

    {:reply, presets, state}
  end

  # Private helper functions

  defp load_system_presets(table) do
    system_presets = [
      %__MODULE__{
        name: "blockchain",
        description: "Blockchain and Web3 experience",
        filters: %{
          technologies: ["Elixir", "Rust", "Solidity", "Go"],
          text_search: "blockchain",
          logic: :or
        },
        created_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        is_system: true,
        tags: ["web3", "blockchain"]
      },
      %__MODULE__{
        name: "defense",
        description: "Defense and submarine projects",
        filters: %{
          companies: ["General Dynamics Electric Boat"],
          include_sections: [:experience, :defense_projects]
        },
        created_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        is_system: true,
        tags: ["defense", "submarine"]
      },
      %__MODULE__{
        name: "recent",
        description: "Recent experience (last 2 years)",
        filters: %{
          date_range: %{
            from: "2022-01",
            to: Date.to_iso8601(Date.utc_today())
          }
        },
        created_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        is_system: true,
        tags: ["recent"]
      },
      %__MODULE__{
        name: "elixir",
        description: "Elixir development experience",
        filters: %{
          technologies: ["Elixir"],
          include_sections: [:experience, :portfolio]
        },
        created_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        is_system: true,
        tags: ["elixir", "functional"]
      },
      %__MODULE__{
        name: "leadership",
        description: "Leadership and management roles",
        filters: %{
          positions: ["CEO", "Lead", "Specialist"],
          logic: :or
        },
        created_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now(),
        is_system: true,
        tags: ["leadership"]
      }
    ]

    Enum.each(system_presets, fn preset ->
      :ets.insert(table, {preset.name, preset})
    end)
  end

  defp load_persisted_presets(table) do
    preset_file = Application.app_dir(:droodotfoo, @persist_file)

    case File.read(preset_file) do
      {:ok, json_content} ->
        case Jason.decode(json_content, keys: :atoms) do
          {:ok, presets} ->
            load_decoded_presets(table, presets)

          {:error, reason} ->
            Logger.error("Failed to decode presets JSON: #{inspect(reason)}")
        end

      {:error, :enoent} ->
        Logger.debug("No persisted presets file found, starting fresh")

      {:error, reason} ->
        Logger.error("Failed to read presets file: #{inspect(reason)}")
    end
  end

  defp load_decoded_presets(table, presets) do
    Enum.each(presets, fn preset_data ->
      preset = struct(__MODULE__, preset_data)

      unless preset.is_system do
        :ets.insert(table, {preset.name, preset})
      end
    end)

    Logger.info("Loaded #{length(presets)} persisted presets")
  end

  defp persist_presets(table) do
    # Only persist user presets (not system presets)
    user_presets =
      :ets.tab2list(table)
      |> Enum.filter(fn {_name, preset} -> not preset.is_system end)
      |> Enum.map(fn {_name, preset} -> preset end)

    preset_file = Application.app_dir(:droodotfoo, @persist_file)

    # Ensure directory exists
    File.mkdir_p!(Path.dirname(preset_file))

    case Jason.encode(user_presets, pretty: true) do
      {:ok, json} ->
        File.write(preset_file, json)

      {:error, reason} ->
        Logger.error("Failed to persist presets: #{inspect(reason)}")
    end
  end

  defp export_to_file(table, file_path) do
    presets =
      :ets.tab2list(table)
      |> Enum.map(fn {_name, preset} -> preset end)

    case Jason.encode(presets, pretty: true) do
      {:ok, json} ->
        case File.write(file_path, json) do
          :ok -> :ok
          {:error, reason} -> {:error, "Failed to write file: #{inspect(reason)}"}
        end

      {:error, reason} ->
        {:error, "Failed to encode presets: #{inspect(reason)}"}
    end
  end

  defp import_from_file(table, file_path) do
    with {:ok, json_content} <- File.read(file_path),
         {:ok, presets} <- Jason.decode(json_content, keys: :atoms) do
      count = import_presets_to_table(table, presets)
      persist_presets(table)
      {:ok, count}
    else
      {:error, %Jason.DecodeError{} = reason} ->
        {:error, "Failed to decode JSON: #{inspect(reason)}"}

      {:error, reason} ->
        {:error, "Failed to read file: #{inspect(reason)}"}
    end
  end

  defp import_presets_to_table(table, presets) do
    Enum.reduce(presets, 0, fn preset_data, acc ->
      preset = struct(__MODULE__, preset_data)
      :ets.insert(table, {preset.name, preset})
      acc + 1
    end)
  end
end
