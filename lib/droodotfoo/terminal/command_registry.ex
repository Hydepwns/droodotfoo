defmodule Droodotfoo.Terminal.CommandRegistry do
  @moduledoc """
  Central registry of all terminal commands.
  Single source of truth for command definitions, aliases, and metadata.
  """

  @commands [
    # Navigation
    %{
      name: "ls",
      aliases: ["list", "dir"],
      category: :navigation,
      description: "List directory contents"
    },
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
    %{
      name: "tree",
      aliases: [],
      category: :content,
      description: "Display site structure as ASCII tree"
    },

    # Games & Plugins
    %{name: "tetris", aliases: ["t"], category: :game, description: "Play Tetris"},
    %{name: "snake", aliases: [], category: :game, description: "Play Snake"},
    %{name: "wordle", aliases: ["word"], category: :game, description: "Play Wordle"},
    %{name: "conway", aliases: ["life"], category: :game, description: "Conway's Game of Life"},
    %{name: "2048", aliases: [], category: :game, description: "Play 2048"},
    %{
      name: "typing",
      aliases: ["type", "wpm"],
      category: :game,
      description: "Typing speed test"
    },
    %{name: "calculator", aliases: ["calc"], category: :tool, description: "Simple calculator"},

    # Integrations
    %{
      name: "spotify",
      aliases: ["music"],
      category: :integration,
      description: "Spotify integration"
    },
    %{name: "github", aliases: ["gh"], category: :integration, description: "GitHub integration"},
    %{
      name: "web3",
      aliases: ["wallet", "w3"],
      category: :integration,
      description: "Web3 wallet integration"
    },
    %{name: "ens", aliases: [], category: :integration, description: "Resolve ENS names"},
    %{name: "nft", aliases: [], category: :integration, description: "NFT gallery and viewer"},
    %{
      name: "nfts",
      aliases: [],
      category: :integration,
      description: "List NFTs (alias for nft list)"
    },
    %{
      name: "tokens",
      aliases: [],
      category: :integration,
      description: "View token balances with USD values"
    },
    %{
      name: "balance",
      aliases: [],
      category: :integration,
      description: "Get token price and chart"
    },
    %{
      name: "crypto",
      aliases: [],
      category: :integration,
      description: "View crypto balances (alias for tokens)"
    },
    %{
      name: "tx",
      aliases: [],
      category: :integration,
      description: "View transaction history and details"
    },
    %{
      name: "transactions",
      aliases: [],
      category: :integration,
      description: "View transaction history (alias for tx)"
    },
    %{
      name: "contract",
      aliases: [],
      category: :integration,
      description: "View contract ABI and call functions"
    },
    %{
      name: "call",
      aliases: [],
      category: :integration,
      description: "Call contract function (alias for contract)"
    },
    %{
      name: "ipfs",
      aliases: [],
      category: :integration,
      description: "Fetch and display IPFS content"
    },
    %{
      name: "ddoc",
      aliases: [],
      category: :integration,
      description: "Fileverse encrypted documents"
    },
    %{
      name: "docs",
      aliases: [],
      category: :integration,
      description: "List dDocs (alias for ddoc list)"
    },
    %{
      name: "upload",
      aliases: [],
      category: :integration,
      description: "Upload file to IPFS via Fileverse"
    },
    %{name: "files", aliases: [], category: :integration, description: "List uploaded files"},
    %{
      name: "file",
      aliases: [],
      category: :integration,
      description: "View file info and versions"
    },
    %{
      name: "portal",
      aliases: [],
      category: :integration,
      description: "Fileverse Portal P2P collaboration spaces"
    },
    %{
      name: "encrypt",
      aliases: [],
      category: :integration,
      description: "Encrypt document with wallet-derived keys"
    },
    %{
      name: "decrypt",
      aliases: [],
      category: :integration,
      description: "Decrypt document with wallet keys"
    },
    %{
      name: "privacy",
      aliases: [],
      category: :utility,
      description: "Toggle privacy mode for sensitive data"
    },
    %{
      name: "keys",
      aliases: [],
      category: :integration,
      description: "Manage encryption keys"
    },
    %{
      name: "sheet",
      aliases: [],
      category: :integration,
      description: "Fileverse dSheets - onchain data visualization"
    },
    %{
      name: "sheets",
      aliases: [],
      category: :integration,
      description: "List dSheets (alias for sheet list)"
    },
    %{
      name: "like",
      aliases: [],
      category: :integration,
      description: "Send HeartBit (like) to content"
    },
    %{
      name: "likes",
      aliases: [],
      category: :integration,
      description: "View HeartBits for content"
    },
    %{
      name: "activity",
      aliases: [],
      category: :integration,
      description: "View social activity feed"
    },
    %{
      name: "heartbits",
      aliases: [],
      category: :integration,
      description: "View HeartBits you've sent"
    },
    %{
      name: "heartbit_metrics",
      aliases: [],
      category: :integration,
      description: "View HeartBit engagement metrics for content"
    },
    %{
      name: "agent",
      aliases: [],
      category: :integration,
      description: "AI agent for natural language blockchain queries"
    },
    %{
      name: "agent_help",
      aliases: [],
      category: :integration,
      description: "Show AI agent capabilities and examples"
    },
    %{
      name: "agent_recommendations",
      aliases: [],
      category: :integration,
      description: "Get AI-powered recommendations for your wallet"
    },
    %{
      name: "agent_analyze",
      aliases: [],
      category: :integration,
      description: "AI analysis of your blockchain data"
    },

    # Utilities
    %{name: "matrix", aliases: [], category: :effect, description: "Matrix rain effect"},
    %{name: "search", aliases: ["find"], category: :utility, description: "Search content"},
    %{name: "theme", aliases: [], category: :utility, description: "Change terminal theme"},
    # Resume Export
    %{
      name: "resume_export",
      aliases: ["resume"],
      category: :content,
      description: "Open resume export with multiple formats and PDF generation"
    },
    %{
      name: "resume_formats",
      aliases: [],
      category: :utility,
      description: "List available resume formats and their descriptions"
    },
    %{
      name: "resume_preview",
      aliases: [],
      category: :utility,
      description: "Preview resume in specified format (technical, executive, minimal, detailed)"
    },
    # Contact Form
    %{
      name: "contact_form",
      aliases: ["contact"],
      category: :content,
      description: "Open contact form with validation and email integration"
    },
    %{
      name: "contact_status",
      aliases: [],
      category: :utility,
      description: "Check contact form status and rate limiting"
    }
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

      command_lines = Enum.map(cmds, &format_command_line/1)

      [category_name | command_lines]
    end)
    |> List.flatten()
  end

  @doc """
  Gets commands by category.
  """
  def get_commands_by_category(category) when is_atom(category) do
    @commands
    |> Enum.filter(&(&1.category == category))
  end

  @doc """
  Gets all command categories.
  """
  def get_categories do
    @commands
    |> Enum.map(& &1.category)
    |> Enum.uniq()
    |> Enum.sort()
  end

  @doc """
  Searches commands by name or description.
  """
  def search_commands(query) when is_binary(query) do
    query_lower = String.downcase(query)

    @commands
    |> Enum.filter(fn cmd ->
      String.contains?(String.downcase(cmd.name), query_lower) or
        String.contains?(String.downcase(cmd.description), query_lower) or
        Enum.any?(cmd.aliases, &String.contains?(String.downcase(&1), query_lower))
    end)
  end

  @doc """
  Gets command statistics.
  """
  def get_statistics do
    total_commands = length(@commands)
    categories = get_categories()

    category_counts =
      Enum.map(categories, fn cat ->
        {cat, length(get_commands_by_category(cat))}
      end)

    %{
      total_commands: total_commands,
      categories: length(categories),
      category_counts: category_counts,
      most_common_category:
        category_counts |> Enum.max_by(fn {_cat, count} -> count end) |> elem(0)
    }
  end

  @doc """
  Gets commands with aliases.
  """
  def get_commands_with_aliases do
    @commands
    |> Enum.filter(&(!Enum.empty?(&1.aliases)))
  end

  @doc """
  Gets commands without aliases.
  """
  def get_commands_without_aliases do
    @commands
    |> Enum.filter(&Enum.empty?(&1.aliases))
  end

  @doc """
  Validates command registry for duplicates and conflicts.
  """
  def validate_registry do
    commands = @commands
    names = Enum.map(commands, & &1.name)
    all_aliases = commands |> Enum.flat_map(& &1.aliases)

    duplicate_names = names -- Enum.uniq(names)
    duplicate_aliases = all_aliases -- Enum.uniq(all_aliases)

    name_alias_conflicts =
      Enum.filter(commands, fn cmd ->
        Enum.any?(cmd.aliases, &(&1 == cmd.name))
      end)

    %{
      valid:
        Enum.empty?(duplicate_names) and Enum.empty?(duplicate_aliases) and
          Enum.empty?(name_alias_conflicts),
      duplicate_names: duplicate_names,
      duplicate_aliases: duplicate_aliases,
      name_alias_conflicts: name_alias_conflicts
    }
  end

  @doc """
  Exports command registry to JSON format.
  """
  def export_to_json do
    @commands
    |> Jason.encode!(pretty: true)
  end

  @doc """
  Imports command registry from JSON format.
  """
  def import_from_json(json_string) when is_binary(json_string) do
    case Jason.decode(json_string) do
      {:ok, commands} -> {:ok, commands}
      {:error, reason} -> {:error, reason}
    end
  end

  # Private helper functions

  defp format_command_line(cmd) do
    aliases_str = format_aliases(cmd.aliases)
    "  #{String.pad_trailing(cmd.name, 12)}#{aliases_str} - #{cmd.description}"
  end

  defp format_aliases([]), do: ""
  defp format_aliases(aliases), do: " (#{Enum.join(aliases, ", ")})"
end
