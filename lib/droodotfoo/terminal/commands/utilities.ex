defmodule Droodotfoo.Terminal.Commands.Utilities do
  @moduledoc """
  Utility command implementations for the terminal.

  Provides commands for:
  - Help & Documentation: help, man
  - Terminal control: clear, history
  - Themes: theme, themes
  - Performance monitoring: perf, dashboard, metrics
  - Accessibility: crt, contrast, a11y
  - Navigation: search, tree
  """

  @available_themes %{
    "synthwave84" => "theme-synthwave84",
    "synthwave84-soft" => "theme-synthwave84-soft",
    "synthwave84-high" => "theme-synthwave84-high",
    "green" => "theme-green",
    "amber" => "theme-amber",
    "matrix" => "theme-matrix",
    "phosphor" => "theme-phosphor",
    "cyberpunk" => "theme-cyberpunk"
  }

  # Help & Documentation

  @doc """
  Display help information for all commands or a specific command.
  """
  def help([], _state) do
    {:ok,
     """
     droo.foo Terminal - Available Commands
     =====================================

     Navigation:
       ls [path]       List directory contents
       cd [path]       Change directory
       pwd             Print working directory

     Files:
       cat <file>      Display file contents
       head <file>     Show first lines of file
       tail <file>     Show last lines of file
       grep <pattern>  Search for pattern in files

     System:
       whoami          Display current user
       date            Show current date/time
       uptime          Show system uptime
       uname [-a]      Show system information

     droo.foo:
       projects        Browse my projects
       skills          View my skills
       resume          Display my resume
       contact         Contact information
       download        Download resume as PDF
       tree            Display site structure as ASCII tree

     Navigation:
       Press 1-6 to jump to sections:
       1=Home (with site map & skills), 2=Experience, 3=Contact
       4=Spotify, 5=STL Viewer, 6=Web3

     Fun:
       fortune         Display a fortune
       cowsay <text>   Cow says something
       sl              Steam locomotive
       matrix          Enter the matrix
       conway          Conway's Game of Life
       typing          Typing speed test (WPM)
       snake           Play Snake game

     Other:
       clear           Clear the terminal
       history         Show command history
       echo <text>     Print text
       help [cmd]      Show help for command
       man <cmd>       Manual page for command
       exit            Exit terminal

     Try 'help <command>' for more info on a specific command.
     """}
  end

  def help([cmd], _state) do
    help_text =
      case cmd do
        "ls" ->
          """
          ls - list directory contents

          Usage: ls [OPTION]... [FILE]...

          Options:
            -l  use a long listing format
            -a  show hidden files
            -h  human-readable sizes

          Examples:
            ls            List current directory
            ls -la        Long format with hidden files
            ls projects   List projects directory
          """

        "cd" ->
          """
          cd - change directory

          Usage: cd [DIRECTORY]

          Change the current directory to DIRECTORY.
          With no arguments, changes to home directory.

          Examples:
            cd            Go to home directory
            cd projects   Change to projects directory
            cd ..         Go up one directory
            cd ~/skills   Go to skills in home
          """

        _ ->
          "No manual entry for #{cmd}"
      end

    {:ok, help_text}
  end

  @doc """
  Display manual pages for commands (alias for help).
  """
  def man([], _state) do
    {:error, "man: missing operand"}
  end

  def man([cmd], state) do
    help([cmd], state)
  end

  # Terminal Control

  @doc """
  Clear the terminal screen.
  """
  def clear(_state) do
    {:ok, "\e[H\e[2J\e[3J"}
  end

  @doc """
  Display command history.
  """
  def history(state) do
    history =
      Map.get(state, :command_history, [])
      |> Enum.with_index(1)
      |> Enum.map_join("\n", fn {cmd, idx} -> "  #{idx}  #{cmd}" end)

    {:ok, history}
  end

  # Theme Management

  @doc """
  List all available themes.
  """
  def themes(_state) do
    output = """
    Available themes:

      synthwave84         Retro 80s neon aesthetic (default)
      synthwave84-soft    Lower contrast variant
      synthwave84-high    High contrast variant
      green               Classic green terminal
      amber               Vintage amber monochrome
      matrix              Green matrix rain
      phosphor            Phosphor blue CRT
      cyberpunk           Pink/cyan neon

    Usage: theme <name>
    Example: theme matrix
    """

    {:ok, String.trim(output)}
  end

  @doc """
  Change the terminal theme.
  """
  def theme([], _state) do
    {:error, "Usage: theme <name>\nRun 'themes' to see available themes"}
  end

  def theme([theme_name], state) do
    theme_key = String.downcase(theme_name)

    case Map.get(@available_themes, theme_key) do
      nil ->
        {:error, "Unknown theme: #{theme_name}\nRun 'themes' to see available themes"}

      theme_class ->
        output = "Theme changed to: #{theme_name}"
        new_state = Map.put(state, :theme_change, theme_class)
        {:ok, output, new_state}
    end
  end

  def theme(_args, _state) do
    {:error, "Usage: theme <name>\nRun 'themes' to see available themes"}
  end

  # Performance Monitoring

  @doc """
  Open performance dashboard.
  """
  def perf(_args, state) do
    new_state = Map.put(state, :section_change, :performance)
    {:ok, "Opening performance dashboard...", new_state}
  end

  def dashboard(_args, state), do: perf([], state)
  def metrics(_args, state), do: perf([], state)

  # CRT Effects

  @doc """
  Toggle CRT screen effects.
  """
  def crt([], state) do
    current_mode = Map.get(state, :crt_mode, false)
    new_mode = !current_mode
    new_state = Map.put(state, :crt_mode, new_mode)
    status = if new_mode, do: "enabled", else: "disabled"
    {:ok, "CRT effects #{status}", new_state}
  end

  def crt(["on"], state) do
    new_state = Map.put(state, :crt_mode, true)
    {:ok, "CRT effects enabled", new_state}
  end

  def crt(["off"], state) do
    new_state = Map.put(state, :crt_mode, false)
    {:ok, "CRT effects disabled", new_state}
  end

  def crt(_args, _state) do
    {:error, "Usage: crt [on|off]\nToggle retro CRT screen effects"}
  end

  # Accessibility

  @doc """
  Toggle high contrast accessibility mode.
  """
  def contrast([], state) do
    current_mode = Map.get(state, :high_contrast_mode, false)
    new_mode = !current_mode
    new_state = Map.put(state, :high_contrast_mode, new_mode)
    status = if new_mode, do: "enabled", else: "disabled"
    {:ok, "High contrast mode #{status}", new_state}
  end

  def contrast(["on"], state) do
    new_state = Map.put(state, :high_contrast_mode, true)
    {:ok, "High contrast mode enabled", new_state}
  end

  def contrast(["off"], state) do
    new_state = Map.put(state, :high_contrast_mode, false)
    {:ok, "High contrast mode disabled", new_state}
  end

  def contrast(_args, _state) do
    {:error, "Usage: contrast [on|off]\nToggle high contrast accessibility mode"}
  end

  @doc """
  Accessibility alias for contrast command.
  """
  def a11y(args, state), do: contrast(args, state)

  # Search & Navigation

  @doc """
  Search the site content.
  """
  def search(args, _state) do
    query = Enum.join(args, " ") |> String.trim()

    if query == "" do
      {:error, "search: empty query"}
    else
      {:search, query}
    end
  end

  @doc """
  Display site structure as ASCII tree.
  """
  def tree(_args, _state) do
    posts_dir = Path.join([Application.app_dir(:droodotfoo), "..", "priv", "posts"])

    posts =
      case File.ls(posts_dir) do
        {:ok, files} ->
          files
          |> Enum.filter(&String.ends_with?(&1, ".md"))
          |> Enum.map(&String.replace_suffix(&1, ".md", ""))
          |> Enum.sort()

        {:error, _} ->
          ["welcome-to-droo-foo", "building-with-raxol", "test-api-post"]
      end

    tree_output = build_site_tree(posts)

    {:ok, tree_output}
  end

  # Helper Functions

  @doc false
  defp build_site_tree(posts) do
    posts_tree =
      posts
      |> Enum.with_index()
      |> Enum.map_join("\n", fn {post, index} ->
        is_last = index == length(posts) - 1
        connector = if is_last, do: "└", else: "├"
        "    #{connector}─ #{post}.md"
      end)

    """
    ┌─ droo.foo
    │
    ├─ posts/
    #{posts_tree}
    │
    ├─ terminal/
    │  ├─ about
    │  ├─ projects
    │  ├─ contact
    │  ├─ stl viewer
    │  └─ web3
    │
    ├─ features/
    │  ├─ spotify integration
    │  ├─ github integration
    │  ├─ web3 wallet
    │  ├─ fileverse (encrypted docs)
    │  └─ games (tetris, snake, etc.)
    │
    └─ api/
        ├─ /posts (obsidian publishing)
        └─ /auth/spotify (oauth)
    """
  end
end
