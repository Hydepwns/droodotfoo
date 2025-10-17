defmodule Droodotfoo.Raxol.Renderer.Home do
  @moduledoc """
  Home section UI rendering for the terminal.
  Displays the unified home page with site structure, skills, and about information.
  """

  alias Droodotfoo.Raxol.BoxBuilder

  @doc """
  Build the unified home display with site structure and key information.
  """
  def build_unified_home(posts) do
    # Intro section
    intro_lines = [
      "",
      "Multi Disciplinary Engineer",
      "expertise in distributed systems and real-time apps.",
      "",
      "• 5+ years building scalable distributed systems",
      "• Elixir, Phoenix, LiveView expert",
      "• Terminal UI and CLI enthusiast",
      ""
    ]

    # Site structure section
    site_structure_lines = build_site_structure_tree(posts)

    # Skills section
    skills_lines = [
      "",
      Droodotfoo.AsciiChart.percent_bar("Elixir", 90,
        width: 35,
        label_width: 12,
        gradient: true,
        style: :rounded
      ),
      Droodotfoo.AsciiChart.percent_bar("Phoenix", 85,
        width: 35,
        label_width: 12,
        gradient: true,
        style: :rounded
      ),
      Droodotfoo.AsciiChart.percent_bar("LiveView", 95,
        width: 35,
        label_width: 12,
        gradient: true,
        style: :rounded
      ),
      Droodotfoo.AsciiChart.percent_bar("JavaScript", 75,
        width: 35,
        label_width: 12,
        gradient: true,
        style: :rounded
      ),
      ""
    ]

    # Build complete box with sections
    BoxBuilder.build_with_sections("droo.foo raxol terminal", [
      {"", intro_lines},
      {"Site Structure", site_structure_lines},
      {"Key Skills", skills_lines}
    ])
  end

  # Build the site structure tree
  defp build_site_structure_tree(posts) do
    posts_tree_lines =
      posts
      |> Enum.with_index()
      |> Enum.map(fn {post, index} ->
        is_last = index == length(posts) - 1
        connector = if is_last, do: "└", else: "├"
        "│  #{connector}─ #{post}.md"
      end)

    [
      "",
      "┌─ droo.foo",
      "│",
      "├─ posts/"
    ] ++
      posts_tree_lines ++
      [
        "│",
        "├─ terminal/",
        "│  ├─ about",
        "│  ├─ projects",
        "│  ├─ contact",
        "│  ├─ stl viewer",
        "│  └─ web3",
        "│",
        "├─ features/",
        "│  ├─ spotify integration",
        "│  ├─ github integration",
        "│  ├─ web3 wallet",
        "│  ├─ fileverse (encrypted docs)",
        "│  └─ games (tetris, snake, etc.)",
        "│",
        "└─ api/",
        "    ├─ /posts (obsidian publishing)",
        "    └─ /auth/spotify (oauth)",
        ""
      ]
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
