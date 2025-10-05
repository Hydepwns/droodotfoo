defmodule Droodotfoo.BootSequence do
  @moduledoc """
  Boot sequence animation for terminal startup.

  Displays a retro boot screen with sequential messages.
  """

  @version Mix.Project.config()[:version] || "1.0.0"

  @boot_steps [
    {"RAXOL TERMINAL v#{@version}", 100},
    {"[OK] Initializing kernel...", 150},
    {"[OK] Loading modules...", 250},
    {"[OK] Starting Phoenix LiveView...", 275},
    {"[OK] Connecting WebSocket...", 300},
    {"[OK] Ready.", 200}
  ]

  @total_steps length(@boot_steps)

  @doc """
  Returns all boot steps with their delays in milliseconds.
  """
  def steps, do: @boot_steps

  @doc """
  Returns the total number of boot steps.
  """
  def total_steps, do: @total_steps

  @doc """
  Returns the delay for a given step (1-indexed).
  """
  def delay_for_step(step) when step > 0 and step <= @total_steps do
    {_msg, delay} = Enum.at(@boot_steps, step - 1)
    delay
  end

  def delay_for_step(_), do: 0

  @doc """
  Renders the boot sequence up to the given step.

  Returns a list of strings to be displayed in the terminal.
  """
  def render(current_step) when current_step >= 0 and current_step <= @total_steps do
    lines =
      @boot_steps
      |> Enum.take(current_step)
      |> Enum.map(fn {msg, _delay} -> msg end)

    # Add some spacing at the top
    ["", ""] ++ lines ++ [""]
  end

  def render(_), do: []

  @doc """
  Returns true if the boot sequence is complete.
  """
  def complete?(step), do: step > @total_steps

  @doc """
  Returns the welcome message shown after boot completes.
  """
  def welcome_message do
    [
      "",
      "droo.foo Terminal - Type 'help' for commands",
      ""
    ]
  end
end
