#!/usr/bin/env elixir

defmodule CommandModuleTemplates do
  @moduledoc """
  Creates module templates for refactoring Commands.
  Each template includes TODOs for which functions to move.
  """

  @templates [
    %{
      name: "Navigation",
      file: "lib/droodotfoo/terminal/commands/navigation.ex",
      functions: ~w(ls cd pwd),
      helpers: ~w(parse_ls_args format_ls_output format_size),
      aliases: ["FileSystem"],
      line_range: "10-53, helpers at 2409-2455"
    },
    %{
      name: "FileOps",
      file: "lib/droodotfoo/terminal/commands/file_ops.ex",
      functions: ~w(find cat touch mkdir rm cp mv head tail wc grep_cmd),
      helpers: ~w(parse_find_args match_pattern? parse_head_tail_args),
      aliases: ["FileSystem"],
      line_range: "54-216, helpers at 77-105, 2457-2468"
    },
    %{
      name: "System",
      file: "lib/droodotfoo/terminal/commands/system.ex",
      functions: ~w(whoami hostname uname date_cmd env echo),
      helpers: [],
      aliases: [],
      line_range: "217-245"
    },
    %{
      name: "Utilities",
      file: "lib/droodotfoo/terminal/commands/utilities.ex",
      functions: ~w(help man clear_cmd history_cmd export_cmd download theme perf metrics crt high_contrast a11y),
      helpers: [],
      aliases: [],
      line_range: "246-375, 2470-2589"
    },
    %{
      name: "Fun",
      file: "lib/droodotfoo/terminal/commands/fun.ex",
      functions: ~w(cowsay fortune sl lolcat figlet weather joke),
      helpers: [],
      aliases: [],
      line_range: "377-435, 638-678"
    },
    %{
      name: "DrooFoo",
      file: "lib/droodotfoo/terminal/commands/droo_foo.ex",
      functions: ~w(about contact_cmd projects skills experience education api resume resume_pdf),
      helpers: [],
      aliases: [],
      line_range: "436-518, 2270-2398, 3838-3938"
    },
    %{
      name: "Git",
      file: "lib/droodotfoo/terminal/commands/git.ex",
      functions: ~w(git npm yarn cargo curl wget ping ssh tar),
      helpers: [],
      aliases: [],
      line_range: "519-637"
    },
    %{
      name: "Plugins",
      file: "lib/droodotfoo/terminal/commands/plugins.ex",
      functions: ~w(matrix rain spotify music github gh),
      helpers: ["launch_plugin"],
      aliases: [],
      line_range: "679-762, helper at 2401-2468"
    },
    %{
      name: "Web3",
      file: "lib/droodotfoo/terminal/commands/web3.ex",
      functions: ~w(web3 wallet w3 ens nft tokens balance tx contract call),
      helpers: [],
      aliases: [],
      line_range: "763-1311"
    },
    %{
      name: "Fileverse",
      file: "lib/droodotfoo/terminal/commands/fileverse.ex",
      functions: ~w(ipfs ddoc docs storage files file portal encrypt decrypt sheet sheets site_tree heartbit agent),
      helpers: ["truncate_string"],
      aliases: [],
      line_range: "1312-2269, 2590-3837"
    }
  ]

  def run do
    IO.puts("\n🏗️  Creating command module templates...\n")

    Enum.each(@templates, &create_template/1)

    IO.puts("\n✅ Created #{length(@templates)} module templates!")
    IO.puts("\nNext steps:")
    IO.puts("  1. Open lib/droodotfoo/terminal/commands.ex")
    IO.puts("  2. Copy functions from the line ranges specified in each TODO")
    IO.puts("  3. Paste into the corresponding module")
    IO.puts("  4. Run tests after each module")
    IO.puts("  5. Use defdelegate in main Commands module")
  end

  defp create_template(config) do
    IO.puts("📝 Creating #{config.name}...")

    content = """
    defmodule Droodotfoo.Terminal.Commands.#{config.name} do
      @moduledoc \"\"\"
      #{config.name} command implementations for the terminal.

      ## Functions to implement
      #{Enum.map(config.functions, fn f -> "  - #{f}/1 or #{f}/2" end) |> Enum.join("\n")}

      ## Helper functions needed
      #{if config.helpers == [], do: "  (none)", else: Enum.map(config.helpers, fn h -> "  - #{h}" end) |> Enum.join("\n")}

      ## Source location in original commands.ex
      Lines: #{config.line_range}
      \"\"\"

      # TODO: Add these aliases if needed
      #{format_aliases(config.aliases)}

      # TODO: Copy these function implementations from commands.ex:
      #{format_function_todos(config.functions)}

      #{if config.helpers != [] do
        "  # TODO: Copy these helper functions:\n" <>
        format_function_todos(config.helpers)
      else
        ""
      end}
    end
    """

    File.write!(config.file, content)
    IO.puts("   ✓ #{config.file}")
  end

  defp format_aliases([]), do: "  # (no aliases needed)"
  defp format_aliases(aliases) do
    Enum.map(aliases, fn alias_name ->
      "  # alias Droodotfoo.Terminal.#{alias_name}"
    end) |> Enum.join("\n")
  end

  defp format_function_todos(functions) do
    Enum.map(functions, fn func ->
      "  # def #{func}(...), do: ..."
    end) |> Enum.join("\n")
  end
end

CommandModuleTemplates.run()
