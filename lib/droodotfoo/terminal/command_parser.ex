defmodule Droodotfoo.Terminal.CommandParser do
  @moduledoc """
  Parses and executes terminal commands, providing a real Unix-like experience.
  """

  alias Droodotfoo.ErrorFormatter
  alias Droodotfoo.Terminal.{CommandRegistry, Commands, FileSystem}

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
    cmd
    |> dispatch_command(args, state)
    |> normalize_result()
  end

  # Command dispatch using pattern matching
  defp dispatch_command(cmd, args, state) do
    case command_map()[cmd] do
      nil -> handle_unknown_command(cmd)
      handler -> handler.(args, state)
    end
  end

  # Command registry map
  defp command_map do
    %{
      # Navigation commands
      "ls" => &Commands.ls/2,
      "cd" => &Commands.cd/2,
      "pwd" => fn _args, state -> Commands.pwd(state) end,
      # File operations
      "cat" => &Commands.cat/2,
      "head" => &Commands.head/2,
      "tail" => &Commands.tail/2,
      "grep" => &Commands.grep/2,
      "find" => &Commands.find/2,
      # System info
      "whoami" => fn _args, state -> Commands.whoami(state) end,
      "date" => fn _args, state -> Commands.date(state) end,
      "uptime" => fn _args, state -> Commands.uptime(state) end,
      "uname" => &Commands.uname/2,
      # Custom commands
      "help" => &Commands.help/2,
      "man" => &Commands.man/2,
      "clear" => fn _args, state -> Commands.clear(state) end,
      "history" => fn _args, state -> Commands.history(state) end,
      "echo" => &Commands.echo/2,
      # Fun commands
      "fortune" => fn _args, state -> Commands.fortune(state) end,
      "cowsay" => &Commands.cowsay/2,
      "sl" => fn _args, state -> Commands.sl(state) end,
      "matrix" => fn _args, state -> Commands.matrix([], state) end,
      # droo.foo specific
      "skills" => &Commands.skills/2,
      "contact" => &Commands.contact/2,
      "resume" => &Commands.resume/2,
      "download" => &Commands.download/2,
      "api" => &Commands.api/2,
      # Git commands
      "git" => &Commands.git/2,
      # Package managers
      "npm" => &Commands.npm/2,
      "pip" => &Commands.pip/2,
      # Network
      "curl" => &Commands.curl/2,
      "wget" => &Commands.wget/2,
      "ping" => &Commands.ping/2,
      # Easter eggs
      "sudo" => fn args, state -> Commands.sudo(args, state) end,
      "rm" => &Commands.rm/2,
      "vim" => &Commands.vim/2,
      "emacs" => &Commands.emacs/2,
      "exit" => fn _args, state -> Commands.exit(state) end,
      # Theme commands
      "theme" => &Commands.theme/2,
      "themes" => fn _args, state -> Commands.themes(state) end,
      # Performance commands
      "perf" => &Commands.perf/2,
      "dashboard" => &Commands.dashboard/2,
      "metrics" => &Commands.metrics/2,
      # Visual Effects
      "crt" => &Commands.crt/2,
      # Music/Entertainment
      "spotify" => &Commands.spotify/2,
      "music" => &Commands.music/2,
      # Development/Social
      "github" => &Commands.github/2,
      "gh" => &Commands.gh/2,
      # Web3
      "web3" => &Commands.web3/2,
      "wallet" => &Commands.wallet/2,
      "w3" => &Commands.w3/2,
      "ens" => &Commands.ens/2,
      "nft" => &Commands.nft/2,
      "nfts" => &Commands.nfts/2,
      "tokens" => &Commands.tokens/2,
      "balance" => &Commands.balance/2,
      "crypto" => &Commands.crypto/2,
      "tx" => &Commands.tx/2,
      "transactions" => &Commands.transactions/2,
      "contract" => &Commands.contract/2,
      "call" => &Commands.call/2,
      "ipfs" => &Commands.ipfs/2,
      # Fileverse
      "ddoc" => &Commands.ddoc/2,
      "docs" => &Commands.docs/2,
      "upload" => &Commands.upload/2,
      "files" => &Commands.files/2,
      "file" => &Commands.file/2,
      "portal" => &Commands.portal/2,
      # Encryption
      "encrypt" => &Commands.encrypt/2,
      "decrypt" => &Commands.decrypt/2,
      # dSheets
      "sheet" => &Commands.sheet/2,
      "sheets" => &Commands.sheets/2,
      # Portfolio
      "project" => &Commands.project/2,
      "projects" => fn _args, state -> Commands.projects([], state) end,
      "tree" => &Commands.tree/2,
      # Search
      "search" => &Commands.search/2,
      # Charts
      "charts" => fn _args, state -> Commands.charts(state) end,
      # Resume Export
      "resume_export" => &Commands.resume_export/2,
      "resume_formats" => &Commands.resume_formats/2,
      "resume_preview" => &Commands.resume_preview/2,
      # Contact Form
      "contact_form" => &Commands.contact_form/2,
      "contact_status" => &Commands.contact_status/2
    }
  end

  defp handle_unknown_command(cmd) do
    suggestions = suggest_command(cmd)
    formatted_error = ErrorFormatter.command_not_found(cmd, suggestions)
    {:error, formatted_error}
  end

  defp normalize_result(result) do
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
