defmodule Droodotfoo.PluginSystem.Validator do
  @moduledoc """
  Plugin validation for ensuring modules implement the Plugin behaviour.
  """

  alias Droodotfoo.PluginSystem.Plugin

  @doc """
  Validate that a module implements the Plugin behaviour.

  ## Returns
  - `:ok` - Module is a valid plugin
  - `{:error, reason}` - Module is invalid
  """
  @spec validate(module()) :: :ok | {:error, String.t()}
  def validate(module) do
    behaviours = module.__info__(:attributes)[:behaviour] || []

    if Plugin in behaviours do
      :ok
    else
      {:error, "Module does not implement Plugin behaviour"}
    end
  rescue
    _ -> {:error, "Invalid plugin module"}
  end

  @doc """
  Check if a module is loaded and valid.
  """
  @spec loadable?(module()) :: boolean()
  def loadable?(module) do
    case Code.ensure_loaded(module) do
      {:module, _} -> true
      _ -> false
    end
  end
end
