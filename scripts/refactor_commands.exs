#!/usr/bin/env elixir

defmodule CommandsRefactor do
  @moduledoc """
  Automatically refactors the massive Commands module into focused submodules.
  """

  @module_mapping %{
    navigation: %{
      lines: {10, 53},
      functions: ["ls", "cd", "pwd"],
      helpers: ["parse_ls_args", "format_ls_output", "format_size"]
    },
    file_ops: %{
      lines: {54, 216},
      functions: ["find", "cat", "touch", "mkdir", "rm", "cp", "mv", "head", "tail", "wc", "grep_cmd"],
      helpers: ["parse_find_args", "match_pattern?", "parse_head_tail_args"]
    },
    system: %{
      lines: {217, 245},
      functions: ["whoami", "hostname", "uname", "date_cmd", "env", "echo"]
    },
    utilities: %{
      lines: [{246, 375}, {2470, 2589}],
      functions: ["help", "man", "clear_cmd", "history_cmd", "export_cmd", "download",
                  "theme", "perf", "metrics", "crt", "high_contrast", "a11y"],
      helpers: []
    },
    fun: %{
      lines: [{377, 435}, {638, 678}],
      functions: ["cowsay", "fortune", "sl", "lolcat", "figlet", "weather", "joke"]
    },
    droo_foo: %{
      lines: [{436, 518}, {2270, 2398}, {3838, 3938}],
      functions: ["about", "contact_cmd", "projects", "skills", "experience", "education",
                  "api", "resume", "resume_pdf"],
      helpers: []
    },
    git: %{
      lines: [{519, 595}, {596, 637}],
      functions: ["git", "npm", "yarn", "cargo", "curl", "wget", "ping", "ssh", "tar"]
    },
    plugins: %{
      lines: [{679, 762}],
      functions: ["matrix", "rain", "spotify", "music", "github", "gh", "launch_plugin"],
      helpers: []
    },
    web3: %{
      lines: [{763, 1311}],
      functions: ["web3", "wallet", "w3", "ens", "nft", "tokens", "balance", "tx",
                  "contract", "call"],
      helpers: []
    },
    fileverse: %{
      lines: [{1312, 2269}, {2590, 3837}],
      functions: ["ipfs", "ddoc", "docs", "storage", "files", "file", "portal",
                  "encrypt", "decrypt", "sheet", "sheets", "site_tree", "heartbit",
                  "agent"],
      helpers: ["truncate_string"]
    }
  }

  def run do
    IO.puts("\n🔧 Starting Commands module refactoring...\n")

    source_file = "lib/droodotfoo/terminal/commands.ex"
    target_dir = "lib/droodotfoo/terminal/commands"

    # Read the source file
    content = File.read!(source_file)
    lines = String.split(content, "\n", trim: false)

    IO.puts("📖 Read #{length(lines)} lines from #{source_file}")

    # Create target directory
    File.mkdir_p!(target_dir)

    # Extract and create each module
    Enum.each(@module_mapping, fn {module_name, config} ->
      create_module(module_name, config, lines, target_dir)
    end)

    # Create the main module with defdelegate
    create_main_module(source_file)

    IO.puts("\n✅ Refactoring complete!")
    IO.puts("\n📊 Created #{map_size(@module_mapping)} new command modules")
    IO.puts("\nNext steps:")
    IO.puts("  1. Review the generated modules in #{target_dir}/")
    IO.puts("  2. Run tests: mix test")
    IO.puts("  3. Fix any issues")
    IO.puts("  4. Delete the old commands.ex after verification")
  end

  defp create_module(module_name, config, lines, target_dir) do
    module_name_pascal = module_name |> Atom.to_string() |> Macro.camelize()
    filename = "#{target_dir}/#{Atom.to_string(module_name)}.ex"

    IO.puts("📝 Creating #{module_name_pascal}...")

    # Extract lines for this module
    extracted_lines = extract_lines(config.lines, lines)
    helper_lines = extract_helpers(config[:helpers] || [], lines)

    # Build the module content
    content = build_module_content(module_name_pascal, extracted_lines, helper_lines)

    File.write!(filename, content)

    function_count = length(config.functions)
    helper_count = length(config[:helpers] || [])
    IO.puts("   ✓ #{filename} (#{function_count} functions, #{helper_count} helpers)")
  end

  defp extract_lines(line_ranges, lines) when is_list(line_ranges) do
    Enum.flat_map(line_ranges, fn range ->
      extract_lines(range, lines)
    end)
  end

  defp extract_lines({start_line, end_line}, lines) do
    Enum.slice(lines, (start_line - 1)..(end_line - 1))
  end

  defp extract_helpers([], _lines), do: []

  defp extract_helpers(helper_names, lines) do
    # Find helper functions in the file
    Enum.flat_map(helper_names, fn helper_name ->
      find_function(helper_name, lines, true)
    end)
  end

  defp find_function(func_name, lines, is_private) do
    prefix = if is_private, do: "defp", else: "def"
    pattern = ~r/^\s{2}#{prefix}\s+#{func_name}/

    # Find the start line
    start_idx = Enum.find_index(lines, fn line ->
      Regex.match?(pattern, line)
    end)

    if start_idx do
      # Find the end (next def/defp or end of section)
      end_idx = find_function_end(lines, start_idx + 1)
      Enum.slice(lines, start_idx..end_idx)
    else
      []
    end
  end

  defp find_function_end(lines, start_idx) do
    # Find the next function definition or end of file
    next_def = Enum.find_index(Enum.drop(lines, start_idx), fn line ->
      Regex.match?(~r/^\s{2}def(?:p)?\s+/, line)
    end)

    if next_def do
      start_idx + next_def - 1
    else
      length(lines) - 1
    end
  end

  defp build_module_content(module_name, function_lines, helper_lines) do
    """
    defmodule Droodotfoo.Terminal.Commands.#{module_name} do
      @moduledoc \"\"\"
      #{module_name} command implementations.
      \"\"\"

      alias Droodotfoo.Terminal.FileSystem
    #{if String.contains?(module_name, "Github"), do: "  alias Droodotfoo.Github.Client, as: GithubClient\n", else: ""}
    #{Enum.join(function_lines, "\n")}

    #{if helper_lines != [], do: "  # Helper functions\n\n", else: ""}#{Enum.join(helper_lines, "\n")}
    end
    """
  end

  defp create_main_module(source_file) do
    IO.puts("\n📝 Creating main Commands module with delegations...")

    # Backup original
    File.cp!(source_file, source_file <> ".backup")
    IO.puts("   ✓ Backed up original to #{source_file}.backup")

    # Create new main module
    content = """
    defmodule Droodotfoo.Terminal.Commands do
      @moduledoc \"\"\"
      Main entry point for all terminal commands.
      Commands are organized into focused submodules for maintainability.

      This module uses `defdelegate` to maintain backward compatibility
      while keeping the codebase organized.
      \"\"\"

      alias Droodotfoo.Terminal.Commands.{
        Navigation,
        FileOps,
        System,
        Utilities,
        Fun,
        DrooFoo,
        Git,
        Plugins,
        Web3,
        Fileverse
      }

      # Navigation Commands
      defdelegate ls(args, state), to: Navigation
      defdelegate cd(args, state), to: Navigation
      defdelegate pwd(state), to: Navigation

      # File Operations
      defdelegate find(args, state), to: FileOps
      defdelegate cat(args, state), to: FileOps
      defdelegate touch(args, state), to: FileOps
      defdelegate mkdir(args, state), to: FileOps
      defdelegate rm(args, state), to: FileOps
      defdelegate cp(args, state), to: FileOps
      defdelegate mv(args, state), to: FileOps
      defdelegate head(args, state), to: FileOps
      defdelegate tail(args, state), to: FileOps
      defdelegate wc(args, state), to: FileOps
      defdelegate grep_cmd(args, state), to: FileOps

      # System Info
      defdelegate whoami(state), to: System
      defdelegate hostname(state), to: System
      defdelegate uname(state), to: System
      defdelegate date_cmd(state), to: System
      defdelegate env(state), to: System
      defdelegate echo(args, state), to: System

      # Utilities
      defdelegate help(state), to: Utilities
      defdelegate man(args, state), to: Utilities
      defdelegate clear_cmd(state), to: Utilities
      defdelegate history_cmd(state), to: Utilities
      defdelegate export_cmd(args, state), to: Utilities
      defdelegate download(args, state), to: Utilities
      defdelegate theme(args, state), to: Utilities
      defdelegate perf(state), to: Utilities
      defdelegate metrics(state), to: Utilities
      defdelegate crt(args, state), to: Utilities
      defdelegate high_contrast(args, state), to: Utilities
      defdelegate a11y(args, state), to: Utilities

      # Fun Commands
      defdelegate cowsay(args, state), to: Fun
      defdelegate fortune(state), to: Fun
      defdelegate sl(state), to: Fun
      defdelegate lolcat(args, state), to: Fun
      defdelegate figlet(args, state), to: Fun
      defdelegate weather(args, state), to: Fun
      defdelegate joke(state), to: Fun

      # droo.foo Commands
      defdelegate about(state), to: DrooFoo
      defdelegate contact_cmd(state), to: DrooFoo
      defdelegate projects(state), to: DrooFoo
      defdelegate skills(state), to: DrooFoo
      defdelegate experience(state), to: DrooFoo
      defdelegate education(state), to: DrooFoo
      defdelegate api(args, state), to: DrooFoo
      defdelegate resume(args, state), to: DrooFoo
      defdelegate resume_pdf(state), to: DrooFoo

      # Git & Package Managers
      defdelegate git(args, state), to: Git
      defdelegate npm(args, state), to: Git
      defdelegate yarn(args, state), to: Git
      defdelegate cargo(args, state), to: Git
      defdelegate curl(args, state), to: Git
      defdelegate wget(args, state), to: Git
      defdelegate ping(args, state), to: Git
      defdelegate ssh(args, state), to: Git
      defdelegate tar(args, state), to: Git

      # Plugins
      defdelegate matrix(args, state), to: Plugins
      defdelegate rain(args, state), to: Plugins
      defdelegate spotify(args, state), to: Plugins
      defdelegate music(args, state), to: Plugins
      defdelegate github(args, state), to: Plugins
      defdelegate gh(args, state), to: Plugins

      # Web3
      defdelegate web3(args, state), to: Web3
      defdelegate wallet(args, state), to: Web3
      defdelegate w3(args, state), to: Web3
      defdelegate ens(args, state), to: Web3
      defdelegate nft(args, state), to: Web3
      defdelegate tokens(args, state), to: Web3
      defdelegate balance(args, state), to: Web3
      defdelegate tx(args, state), to: Web3
      defdelegate contract(args, state), to: Web3
      defdelegate call(args, state), to: Web3

      # Fileverse
      defdelegate ipfs(args, state), to: Fileverse
      defdelegate ddoc(args, state), to: Fileverse
      defdelegate docs(args, state), to: Fileverse
      defdelegate storage(args, state), to: Fileverse
      defdelegate files(args, state), to: Fileverse
      defdelegate file(args, state), to: Fileverse
      defdelegate portal(args, state), to: Fileverse
      defdelegate encrypt(args, state), to: Fileverse
      defdelegate decrypt(args, state), to: Fileverse
      defdelegate sheet(args, state), to: Fileverse
      defdelegate sheets(args, state), to: Fileverse
      defdelegate site_tree(state), to: Fileverse
      defdelegate heartbit(args, state), to: Fileverse
      defdelegate agent(args, state), to: Fileverse
    end
    """

    File.write!(source_file <> ".new", content)
    IO.puts("   ✓ Created #{source_file}.new")
    IO.puts("\n⚠️  Original file backed up to #{source_file}.backup")
    IO.puts("   After testing, run: mv #{source_file}.new #{source_file}")
  end
end

CommandsRefactor.run()
