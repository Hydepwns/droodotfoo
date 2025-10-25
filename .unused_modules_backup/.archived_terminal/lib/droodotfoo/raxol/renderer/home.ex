defmodule Droodotfoo.Raxol.Renderer.Home do
  @moduledoc """
  Home section UI rendering for the terminal.
  Displays the unified home page with site structure, skills, and about information.
  """

  alias Droodotfoo.Raxol.BoxBuilder

  @doc """
  Build the simplified home display focusing on Raxol terminal capabilities.
  """
  def build_unified_home(_posts) do
    # Simplified intro focusing on what Raxol enables
    intro_lines = [
      "",
      "Welcome to droo.foo",
      "",
      "Blockchain infrastructure engineer | Open source developer",
      "Building production-grade FOSS tools for Web3",
      "",
      "This terminal UI is built with Raxol - a framework for creating",
      "keyboard-driven, vim-style terminal interfaces in Elixir.",
      ""
    ]

    # Raxol capabilities demo
    capabilities_lines = [
      "",
      "Terminal Features:",
      "",
      "  [>] Keyboard Navigation    - Arrow keys, hjkl (vim mode)",
      "  [>] Command Interface     - Type commands at the prompt",
      "  [>] ASCII Rendering       - Character-perfect monospace grid",
      "  [>] Interactive Games     - Snake, Tetris, 2048, Wordle, etc.",
      "  [>] Scrollable Content    - PageUp/PageDown navigation",
      "  [>] Responsive Design     - Adapts to terminal dimensions",
      ""
    ]

    # Links to full content pages with prominent ASCII navigation
    navigation_lines = [
      "",
      "Site Navigation - Click or visit these URLs:",
      "",
      "  ┌─────────────────────────────────────────────────────────┐",
      "  │  [ABOUT]     /about     Experience & Background         │",
      "  │  [PROJECTS]  /projects  Portfolio Showcase              │",
      "  │  [WEB3]      /web3      Blockchain Capabilities         │",
      "  │  [CONTACT]   /contact   Get In Touch                    │",
      "  │  [RESUME]    /resume    Full Resume                     │",
      "  └─────────────────────────────────────────────────────────┘",
      "",
      "Terminal: Press Tab to explore games, or type 'help' for commands.",
      ""
    ]

    # Build complete box with simplified sections
    BoxBuilder.build_with_sections("droo.foo", [
      {"", intro_lines},
      {"Capabilities", capabilities_lines},
      {"Site Links", navigation_lines}
    ])
  end

  @doc """
  Get the list of posts from the posts directory or fallback to defaults.
  """
  def get_posts do
    posts_dir = Path.join([Application.app_dir(:droodotfoo), "..", "priv", "posts"])

    case File.ls(posts_dir) do
      {:ok, files} ->
        files
        |> Enum.filter(&String.ends_with?(&1, ".md"))
        |> Enum.map(&String.replace_suffix(&1, ".md", ""))
        |> Enum.sort()

      {:error, _} ->
        ["welcome-to-droo-foo", "building-with-raxol", "test-api-post"]
    end
  end
end
