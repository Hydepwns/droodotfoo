defmodule Droodotfoo.Terminal.Commands do
  @moduledoc """
  Implementation of all terminal commands.
  Each command returns {:ok, output} or {:error, message}.
  """

  alias Droodotfoo.Terminal.FileSystem
  alias Droodotfoo.Github.Client, as: GithubClient

  # Navigation Commands

  def ls(args, state) do
    {opts, paths} = parse_ls_args(args)

    paths = if paths == [], do: ["."], else: paths

    output =
      Enum.map(paths, fn path ->
        case FileSystem.list_directory(path, state) do
          {:ok, contents} ->
            format_ls_output(contents, opts, path, state)

          {:error, msg} ->
            "ls: #{msg}"
        end
      end)
      |> Enum.join("\n")

    {:ok, output}
  end

  def cd([], state) do
    # cd with no args goes home
    new_state = %{state | current_dir: state.home_dir}
    # Empty output but new state
    {:ok, "", new_state}
  end

  def cd([path], state) do
    case FileSystem.change_directory(path, state) do
      {:ok, new_state} -> {:ok, "", new_state}
      {:error, msg} -> {:error, "cd: #{msg}"}
    end
  end

  def cd(_args, _state) do
    {:error, "cd: too many arguments"}
  end

  def pwd(state) do
    {:ok, state.current_dir}
  end

  # File Operations

  def find(args, state) do
    # Simple find implementation
    {opts, paths} = parse_find_args(args)
    name_pattern = opts[:name] || "*"
    search_path = List.first(paths) || "."

    # For simplicity, just list matching files
    case FileSystem.list_directory(search_path, state) do
      {:ok, contents} ->
        matching =
          Enum.filter(contents, fn file ->
            match_pattern?(file, name_pattern)
          end)

        {:ok, Enum.join(matching, "\n")}

      {:error, msg} ->
        {:error, "find: #{msg}"}
    end
  end

  defp parse_find_args(args) do
    {opts, paths} = Enum.split_while(args, &String.starts_with?(&1, "-"))

    opts_map =
      opts
      |> Enum.chunk_every(2)
      |> Enum.reduce(%{}, fn
        ["-name", pattern], acc -> Map.put(acc, :name, pattern)
        _, acc -> acc
      end)

    {opts_map, paths}
  end

  defp match_pattern?(_file, "*"), do: true

  defp match_pattern?(file, pattern) do
    pattern
    |> String.replace("*", ".*")
    |> Regex.compile!()
    |> Regex.match?(file)
  end

  def cat([], _state) do
    {:error, "cat: missing operand"}
  end

  def cat(files, state) do
    output =
      Enum.map(files, fn file ->
        case FileSystem.read_file(file, state) do
          {:ok, content} -> content
          {:error, msg} -> "cat: #{msg}"
        end
      end)
      |> Enum.join("\n")

    {:ok, output}
  end

  def head(args, state) do
    {n, files} = parse_head_tail_args(args, 10)

    files = if files == [], do: ["README.md"], else: files

    output =
      Enum.map(files, fn file ->
        case FileSystem.read_file(file, state) do
          {:ok, content} ->
            lines =
              String.split(content, "\n")
              |> Enum.take(n)
              |> Enum.join("\n")

            if length(files) > 1 do
              "==> #{file} <==\n#{lines}"
            else
              lines
            end

          {:error, msg} ->
            "head: #{msg}"
        end
      end)
      |> Enum.join("\n\n")

    {:ok, output}
  end

  def tail(args, state) do
    {n, files} = parse_head_tail_args(args, 10)

    files = if files == [], do: ["README.md"], else: files

    output =
      Enum.map(files, fn file ->
        case FileSystem.read_file(file, state) do
          {:ok, content} ->
            lines =
              String.split(content, "\n")
              |> Enum.take(-n)
              |> Enum.join("\n")

            if length(files) > 1 do
              "==> #{file} <==\n#{lines}"
            else
              lines
            end

          {:error, msg} ->
            "tail: #{msg}"
        end
      end)
      |> Enum.join("\n\n")

    {:ok, output}
  end

  def grep([], _state) do
    {:error, "grep: missing pattern"}
  end

  def grep([_pattern], _state) do
    {:error, "grep: missing file operand"}
  end

  def grep([pattern | files], state) do
    output =
      Enum.map(files, fn file ->
        case FileSystem.read_file(file, state) do
          {:ok, content} ->
            matching_lines =
              String.split(content, "\n")
              |> Enum.with_index(1)
              |> Enum.filter(fn {line, _} -> String.contains?(line, pattern) end)
              |> Enum.map(fn {line, num} ->
                if length(files) > 1 do
                  "#{file}:#{num}:#{line}"
                else
                  "#{num}:#{line}"
                end
              end)
              |> Enum.join("\n")

            if matching_lines == "" do
              nil
            else
              matching_lines
            end

          {:error, msg} ->
            "grep: #{msg}"
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n")

    {:ok, output}
  end

  # System Info

  def whoami(_state) do
    {:ok, "drew"}
  end

  def date(_state) do
    {:ok, DateTime.utc_now() |> DateTime.to_string()}
  end

  def uptime(_state) do
    # Calculate uptime from state.start_time if available
    {:ok, "up 42 days, 3:14, 1 user, load average: 0.15, 0.12, 0.10"}
  end

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

  # Help & Documentation

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

  def man([], _state) do
    {:error, "man: missing operand"}
  end

  def man([cmd], state) do
    help([cmd], state)
  end

  # Utility Commands

  def clear(_state) do
    # Send ANSI clear screen
    {:ok, "\e[H\e[2J\e[3J"}
  end

  def echo(args, _state) do
    {:ok, Enum.join(args, " ")}
  end

  def history(state) do
    history =
      Map.get(state, :command_history, [])
      |> Enum.with_index(1)
      |> Enum.map(fn {cmd, idx} -> "  #{idx}  #{cmd}" end)
      |> Enum.join("\n")

    {:ok, history}
  end

  # Fun Commands

  def fortune(_state) do
    fortunes = [
      "The only way to do great work is to love what you do. - Steve Jobs",
      "Code is like humor. When you have to explain it, it's bad. - Cory House",
      "First, solve the problem. Then, write the code. - John Johnson",
      "Experience is the name everyone gives to their mistakes. - Oscar Wilde",
      "The best way to predict the future is to invent it. - Alan Kay",
      "Simplicity is the soul of efficiency. - Austin Freeman",
      "Make it work, make it right, make it fast. - Kent Beck"
    ]

    {:ok, Enum.random(fortunes)}
  end

  def cowsay([], _state) do
    cowsay(["moo!"], nil)
  end

  def cowsay(words, _state) do
    text = Enum.join(words, " ")
    width = String.length(text) + 2

    cow = """
     #{"_" |> String.duplicate(width)}
    < #{text} >
     #{"-" |> String.duplicate(width)}
            \\   ^__^
             \\  (oo)\\_______
                (__)\\       )\\/\\
                    ||----w |
                    ||     ||
    """

    {:ok, cow}
  end

  def sl(_state) do
    # ASCII steam locomotive animation
    train = """
                        (@@) (  ) (@)  ( )  @@    ()    @     O     @
                   (   )
               (@@@@)
            (    )

          (@@@)
        ====        ________                ___________
    _D _|  |_______/        \\__I_I_____===__|_________|
     |(_)---  |   H\\________/ |   |        =|___ ___|
     /     |  |   H  |  |     |   |         ||_| |_||
    |      |  |   H  |__--------------------| [___] |
    | ________|___H__/__|_____/[][]~\\_______|       |
    |/ |   |-----------I_____I [][] []  D   |=======|__
    """

    {:ok, train}
  end

  # droo.foo Specific Commands

  def projects([], _state) do
    # Fetch pinned repos from GitHub (hydepwns profile)
    result =
      case GithubClient.fetch_pinned_repos("hydepwns") do
        {:ok, repos} -> GithubClient.format_repos(repos)
        {:error, _reason} = error -> GithubClient.format_repos(error)
      end

    {:ok, result}
  end

  def skills([], _state) do
    {:ok,
     """
     Technical Skills
     ================

     Languages:
       Expert: Elixir, JavaScript, Python, Rust
       Proficient: Go, Ruby, Java, C++

     Frameworks:
       Backend: Phoenix, Node.js, FastAPI, Actix
       Frontend: React, Vue, Svelte, LiveView

     Databases:
       SQL: PostgreSQL, MySQL, SQLite
       NoSQL: Redis, MongoDB, Cassandra

     Tools & Platforms:
       Cloud: AWS, GCP, Azure
       DevOps: Docker, Kubernetes, Terraform
       CI/CD: GitHub Actions, GitLab CI, Jenkins

     Type 'cat skills/<category>.txt' for detailed info.
     """}
  end

  def resume([], state) do
    cat(["resume.txt"], state)
  end

  def contact([], _state) do
    {:ok,
     """
     Contact Information
     ===================

     Email:    drew@axol.io
     GitHub:   https://github.com/hydepwns
     LinkedIn: https://linkedin.com/in/drew-hiro
     Twitter:  @MF_DROO

     Feel free to reach out for:
     - Job opportunities
     - Open source collaboration
     - Technical discussions
     - Coffee chat

     PGP Key available at: https://droo.foo/pgp
     """}
  end

  def download(["resume.pdf"], _state) do
    {:ok,
     """
     Downloading resume.pdf...

     [============================] 100%

     Downloaded: resume.pdf (142 KB)

     Note: In a real terminal, this would trigger a file download.
     Visit https://droo.foo/resume.pdf to download.
     """}
  end

  def download([], state) do
    download(["resume.pdf"], state)
  end

  # Git commands (simulated)

  def git(["status"], _state) do
    {:ok,
     """
     On branch main
     Your branch is up to date with 'origin/main'.

     nothing to commit, working tree clean
     """}
  end

  def git(["log"], _state) do
    {:ok,
     """
     commit 5a7f9d2 (HEAD -> main, origin/main)
     Author: Drew Hiro <drew@axol.io>
     Date:   #{Date.utc_today()}

         Add interactive terminal commands

     commit 3c2e1a4
     Author: Drew Hiro <drew@axol.io>
     Date:   #{Date.utc_today() |> Date.add(-1)}

         Implement performance optimizations
     """}
  end

  def git(args, _state) do
    {:ok, "git: '#{Enum.join(args, " ")}' is not a git command"}
  end

  # Package managers

  def npm(args, _state) do
    case args do
      ["install"] ->
        {:ok, "npm install\n└── droo.foo@1.0.0\n\nAll dependencies installed successfully!"}

      ["start"] ->
        {:ok, "Starting development server...\nServer running at http://localhost:4000"}

      ["test"] ->
        {:ok, "Running test suite...\n\n✓ All tests passed!"}

      ["version"] ->
        {:ok, "8.19.2"}

      [] ->
        {:ok, "npm <command>\n\nCommands: install, start, test, build, version"}

      _ ->
        {:error, "npm: Unknown command"}
    end
  end

  def pip(args, _state) do
    case args do
      ["install" | _] ->
        {:ok, "Successfully installed packages"}

      ["list"] ->
        {:ok,
         "Package         Version\n----------      -------\nelixir-bridge   1.0.0\nphoenix-utils   2.1.0"}

      ["--version"] ->
        {:ok, "pip 23.0.1"}

      [] ->
        {:ok, "pip <command> [options]"}

      _ ->
        {:error, "pip: Unknown command"}
    end
  end

  # Network commands

  def wget(args, _state) do
    case args do
      [url] ->
        {:ok,
         "--#{DateTime.utc_now()}--  #{url}\nConnecting... connected.\nHTTP request sent, awaiting response... 200 OK\nLength: 1337 (1.3K)\nSaving to: 'index.html'\n\n100%[==================>] 1,337       --.-K/s    in 0s"}

      [] ->
        {:error, "wget: missing URL"}

      _ ->
        {:ok, "wget: downloading #{Enum.join(args, " ")}"}
    end
  end

  def ping(args, _state) do
    host = List.first(args) || "localhost"

    {:ok,
     """
     PING #{host}: 56 data bytes
     64 bytes from #{host}: icmp_seq=0 ttl=64 time=0.123 ms
     64 bytes from #{host}: icmp_seq=1 ttl=64 time=0.145 ms
     64 bytes from #{host}: icmp_seq=2 ttl=64 time=0.131 ms

     --- #{host} ping statistics ---
     3 packets transmitted, 3 packets received, 0.0% packet loss
     round-trip min/avg/max/stddev = 0.123/0.133/0.145/0.011 ms
     """}
  end

  # File management

  def rm(args, _state) do
    case args do
      ["-rf", "/"] -> {:error, "rm: permission denied (nice try!)"}
      [] -> {:error, "rm: missing operand"}
      files -> {:ok, "rm: removed #{Enum.join(files, ", ")}"}
    end
  end

  # Easter eggs

  def sudo(["rm", "-rf", "/"], _state) do
    {:error,
     """
     Nice try! 😄

     This is a simulated terminal. No actual files were harmed.
     But I appreciate your commitment to chaos!
     """}
  end

  def sudo(_args, _state) do
    {:ok, "[sudo] password for drew: \n(Just kidding, running without sudo)"}
  end

  def vim([], _state) do
    {:ok,
     """
     VIM - Vi IMproved

     ~
     ~
     ~
     ~  You are now trapped in vim.
     ~
     ~  Quick, press :q! to escape!
     ~  (Just kidding, type 'exit' to leave)
     ~
     ~
     """}
  end

  def emacs([], _state) do
    {:ok, "emacs: Real programmers use vim. (Just kidding, use what you like!)"}
  end

  def exit(_state) do
    {:exit, "Goodbye! Thanks for visiting droo.foo"}
  end

  # Plugin commands

  def plugins([], _state) do
    case Droodotfoo.PluginSystem.Manager.list_plugins() do
      [] ->
        {:ok, "No plugins available"}

      plugins ->
        output =
          [
            "Available Plugins:",
            ""
          ] ++
            Enum.map(plugins, fn plugin ->
              "  #{plugin.name} (v#{plugin.version}) - #{plugin.description}"
            end)

        {:ok, Enum.join(output, "\n")}
    end
  end

  def plugins(["list"], state), do: plugins([], state)

  def plugins(args, _state) do
    {:error, "Unknown plugins command: #{Enum.join(args, " ")}"}
  end

  def snake([], state) do
    case Droodotfoo.PluginSystem.Manager.start_plugin("snake", state) do
      {:ok, output} -> {:plugin, "snake", output}
      {:error, reason} -> {:error, reason}
    end
  end

  def calc([], state) do
    case Droodotfoo.PluginSystem.Manager.start_plugin("calc", state) do
      {:ok, output} -> {:plugin, "calc", output}
      {:error, reason} -> {:error, reason}
    end
  end

  def calculator(args, state), do: calc(args, state)

  def matrix([], state) do
    case Droodotfoo.PluginSystem.Manager.start_plugin("matrix", state) do
      {:ok, output} -> {:plugin, "matrix", output}
      {:error, reason} -> {:error, reason}
    end
  end

  def rain(args, state), do: matrix(args, state)

  # Plugin launch commands (consolidated pattern)
  def spotify([], state), do: launch_plugin("spotify", state)
  def music(args, state), do: spotify(args, state)

  def github([], state), do: launch_plugin("github", state)
  def gh(args, state), do: github(args, state)

  # Project commands
  def project([], state) do
    # Go to projects section
    {:ok, "Navigating to projects...", %{state | current_section: :projects}}
  end

  def project([project_name], state) do
    # Find project by name
    projects = Droodotfoo.Projects.all()

    matching_project =
      Enum.find_index(projects, fn p ->
        String.downcase(p.name) =~ String.downcase(project_name) or
          Atom.to_string(p.id) == String.downcase(project_name)
      end)

    case matching_project do
      nil ->
        {:error, "Project not found: #{project_name}"}

      idx ->
        {:ok, "Opening project: #{Enum.at(projects, idx).name}",
         %{state | current_section: :projects, selected_project_index: idx, project_detail_view: true}}
    end
  end

  def projects(_state) do
    # List all projects
    projects = Droodotfoo.Projects.all()

    output =
      projects
      |> Enum.with_index()
      |> Enum.map(fn {p, idx} ->
        status = case p.status do
          :active -> "[ACTIVE]"
          :completed -> "[COMPLETED]"
          :archived -> "[ARCHIVED]"
        end
        "#{idx + 1}. #{p.name} #{status}\n   #{p.tagline}"
      end)
      |> Enum.join("\n\n")

    {:ok, "Portfolio Projects:\n\n#{output}\n\nUse 'project <name>' to view details"}
  end

  def charts(_state) do
    # Display ASCII chart showcase
    output = Droodotfoo.AsciiChart.showcase()
    |> Enum.join("\n")

    {:ok, output}
  end

  def conway([], state), do: launch_plugin("conway", state)
  def life(args, state), do: conway(args, state)

  def tetris([], state), do: launch_plugin("tetris", state)
  def t(args, state), do: tetris(args, state)

  def twenty48([], state), do: launch_plugin("2048", state)
  def game48(args, state), do: twenty48(args, state)

  def wordle([], state), do: launch_plugin("wordle", state)
  def word(args, state), do: wordle(args, state)

  def typing([], state), do: launch_plugin("typing_test", state)
  def type(args, state), do: typing(args, state)
  def wpm(args, state), do: typing(args, state)

  # API commands

  def api(["status"], _state) do
    {:ok,
     """
     API Status: Online

     Endpoints:
       GET  /api/projects     - List all projects
       GET  /api/skills       - Get skills data
       GET  /api/resume       - Resume in JSON format
       POST /api/contact      - Send a message
       GET  /api/stats        - Visitor statistics

     Base URL: https://droo.foo/api
     Docs: https://droo.foo/api/docs
     """}
  end

  def curl(["https://droo.foo/api/status"], _state) do
    {:ok,
     """
     HTTP/1.1 200 OK
     Content-Type: application/json

     {
       "status": "online",
       "uptime": "42 days",
       "version": "1.0.0",
       "visitors_today": 1337
     }
     """}
  end

  def curl(args, _state) do
    {:ok, "curl: #{Enum.join(args, " ")}: Could not resolve host"}
  end

  # Search command
  def search(args, _state) do
    query = Enum.join(args, " ") |> String.trim()

    if query == "" do
      {:error, "search: empty query"}
    else
      # Return special search tuple with query and mode flags
      # This will be handled in Command.execute_terminal_command
      {:search, query}
    end
  end

  # Helper functions

  # Plugin launch helper (consolidates repetitive pattern)
  defp launch_plugin(plugin_name, state) do
    case Droodotfoo.PluginSystem.Manager.start_plugin(plugin_name, state) do
      {:ok, output} -> {:plugin, plugin_name, output}
      {:error, reason} -> {:error, reason}
    end
  end

  defp parse_ls_args(args) do
    {opts, paths} = Enum.split_while(args, &String.starts_with?(&1, "-"))

    opts =
      opts
      |> Enum.join()
      |> String.graphemes()
      |> Enum.filter(&(&1 != "-"))
      |> MapSet.new()

    {opts, paths}
  end

  defp format_ls_output(contents, opts, path, state) do
    show_hidden = MapSet.member?(opts, "a")
    long_format = MapSet.member?(opts, "l")

    filtered_contents =
      if show_hidden do
        contents
      else
        Enum.reject(contents, &String.starts_with?(&1, "."))
      end

    if long_format do
      # Long format with permissions, size, etc.
      Enum.map(filtered_contents, fn name ->
        file_path = FileSystem.normalize_path(Path.join(path, name), state.current_dir)

        case FileSystem.get_file(file_path, state) do
          %{permissions: perms, owner: owner, size: size} ->
            "#{perms}  #{owner}  #{format_size(size)}  #{name}"

          _ ->
            name
        end
      end)
      |> Enum.join("\n")
    else
      # Simple format
      Enum.join(filtered_contents, "  ")
    end
  end

  defp format_size(bytes) when bytes < 1024, do: "#{bytes}B"
  defp format_size(bytes) when bytes < 1024 * 1024, do: "#{div(bytes, 1024)}K"
  defp format_size(bytes), do: "#{div(bytes, 1024 * 1024)}M"

  defp parse_head_tail_args(args, default_n) do
    case args do
      ["-n", n_str | rest] ->
        case Integer.parse(n_str) do
          {n, _} -> {n, rest}
          _ -> {default_n, args}
        end

      args ->
        {default_n, args}
    end
  end

  # Theme Commands

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

  def theme([], _state) do
    {:error, "Usage: theme <name>\nRun 'themes' to see available themes"}
  end

  def theme([theme_name], state) do
    theme_key = String.downcase(theme_name)

    case Map.get(@available_themes, theme_key) do
      nil ->
        {:error, "Unknown theme: #{theme_name}\nRun 'themes' to see available themes"}

      theme_class ->
        # Return a special tuple that LiveView can intercept
        output = "Theme changed to: #{theme_name}"
        new_state = Map.put(state, :theme_change, theme_class)
        {:ok, output, new_state}
    end
  end

  def theme(_args, _state) do
    {:error, "Usage: theme <name>\nRun 'themes' to see available themes"}
  end

  # Performance & Monitoring Commands

  def perf(_args, state) do
    # Switch to performance dashboard view
    new_state = Map.put(state, :section_change, :performance)
    {:ok, "Opening performance dashboard...", new_state}
  end

  def dashboard(_args, state), do: perf([], state)
  def metrics(_args, state), do: perf([], state)

  # CRT Effects Command

  def crt([], state) do
    # Toggle CRT mode
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

  # High Contrast Mode Command

  def contrast([], state) do
    # Toggle high contrast mode
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

  # Accessibility alias
  def a11y(args, state), do: contrast(args, state)
end
