defmodule Droodotfoo.Terminal.CommandParser do
  @moduledoc """
  Parses and executes terminal commands, providing a real Unix-like experience.
  """

  alias Droodotfoo.Terminal.{FileSystem, Commands, CommandRegistry}
  alias Droodotfoo.ErrorFormatter

  @doc """
  Parse and execute a command string.
  Returns {:ok, output} or {:error, message}
  """
  def parse_and_execute(input, state) do
    input
    |> String.trim()
    |> tokenize()
    |> execute_command(state)
  end

  @doc """
  Tokenize input into command and arguments.
  Handles quotes, pipes, and redirects.
  """
  def tokenize(input) do
    # Handle empty input
    if input == "" do
      {:empty}
    else
      # Simple tokenization for now - can be enhanced
      case parse_command_line(input) do
        {:ok, tokens} -> {:command, tokens}
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp parse_command_line(input) do
    # Handle quoted strings and special characters
    tokens =
      input
      |> parse_with_quotes()
      |> handle_pipes()
      |> handle_redirects()

    {:ok, tokens}
  rescue
    _ -> {:error, "Invalid command syntax"}
  end

  defp parse_with_quotes(input) do
    # Regex to match quoted strings and regular tokens
    ~r/(?:[^\s"']+|"[^"]*"|'[^']*')+/
    |> Regex.scan(input)
    |> List.flatten()
    |> Enum.map(&strip_quotes/1)
  end

  defp strip_quotes(str) do
    str
    |> String.replace(~r/^["']/, "")
    |> String.replace(~r/["']$/, "")
  end

  defp handle_pipes(tokens) do
    # Split on pipe character for command chaining
    # For now, return as-is (enhancement for later)
    tokens
  end

  defp handle_redirects(tokens) do
    # Handle > >> < redirects
    # For now, return as-is (enhancement for later)
    tokens
  end

  @doc """
  Execute a parsed command.
  """
  def execute_command({:empty}, _state) do
    {:ok, ""}
  end

  def execute_command({:error, reason}, _state) do
    {:error, reason}
  end

  def execute_command({:command, []}, _state) do
    {:ok, ""}
  end

  def execute_command({:command, [cmd | args]}, state) do
    result =
      case cmd do
        # Navigation commands
        "ls" ->
          Commands.ls(args, state)

        "cd" ->
          Commands.cd(args, state)

        "pwd" ->
          Commands.pwd(state)

        # File operations
        "cat" ->
          Commands.cat(args, state)

        "head" ->
          Commands.head(args, state)

        "tail" ->
          Commands.tail(args, state)

        "grep" ->
          Commands.grep(args, state)

        "find" ->
          Commands.find(args, state)

        # System info
        "whoami" ->
          Commands.whoami(state)

        "date" ->
          Commands.date(state)

        "uptime" ->
          Commands.uptime(state)

        "uname" ->
          Commands.uname(args, state)

        # Custom commands
        "help" ->
          Commands.help(args, state)

        "man" ->
          Commands.man(args, state)

        "clear" ->
          Commands.clear(state)

        "history" ->
          Commands.history(state)

        "echo" ->
          Commands.echo(args, state)

        # Fun commands
        "fortune" ->
          Commands.fortune(state)

        "cowsay" ->
          Commands.cowsay(args, state)

        "sl" ->
          Commands.sl(state)

        "matrix" ->
          Commands.matrix([], state)

        # droo.foo specific
        "skills" ->
          Commands.skills(args, state)

        "contact" ->
          Commands.contact(args, state)

        "resume" ->
          Commands.resume(args, state)

        "download" ->
          Commands.download(args, state)

        "api" ->
          Commands.api(args, state)

        # Git commands
        "git" ->
          Commands.git(args, state)

        # Package managers
        "npm" ->
          Commands.npm(args, state)

        "pip" ->
          Commands.pip(args, state)

        # Network
        "curl" ->
          Commands.curl(args, state)

        "wget" ->
          Commands.wget(args, state)

        "ping" ->
          Commands.ping(args, state)

        # Easter eggs
        "sudo" ->
          Commands.sudo([cmd | args], state)

        "rm" ->
          Commands.rm(args, state)

        "vim" ->
          Commands.vim(args, state)

        "emacs" ->
          Commands.emacs(args, state)

        "exit" ->
          Commands.exit(state)

        # Theme commands
        "theme" ->
          Commands.theme(args, state)

        "themes" ->
          Commands.themes(state)

        # Performance commands
        "perf" ->
          Commands.perf(args, state)

        "dashboard" ->
          Commands.dashboard(args, state)

        "metrics" ->
          Commands.metrics(args, state)

        # Visual Effects
        "crt" ->
          Commands.crt(args, state)

        # Music/Entertainment
        "spotify" ->
          Commands.spotify(args, state)

        "music" ->
          Commands.music(args, state)

        # Development/Social
        "github" ->
          Commands.github(args, state)

        "gh" ->
          Commands.gh(args, state)

        # Web3
        "web3" ->
          Commands.web3(args, state)

        "wallet" ->
          Commands.wallet(args, state)

        "w3" ->
          Commands.w3(args, state)

        # Portfolio
        "project" ->
          Commands.project(args, state)

        "projects" ->
          Commands.projects(state)

        # Search
        "search" ->
          Commands.search(args, state)

        # Charts
        "charts" ->
          Commands.charts(state)

        # Unknown command
        _ ->
          suggestions = suggest_command(cmd)
          formatted_error = ErrorFormatter.command_not_found(cmd, suggestions)
          {:error, formatted_error}
      end

    # Normalize return values to ensure consistent format
    case result do
      {:ok, output, new_state} -> {:ok, output, new_state}
      {:ok, output} -> {:ok, output}
      {:error, msg} -> {:error, msg}
      {:exit, msg} -> {:exit, msg}
      {:plugin, plugin_name, output} -> {:plugin, plugin_name, output}
      {:search, query} -> {:search, query}
    end
  end

  @doc """
  Suggest similar commands based on input.
  Uses Levenshtein distance for fuzzy matching.
  """
  def suggest_command(input) do
    CommandRegistry.all_command_names()
    |> Enum.map(fn cmd -> {cmd, String.jaro_distance(input, cmd)} end)
    |> Enum.filter(fn {_cmd, score} -> score > 0.7 end)
    |> Enum.sort_by(fn {_cmd, score} -> score end, :desc)
    |> Enum.take(3)
    |> Enum.map(fn {cmd, _score} -> cmd end)
  end


  @doc """
  Get command completion suggestions.
  """
  def get_completions(partial_input, state) do
    all_commands = get_all_commands()

    if String.contains?(partial_input, " ") do
      # Complete arguments for specific command
      [cmd | args] = String.split(partial_input, " ")
      get_argument_completions(cmd, Enum.join(args, " "), state)
    else
      # Complete command name
      all_commands
      |> Enum.filter(&String.starts_with?(&1, partial_input))
      |> Enum.sort()
    end
  end

  defp get_all_commands do
    CommandRegistry.all_command_names()
  end

  defp get_argument_completions("cd", partial_path, state) do
    FileSystem.get_directory_completions(partial_path, state)
  end

  defp get_argument_completions("cat", partial_path, state) do
    FileSystem.get_file_completions(partial_path, state)
  end

  defp get_argument_completions("git", partial_arg, _state) do
    git_commands = [
      "status",
      "log",
      "diff",
      "add",
      "commit",
      "push",
      "pull",
      "branch",
      "checkout",
      "merge",
      "rebase",
      "clone"
    ]

    git_commands
    |> Enum.filter(&String.starts_with?(&1, partial_arg))
  end

  defp get_argument_completions("stl", partial_arg, _state) do
    stl_commands = [
      "load",
      "info",
      "mode",
      "rotate",
      "reset",
      "ascii",
      "help"
    ]

    stl_commands
    |> Enum.filter(&String.starts_with?(&1, partial_arg))
  end

  defp get_argument_completions(_cmd, _partial_arg, _state) do
    []
  end
end
