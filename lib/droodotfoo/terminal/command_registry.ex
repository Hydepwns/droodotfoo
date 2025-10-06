defmodule Droodotfoo.Terminal.CommandRegistry do
  @moduledoc """
  Central registry of all terminal commands.
  Single source of truth for command definitions, aliases, and metadata.
  """

  @commands [
    # Navigation
    %{name: "ls", aliases: ["list", "dir"], category: :navigation, description: "List directory contents"},
    %{name: "cd", aliases: [], category: :navigation, description: "Change directory"},
    %{name: "pwd", aliases: [], category: :navigation, description: "Print working directory"},
    %{name: "cat", aliases: [], category: :file, description: "Display file contents"},
    %{name: "head", aliases: [], category: :file, description: "Show first lines of file"},
    %{name: "tail", aliases: [], category: :file, description: "Show last lines of file"},

    # System
    %{name: "clear", aliases: [], category: :system, description: "Clear the screen"},
    %{name: "help", aliases: ["?"], category: :system, description: "Show help information"},
    %{name: "whoami", aliases: [], category: :system, description: "Display current user"},
    %{name: "uname", aliases: [], category: :system, description: "Display system information"},
    %{name: "date", aliases: [], category: :system, description: "Display current date"},
    %{name: "echo", aliases: [], category: :system, description: "Print text to screen"},
    %{name: "exit", aliases: ["quit", "q"], category: :system, description: "Exit the terminal"},

    # Features
    %{name: "projects", aliases: [], category: :content, description: "View projects showcase"},
    %{name: "skills", aliases: [], category: :content, description: "View skills and expertise"},
    %{name: "about", aliases: ["bio"], category: :content, description: "Learn about me"},
    %{name: "contact", aliases: [], category: :content, description: "Get contact information"},
    %{name: "blog", aliases: ["posts"], category: :content, description: "Read blog posts"},

    # Games & Plugins
    %{name: "tetris", aliases: ["t"], category: :game, description: "Play Tetris"},
    %{name: "snake", aliases: [], category: :game, description: "Play Snake"},
    %{name: "wordle", aliases: ["word"], category: :game, description: "Play Wordle"},
    %{name: "conway", aliases: ["life"], category: :game, description: "Conway's Game of Life"},
    %{name: "2048", aliases: [], category: :game, description: "Play 2048"},
    %{name: "typing", aliases: ["type", "wpm"], category: :game, description: "Typing speed test"},
    %{name: "calculator", aliases: ["calc"], category: :tool, description: "Simple calculator"},

    # Integrations
    %{name: "spotify", aliases: ["music"], category: :integration, description: "Spotify integration"},
    %{name: "github", aliases: ["gh"], category: :integration, description: "GitHub integration"},
    %{name: "web3", aliases: ["wallet", "w3"], category: :integration, description: "Web3 wallet integration"},
    %{name: "ens", aliases: [], category: :integration, description: "Resolve ENS names"},
    %{name: "nft", aliases: [], category: :integration, description: "NFT gallery and viewer"},
    %{name: "nfts", aliases: [], category: :integration, description: "List NFTs (alias for nft list)"},
    %{name: "tokens", aliases: [], category: :integration, description: "View token balances with USD values"},
    %{name: "balance", aliases: [], category: :integration, description: "Get token price and chart"},
    %{name: "crypto", aliases: [], category: :integration, description: "View crypto balances (alias for tokens)"},
    %{name: "tx", aliases: [], category: :integration, description: "View transaction history and details"},
    %{name: "transactions", aliases: [], category: :integration, description: "View transaction history (alias for tx)"},
    %{name: "contract", aliases: [], category: :integration, description: "View contract ABI and call functions"},
    %{name: "call", aliases: [], category: :integration, description: "Call contract function (alias for contract)"},
    %{name: "ipfs", aliases: [], category: :integration, description: "Fetch and display IPFS content"},
    %{name: "ddoc", aliases: [], category: :integration, description: "Fileverse encrypted documents"},
    %{name: "docs", aliases: [], category: :integration, description: "List dDocs (alias for ddoc list)"},
    %{name: "upload", aliases: [], category: :integration, description: "Upload file to IPFS via Fileverse"},
    %{name: "files", aliases: [], category: :integration, description: "List uploaded files"},
    %{name: "file", aliases: [], category: :integration, description: "View file info and versions"},

    # Utilities
    %{name: "matrix", aliases: [], category: :effect, description: "Matrix rain effect"},
    %{name: "search", aliases: ["find"], category: :utility, description: "Search content"},
    %{name: "theme", aliases: [], category: :utility, description: "Change terminal theme"}
  ]

  @doc """
  Returns all registered commands.
  """
  def all_commands, do: @commands

  @doc """
  Returns list of all command names (including aliases).
  """
  def all_command_names do
    Enum.flat_map(@commands, fn cmd ->
      [cmd.name | cmd.aliases]
    end)
  end

  @doc """
  Returns commands filtered by category.
  """
  def commands_by_category(category) do
    Enum.filter(@commands, &(&1.category == category))
  end

  @doc """
  Returns all unique categories.
  """
  def categories do
    @commands
    |> Enum.map(& &1.category)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Finds a command by name or alias.
  Returns {:ok, command} or :error.
  """
  def find_command(name) do
    result =
      Enum.find(@commands, fn cmd ->
        cmd.name == name or name in cmd.aliases
      end)

    case result do
      nil -> :error
      cmd -> {:ok, cmd}
    end
  end

  @doc """
  Suggests commands based on partial input.
  Returns list of matching command names.
  """
  def suggest_commands(prefix) do
    all_command_names()
    |> Enum.filter(&String.starts_with?(&1, prefix))
    |> Enum.sort()
  end

  @doc """
  Returns help text for all commands, grouped by category.
  """
  def help_text do
    @commands
    |> Enum.group_by(& &1.category)
    |> Enum.sort_by(fn {cat, _} -> cat end)
    |> Enum.map(fn {category, cmds} ->
      category_name = category |> Atom.to_string() |> String.upcase()

      command_lines =
        Enum.map(cmds, fn cmd ->
          aliases_str =
            if Enum.empty?(cmd.aliases) do
              ""
            else
              " (#{Enum.join(cmd.aliases, ", ")})"
            end

          "  #{String.pad_trailing(cmd.name, 12)}#{aliases_str} - #{cmd.description}"
        end)

      [category_name | command_lines]
    end)
    |> List.flatten()
  end
end
