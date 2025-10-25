defmodule Droodotfoo.Terminal.Commands.System do
  @moduledoc """
  System information and basic utility command implementations.

  Provides commands for:
  - whoami: Display current user
  - date: Display current date/time
  - uptime: Display system uptime
  - uname: Display system information
  - echo: Echo arguments
  - hostname: Display hostname
  - env: Display environment info
  """

  use Droodotfoo.Terminal.CommandBase

  @impl true
  def execute("whoami", _args, state), do: whoami(state)
  def execute("date", _args, state), do: date(state)
  def execute("uptime", _args, state), do: uptime(state)
  def execute("uname", args, state), do: uname(args, state)
  def execute("echo", args, state), do: echo(args, state)
  def execute("hostname", _args, state), do: hostname(state)
  def execute("env", _args, state), do: env(state)

  def execute(command, _args, state) do
    {:error, "Unknown system command: #{command}", state}
  end

  @doc """
  Returns the current user.
  """
  def whoami(_state) do
    {:ok, "drew"}
  end

  @doc """
  Returns the current date and time in UTC.
  """
  def date(_state) do
    {:ok, DateTime.utc_now() |> DateTime.to_string()}
  end

  @doc """
  Returns system uptime information.
  """
  def uptime(_state) do
    # Calculate uptime from state.start_time if available
    {:ok, "up 42 days, 3:14, 1 user, load average: 0.15, 0.12, 0.10"}
  end

  @doc """
  Returns system information similar to Unix uname command.

  Supports flags:
  - `-a`: All information
  - `-s`: System name
  - `-n`: Node name (hostname)
  - `-r`: Release version
  """
  def uname(args, _state) do
    output =
      case args do
        ["-a"] -> "Linux droo.foo 5.15.0 #1 SMP x86_64 GNU/Linux"
        ["-s"] -> "Linux"
        ["-n"] -> "droo.foo"
        ["-r"] -> "5.15.0"
        [] -> "Linux"
        _ -> "Linux"
      end

    {:ok, output}
  end

  @doc """
  Echoes the provided arguments.
  """
  def echo(args, _state) do
    {:ok, Enum.join(args, " ")}
  end

  @doc """
  Returns the system hostname.
  """
  def hostname(_state) do
    {:ok, "droo.foo"}
  end

  @doc """
  Returns environment information.
  """
  def env(_state) do
    env_vars = """
    PATH=/usr/local/bin:/usr/bin:/bin
    HOME=/home/drew
    USER=drew
    SHELL=/bin/bash
    PWD=/home/drew
    TERM=xterm-256color
    """

    {:ok, String.trim(env_vars)}
  end
end
