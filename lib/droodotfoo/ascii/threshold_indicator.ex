defmodule Droodotfoo.Ascii.ThresholdIndicator do
  @moduledoc """
  Status visualization using threshold-based indicators.
  """

  @type threshold_style :: :symbols | :blocks | :dots
  @type thresholds :: %{good: number(), warning: number(), critical: number()}

  @default_thresholds %{good: 0, warning: 50, critical: 80}

  @doc """
  Create a threshold indicator with visual symbols.
  Returns a character indicating status based on thresholds.

  ## Options
  - `:style` - One of `:symbols`, `:blocks`, or `:dots` (default: `:symbols`)
  - `:good` - Threshold for good status (default: 0)
  - `:warning` - Threshold for warning status (default: 50)
  - `:critical` - Threshold for critical status (default: 80)
  """
  @spec render(number(), keyword()) :: String.t()
  def render(value, opts \\ []) do
    thresholds = extract_thresholds(opts)
    style = Keyword.get(opts, :style, :symbols)
    apply_style(value, thresholds, style)
  end

  @doc """
  Extract threshold values from options.
  """
  @spec extract_thresholds(keyword()) :: thresholds()
  def extract_thresholds(opts) do
    %{
      good: Keyword.get(opts, :good, @default_thresholds.good),
      warning: Keyword.get(opts, :warning, @default_thresholds.warning),
      critical: Keyword.get(opts, :critical, @default_thresholds.critical)
    }
  end

  # Style applications

  defp apply_style(value, thresholds, :symbols), do: symbols(value, thresholds)
  defp apply_style(value, thresholds, :blocks), do: blocks(value, thresholds)
  defp apply_style(value, thresholds, :dots), do: dots(value, thresholds)
  defp apply_style(value, thresholds, _), do: symbols(value, thresholds)

  @doc """
  Render using symbol characters (!, *, +, -).
  """
  @spec symbols(number(), thresholds()) :: String.t()
  def symbols(value, %{critical: critical, warning: warning, good: good}) do
    cond do
      value >= critical -> "!"
      value >= warning -> "*"
      value >= good -> "+"
      true -> "-"
    end
  end

  @doc """
  Render using block characters.
  """
  @spec blocks(number(), thresholds()) :: String.t()
  def blocks(value, %{critical: critical, warning: warning, good: good}) do
    cond do
      value >= critical -> "~"
      value >= warning -> "#"
      value >= good -> "+"
      true -> "-"
    end
  end

  @doc """
  Render using dot/circle characters.
  """
  @spec dots(number(), thresholds()) :: String.t()
  def dots(value, %{critical: critical, warning: warning, good: good}) do
    cond do
      value >= critical -> "@"
      value >= warning -> "O"
      value >= good -> "o"
      true -> "."
    end
  end
end
