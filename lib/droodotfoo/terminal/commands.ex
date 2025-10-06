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

  # Web3 commands
  def web3([], state) do
    # Navigate to web3 section
    {:ok, "Opening Web3 wallet interface...", %{state | section_change: :web3}}
  end

  def web3(["connect" | _], state) do
    # Set connecting flag and navigate to web3 section
    # The LiveView will pick up the web3_action and trigger MetaMask
    {:ok, "Initiating wallet connection...",
     %{state | section_change: :web3, web3_action: :connect}}
  end

  def web3(["disconnect" | _], state) do
    # Set disconnect action
    {:ok, "Disconnecting wallet...", %{state | web3_action: :disconnect}}
  end

  def web3([subcommand | _], _state) do
    {:error, "Unknown web3 subcommand: #{subcommand}\n\nUsage:\n  web3         - Open Web3 interface\n  web3 connect - Connect wallet\n  web3 disconnect - Disconnect wallet"}
  end

  def wallet(args, state), do: web3(["connect" | args], state)
  def w3(args, state), do: web3(args, state)

  # ENS resolution command
  def ens([], _state) do
    {:error, "Usage: ens <name.eth> - Resolve ENS name to address"}
  end

  def ens([name | _], _state) do
    if String.ends_with?(name, ".eth") do
      case Droodotfoo.Web3.Manager.lookup_ens(name) do
        {:ok, address} ->
          output = """
          ENS Resolution:
            Name:    #{name}
            Address: #{address}
          """

          {:ok, String.trim(output)}

        {:error, :invalid_ens_name} ->
          {:error, "Invalid ENS name: #{name}"}

        {:error, :ens_only_on_mainnet} ->
          {:error, "ENS is only available on Ethereum mainnet"}

        {:error, :not_found} ->
          {:error, "ENS name not found: #{name}"}

        {:error, reason} ->
          {:error, "Failed to resolve ENS: #{reason}"}
      end
    else
      {:error, "ENS names must end with .eth (e.g., vitalik.eth)"}
    end
  end

  # NFT commands
  def nft([], _state) do
    {:error, "Usage:\n  nft list [address]     - List NFTs for an address\n  nft view <contract> <id> - View NFT details"}
  end

  def nft(["list"], state) do
    # List NFTs for connected wallet
    case Map.get(state, :web3_wallet_address) do
      nil ->
        {:error, "No wallet connected. Use 'web3 connect' first."}

      address ->
        nft(["list", address], state)
    end
  end

  def nft(["list", address], _state) do
    case Droodotfoo.Web3.NFT.fetch_nfts(address, limit: 10) do
      {:ok, []} ->
        {:ok, "No NFTs found for address: #{address}"}

      {:ok, nfts} ->
        output =
          nfts
          |> Enum.with_index(1)
          |> Enum.map(fn {nft, idx} ->
            "#{idx}. #{nft.name}\n   Collection: #{nft.collection_name}\n   Token ID: #{nft.token_id}\n   Standard: #{nft.token_standard}"
          end)
          |> Enum.join("\n\n")

        header = "NFTs owned by #{address}:\n\n"
        {:ok, header <> output}

      {:error, :invalid_address} ->
        {:error, "Invalid Ethereum address"}

      {:error, _reason} ->
        {:error, "Failed to fetch NFTs. Check network connection."}
    end
  end

  def nft(["view", contract_address, token_id], _state) do
    case Droodotfoo.Web3.NFT.fetch_nft(contract_address, token_id) do
      {:ok, nft} ->
        {:ok, ascii_art} = Droodotfoo.Web3.NFT.image_to_ascii(nft.image_url)

        properties_text =
          if is_list(nft.properties) and length(nft.properties) > 0 do
            props =
              nft.properties
              |> Enum.take(5)
              |> Enum.map(fn prop ->
                trait_type = Map.get(prop, "trait_type", "Unknown")
                value = Map.get(prop, "value", "Unknown")
                "  - #{trait_type}: #{value}"
              end)
              |> Enum.join("\n")

            "\n\nProperties:\n" <> props
          else
            ""
          end

        output = """
        #{ascii_art}

        Name: #{nft.name}
        Collection: #{nft.collection_name}
        Token ID: #{nft.token_id}
        Standard: #{nft.token_standard}
        Contract: #{nft.contract_address}

        Description:
        #{String.slice(nft.description, 0..200)}#{if String.length(nft.description) > 200, do: "...", else: ""}#{properties_text}
        """

        {:ok, String.trim(output)}

      {:error, :invalid_contract_address} ->
        {:error, "Invalid contract address"}

      {:error, _reason} ->
        {:error, "Failed to fetch NFT. Check contract address and token ID."}
    end
  end

  def nft([subcommand | _], _state) do
    {:error, "Unknown nft subcommand: #{subcommand}"}
  end

  # Alias for nft list
  def nfts([], state), do: nft(["list"], state)
  def nfts([address], state), do: nft(["list", address], state)

  # Token balance commands
  def tokens([], state) do
    # List tokens for connected wallet
    case Map.get(state, :web3_wallet_address) do
      nil ->
        {:error, "No wallet connected. Use 'web3 connect' first."}

      address ->
        tokens(["list", address], state)
    end
  end

  def tokens(["list"], state) do
    case Map.get(state, :web3_wallet_address) do
      nil ->
        {:error, "No wallet connected. Use 'web3 connect' first."}

      address ->
        tokens(["list", address], state)
    end
  end

  def tokens(["list", address], _state) do
    case Droodotfoo.Web3.Token.fetch_balances(address) do
      {:ok, []} ->
        {:ok, "No token balances found for address: #{address}"}

      {:ok, balances} ->
        # Filter out zero balances
        non_zero = Enum.filter(balances, fn t -> t.balance_formatted > 0 end)

        if Enum.empty?(non_zero) do
          {:ok, "No token balances found (all balances are zero)"}
        else
          header = "Token Balances for #{String.slice(address, 0..9)}...#{String.slice(address, -4..-1)}\n\n"

          rows =
            non_zero
            |> Enum.map(fn token ->
              balance_str = :erlang.float_to_binary(token.balance_formatted, decimals: 4)

              price_str =
                if token.usd_price do
                  "$#{:erlang.float_to_binary(token.usd_price, decimals: 2)}"
                else
                  "N/A"
                end

              value_str =
                if token.usd_value do
                  "$#{:erlang.float_to_binary(token.usd_value, decimals: 2)}"
                else
                  "N/A"
                end

              change_str =
                if token.price_change_24h do
                  change = :erlang.float_to_binary(token.price_change_24h, decimals: 2)

                  if token.price_change_24h >= 0 do
                    "+#{change}%"
                  else
                    "#{change}%"
                  end
                else
                  "N/A"
                end

              "#{String.pad_trailing(token.symbol, 6)} #{String.pad_leading(balance_str, 12)} @ #{String.pad_leading(price_str, 10)} = #{String.pad_leading(value_str, 12)}  (#{change_str})"
            end)
            |> Enum.join("\n")

          {:ok, header <> rows}
        end

      {:error, :invalid_address} ->
        {:error, "Invalid Ethereum address"}

      {:error, _reason} ->
        {:error, "Failed to fetch token balances. Check network connection."}
    end
  end

  def tokens([subcommand | _], _state) do
    {:error, "Unknown tokens subcommand: #{subcommand}\n\nUsage:\n  tokens          - List token balances\n  tokens list     - List token balances\n  balance <symbol> - Get price for a specific token"}
  end

  # Balance command for specific token price
  def balance([], _state) do
    {:error, "Usage: balance <symbol> - Get USD price and chart for a token (e.g., balance ETH)"}
  end

  def balance([symbol | _], _state) do
    symbol_upper = String.upcase(symbol)

    with {:ok, price_data} <- Droodotfoo.Web3.Token.get_token_price(symbol_upper),
         {:ok, history} <- Droodotfoo.Web3.Token.get_price_history(symbol_upper, 7) do
      chart = Droodotfoo.Web3.Token.price_chart(history)

      change_str =
        if price_data.usd_24h_change >= 0 do
          "+#{:erlang.float_to_binary(price_data.usd_24h_change, decimals: 2)}%"
        else
          "#{:erlang.float_to_binary(price_data.usd_24h_change, decimals: 2)}%"
        end

      output = """
      #{symbol_upper} Price Information

      Current Price: $#{:erlang.float_to_binary(price_data.usd, decimals: 2)}
      24h Change:    #{change_str}

      7-Day Price Chart:
      #{chart}
      """

      {:ok, String.trim(output)}
    else
      {:error, :token_not_found} ->
        {:error, "Token not found: #{symbol}. Supported tokens: ETH, USDT, USDC, DAI, WBTC, LINK, MATIC, UNI, AAVE"}

      {:error, :rate_limit} ->
        {:error, "CoinGecko API rate limit reached. Please try again later."}

      {:error, _reason} ->
        {:error, "Failed to fetch price for #{symbol}. Check network connection."}
    end
  end

  # Alias for tokens list
  def crypto(args, state), do: tokens(args, state)

  # Transaction history commands
  def tx([], state) do
    # Show transaction history for connected wallet
    case Map.get(state, :web3_wallet_address) do
      nil ->
        {:error, "No wallet connected. Use 'web3 connect' first."}

      address ->
        tx(["history", address], state)
    end
  end

  def tx(["history"], state) do
    case Map.get(state, :web3_wallet_address) do
      nil ->
        {:error, "No wallet connected. Use 'web3 connect' first."}

      address ->
        tx(["history", address], state)
    end
  end

  def tx(["history", address], _state) do
    case Droodotfoo.Web3.Transaction.fetch_history(address, limit: 10) do
      {:ok, []} ->
        {:ok, "No transactions found for address: #{address}"}

      {:ok, transactions} ->
        header = """
        Transaction History for #{Droodotfoo.Web3.Transaction.shorten(address)}

        """

        # ASCII table with transaction data
        rows =
          transactions
          |> Enum.with_index(1)
          |> Enum.map(fn {tx, idx} ->
            tx_hash = Droodotfoo.Web3.Transaction.shorten(tx.hash)
            from = Droodotfoo.Web3.Transaction.shorten(tx.from)
            to = Droodotfoo.Web3.Transaction.shorten(tx.to)
            value = :erlang.float_to_binary(tx.value_eth, decimals: 4)
            gas = :erlang.float_to_binary(tx.gas_cost_eth, decimals: 6)

            time_ago =
              case DateTime.from_unix(tx.timestamp) do
                {:ok, dt} ->
                  diff = DateTime.diff(DateTime.utc_now(), dt)
                  cond do
                    diff < 60 -> "#{diff}s ago"
                    diff < 3600 -> "#{div(diff, 60)}m ago"
                    diff < 86400 -> "#{div(diff, 3600)}h ago"
                    true -> "#{div(diff, 86400)}d ago"
                  end

                _ ->
                  "Unknown"
              end

            status = if tx.status == "1", do: "OK", else: "FAIL"

            "#{String.pad_leading(Integer.to_string(idx), 2)}. #{tx_hash} #{String.pad_trailing(from, 14)} -> #{String.pad_trailing(to, 14)} #{String.pad_leading(value, 10)} ETH  Gas: #{String.pad_leading(gas, 8)} ETH  #{String.pad_trailing(time_ago, 8)} [#{status}]"
          end)
          |> Enum.join("\n")

        {:ok, header <> rows}

      {:error, :invalid_address} ->
        {:error, "Invalid Ethereum address"}

      {:error, _reason} ->
        {:error, "Failed to fetch transaction history"}
    end
  end

  def tx([tx_hash], _state) when byte_size(tx_hash) > 60 do
    # View transaction details by hash
    case Droodotfoo.Web3.Transaction.fetch_transaction(tx_hash) do
      {:ok, tx} ->
        time = Droodotfoo.Web3.Transaction.format_timestamp(tx.timestamp)
        value = :erlang.float_to_binary(tx.value_eth, decimals: 6)
        gas_price_gwei = String.to_integer(tx.gas_price) / 1_000_000_000
        gas_cost = :erlang.float_to_binary(tx.gas_cost_eth, decimals: 6)
        status = if tx.status == "1", do: "Success", else: "Failed"

        output = """
        Transaction Details

        Hash:        #{tx.hash}
        Status:      #{status}
        Block:       #{tx.block_number}
        Timestamp:   #{time}

        From:        #{tx.from}
        To:          #{tx.to}
        Value:       #{value} ETH

        Gas Used:    #{tx.gas_used}
        Gas Price:   #{:erlang.float_to_binary(gas_price_gwei, decimals: 2)} Gwei
        Gas Cost:    #{gas_cost} ETH

        Method:      #{if tx.method == "", do: "Transfer", else: tx.method}
        """

        {:ok, String.trim(output)}

      {:error, :invalid_tx_hash} ->
        {:error, "Invalid transaction hash"}

      {:error, _reason} ->
        {:error, "Failed to fetch transaction details"}
    end
  end

  def tx([subcommand | _], _state) do
    {:error, "Unknown tx subcommand: #{subcommand}\n\nUsage:\n  tx                   - Show transaction history\n  tx history [address] - Show transaction history\n  tx <hash>            - View transaction details"}
  end

  # Alias for tx history
  def transactions(args, state), do: tx(["history" | args], state)

  # Contract commands
  def contract([], _state) do
    {:error, "Usage:\n  contract <address>         - View contract info and ABI\n  contract <address> <function> [args...] - Call read-only function"}
  end

  def contract([address], _state) do
    case Droodotfoo.Web3.Contract.fetch_contract(address) do
      {:ok, contract_info} ->
        # Parse ABI
        case Droodotfoo.Web3.Contract.parse_abi(contract_info.abi) do
          {:ok, %{functions: functions, events: events}} ->
            # Display contract info
            output = """
            Contract Information
            #{String.duplicate("=", 78)}

            Address:     #{contract_info.address}
            Name:        #{contract_info.name}
            Verified:    #{if contract_info.verified, do: "YES", else: "NO"}
            Compiler:    #{contract_info.compiler_version}
            License:     #{contract_info.license_type}
            Proxy:       #{if contract_info.proxy, do: "YES", else: "NO"}

            #{String.duplicate("-", 78)}
            VIEW FUNCTIONS (Read-only)
            #{String.duplicate("-", 78)}

            #{format_functions_list(functions, :view)}

            #{String.duplicate("-", 78)}
            WRITE FUNCTIONS (State-changing)
            #{String.duplicate("-", 78)}

            #{format_functions_list(functions, :write)}

            #{String.duplicate("-", 78)}
            EVENTS
            #{String.duplicate("-", 78)}

            #{format_events_list(events)}

            Usage: contract #{Droodotfoo.Web3.Transaction.shorten(address)} <function> [args...]
            """

            {:ok, output}

          {:error, reason} ->
            {:error, "Failed to parse ABI: #{reason}"}
        end

      {:error, :invalid_address} ->
        {:error, "Invalid contract address"}

      {:error, reason} ->
        {:error, "Failed to fetch contract: #{reason}"}
    end
  end

  def contract([address, function_name | args], _state) do
    # Call read-only contract function
    case Droodotfoo.Web3.Contract.call_function(address, function_name, args) do
      {:ok, result} ->
        output = """
        Contract Call Result
        #{String.duplicate("=", 78)}

        Contract:  #{Droodotfoo.Web3.Transaction.shorten(address)}
        Function:  #{function_name}
        Arguments: #{if Enum.empty?(args), do: "(none)", else: inspect(args)}

        Result:    #{inspect(result)}
        """

        {:ok, output}

      {:error, :invalid_address} ->
        {:error, "Invalid contract address"}

      {:error, reason} ->
        {:error, "Function call failed: #{reason}"}
    end
  end

  defp format_functions_list(functions, type) do
    filtered =
      case type do
        :view ->
          Enum.filter(functions, fn f ->
            f.state_mutability in ["view", "pure"]
          end)

        :write ->
          Enum.filter(functions, fn f ->
            f.state_mutability not in ["view", "pure"]
          end)
      end

    if Enum.empty?(filtered) do
      "  (none)"
    else
      filtered
      |> Enum.map(fn func ->
        "  #{Droodotfoo.Web3.Contract.format_function_signature(func)}"
      end)
      |> Enum.join("\n")
    end
  end

  defp format_events_list(events) do
    if Enum.empty?(events) do
      "  (none)"
    else
      events
      |> Enum.map(fn event ->
        "  #{Droodotfoo.Web3.Contract.format_event_signature(event)}"
      end)
      |> Enum.join("\n")
    end
  end

  # call command - shorthand for contract function calls
  def call([address, function_name | args], state) do
    contract([address, function_name | args], state)
  end

  def call(_args, _state) do
    {:error, "Usage: call <contract_address> <function> [args...]"}
  end

  # IPFS commands
  def ipfs([], _state) do
    {:error, "Usage:\n  ipfs cat <cid>    - Fetch and display IPFS content\n  ipfs gateway <cid> - Show gateway URLs"}
  end

  def ipfs(["cat", cid], _state) do
    case Droodotfoo.Web3.IPFS.cat(cid) do
      {:ok, content} ->
        formatted = Droodotfoo.Web3.IPFS.format_content(content, max_lines: 100)

        output = """
        IPFS Content
        #{String.duplicate("=", 78)}

        CID:          #{content.cid}
        Content-Type: #{content.content_type}
        Size:         #{format_content_size(content.size)}
        Gateway:      #{String.replace(content.gateway, "https://", "")}

        #{String.duplicate("-", 78)}

        #{formatted}
        """

        {:ok, output}

      {:error, :invalid_cid} ->
        {:error, "Invalid IPFS CID format"}

      {:error, :not_found} ->
        {:error, "Content not found on IPFS"}

      {:error, :content_too_large} ->
        {:error, "Content too large to display (>10MB)"}

      {:error, :all_gateways_failed} ->
        {:error, "Failed to fetch from all IPFS gateways"}

      {:error, reason} ->
        {:error, "Failed to fetch IPFS content: #{reason}"}
    end
  end

  def ipfs(["gateway", cid], _state) do
    if Droodotfoo.Web3.IPFS.valid_cid?(cid) do
      output = """
      IPFS Gateway URLs
      #{String.duplicate("=", 78)}

      CID: #{cid}

      Available Gateways:
      - https://cloudflare-ipfs.com/ipfs/#{cid}
      - https://ipfs.io/ipfs/#{cid}
      - https://gateway.pinata.cloud/ipfs/#{cid}
      - https://dweb.link/ipfs/#{cid}

      Copy any URL to access the content in your browser.
      """

      {:ok, output}
    else
      {:error, "Invalid IPFS CID format"}
    end
  end

  def ipfs(["ls", cid], _state) do
    case Droodotfoo.Web3.IPFS.ls(cid) do
      {:ok, entries} ->
        output = """
        IPFS Directory Listing
        #{String.duplicate("=", 78)}

        CID: #{cid}

        #{format_ipfs_directory(entries)}
        """

        {:ok, output}

      {:error, :invalid_cid} ->
        {:error, "Invalid IPFS CID format"}

      {:error, :not_implemented} ->
        {:error, "Directory listing not yet implemented\n\nUse: ipfs gateway <cid> to view in browser"}

      {:error, reason} ->
        {:error, "Failed to list directory: #{reason}"}
    end
  end

  def ipfs([subcommand | _], _state) do
    {:error, "Unknown ipfs subcommand: #{subcommand}\n\nUsage:\n  ipfs cat <cid>     - Fetch and display content\n  ipfs gateway <cid> - Show gateway URLs\n  ipfs ls <cid>      - List directory (not yet implemented)"}
  end

  defp format_content_size(bytes) when bytes < 1024, do: "#{bytes} bytes"
  defp format_content_size(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 2)} KB"
  defp format_content_size(bytes) when bytes < 1_073_741_824, do: "#{Float.round(bytes / 1_048_576, 2)} MB"
  defp format_content_size(bytes), do: "#{Float.round(bytes / 1_073_741_824, 2)} GB"

  defp format_ipfs_directory(entries) do
    if Enum.empty?(entries) do
      "(empty directory)"
    else
      entries
      |> Enum.map(fn entry ->
        type_indicator = if entry.type == :directory, do: "[DIR]", else: "[FILE]"
        size_str = if entry.size, do: " (#{format_content_size(entry.size)})", else: ""
        "#{type_indicator} #{entry.name}#{size_str}"
      end)
      |> Enum.join("\n")
    end
  end

  # Fileverse dDocs commands
  def ddoc([], state) do
    wallet = get_wallet_address(state)

    if not wallet do
      {:error, "Please connect your wallet first using: web3 connect"}
    else
      {:error, "Usage:\n  ddoc list          - List your documents\n  ddoc new <title>   - Create new document\n  ddoc view <id>     - View document\n  ddoc delete <id>   - Delete document"}
    end
  end

  def ddoc(["list"], state) do
    wallet = get_wallet_address(state)

    if not wallet do
      {:error, "Please connect your wallet first"}
    else
      case Droodotfoo.Fileverse.DDoc.list(wallet) do
        {:ok, docs} ->
          output = """
          Fileverse dDocs - Encrypted Documents
          #{String.duplicate("=", 78)}

          #{Droodotfoo.Fileverse.DDoc.format_doc_list(docs)}

          Note: Full dDocs integration requires @fileverse-dev/ddoc React SDK
          """

          {:ok, output}

        {:error, reason} ->
          {:error, "Failed to list documents: #{reason}"}
      end
    end
  end

  def ddoc(["new", title], state) do
    wallet = get_wallet_address(state)

    if not wallet do
      {:error, "Please connect your wallet first"}
    else
      case Droodotfoo.Fileverse.DDoc.create(title, wallet_address: wallet) do
        {:ok, doc} ->
          {:ok, "Created document: #{doc.id}\nTitle: #{doc.title}\nEncrypted: YES"}

        {:error, :wallet_required} ->
          {:error, "Wallet connection required"}

        {:error, reason} ->
          {:error, "Failed to create document: #{reason}"}
      end
    end
  end

  def ddoc(["view", doc_id], state) do
    wallet = get_wallet_address(state)

    if not wallet do
      {:error, "Please connect your wallet first"}
    else
      case Droodotfoo.Fileverse.DDoc.get(doc_id, wallet) do
        {:ok, doc} ->
          {:ok, Droodotfoo.Fileverse.DDoc.format_doc_info(doc) <> "\n#{String.duplicate("-", 78)}\n\n#{doc.content}"}

        {:error, :not_found} ->
          {:error, "Document not found: #{doc_id}"}

        {:error, reason} ->
          {:error, "Failed to load document: #{reason}"}
      end
    end
  end

  def ddoc([subcommand | _], _state) do
    {:error, "Unknown ddoc subcommand: #{subcommand}"}
  end

  defp get_wallet_address(%{web3_wallet: %{address: address}}) when is_binary(address), do: address
  defp get_wallet_address(_), do: nil

  # docs command - alias for ddoc list
  def docs(_args, state), do: ddoc(["list"], state)

  # Fileverse Storage commands
  def upload([file_path | _rest], state) do
    wallet = get_wallet_address(state)

    if not wallet do
      {:error, "Please connect your wallet first with :web3 connect"}
    else
      case Droodotfoo.Fileverse.Storage.upload(file_path, wallet_address: wallet) do
        {:ok, metadata} ->
          output = """
          File Upload Successful
          #{String.duplicate("=", 78)}

          #{Droodotfoo.Fileverse.Storage.format_file_info(metadata)}

          Note: Full upload implementation requires Fileverse Storage API
          """

          {:ok, output}

        {:error, :wallet_required} ->
          {:error, "Please connect your wallet first with :web3 connect"}

        {:error, reason} ->
          {:error, "Upload failed: #{inspect(reason)}"}
      end
    end
  end

  def upload([], _state) do
    {:error, "Usage: :upload <file_path>"}
  end

  # files command - list uploaded files
  def files(_args, state) do
    wallet = get_wallet_address(state)

    if not wallet do
      {:error, "Please connect your wallet first with :web3 connect"}
    else
      case Droodotfoo.Fileverse.Storage.list_files(wallet) do
        {:ok, file_list} ->
          output = """
          Fileverse Storage - My Files
          #{String.duplicate("=", 78)}

          #{Droodotfoo.Fileverse.Storage.format_file_list(file_list)}

          Use ':file info <cid>' to view file details
          Use ':file versions <cid>' to see version history

          Note: Full storage integration requires Fileverse Storage API
          """

          {:ok, output}

        {:error, :wallet_required} ->
          {:error, "Please connect your wallet first with :web3 connect"}

        {:error, reason} ->
          {:error, "Failed to list files: #{inspect(reason)}"}
      end
    end
  end

  # file command - file operations
  def file(["info", cid], state) do
    wallet = get_wallet_address(state)

    if not wallet do
      {:error, "Please connect your wallet first with :web3 connect"}
    else
      case Droodotfoo.Fileverse.Storage.get_file(cid, wallet) do
        {:ok, metadata} ->
          output = """
          #{Droodotfoo.Fileverse.Storage.format_file_info(metadata)}

          Note: Full storage integration requires Fileverse Storage API
          """

          {:ok, output}

        {:error, :not_found} ->
          {:error, "File not found: #{cid}"}

        {:error, reason} ->
          {:error, "Failed to get file info: #{inspect(reason)}"}
      end
    end
  end

  def file(["versions", cid], _state) do
    case Droodotfoo.Fileverse.Storage.get_versions(cid) do
      {:ok, versions} ->
        version_lines =
          Enum.map(versions, fn v ->
            uploaded = Calendar.strftime(v.uploaded_at, "%Y-%m-%d %H:%M UTC")
            size = format_file_size(v.size)
            "  v#{v.version} - #{v.cid} (#{size}) - #{uploaded}\n  #{v.notes}"
          end)

        output = """
        File Version History
        #{String.duplicate("=", 78)}

        CID: #{cid}

        #{Enum.join(version_lines, "\n\n")}

        Note: Full storage integration requires Fileverse Storage API
        """

        {:ok, output}

      {:error, reason} ->
        {:error, "Failed to get versions: #{inspect(reason)}"}
    end
  end

  def file([], _state) do
    {:error, "Usage: :file info <cid> or :file versions <cid>"}
  end

  def file(_args, _state) do
    {:error, "Usage: :file info <cid> or :file versions <cid>"}
  end

  defp format_file_size(bytes) when bytes < 1024, do: "#{bytes} B"
  defp format_file_size(bytes) when bytes < 1_048_576, do: "#{Float.round(bytes / 1024, 2)} KB"

  defp format_file_size(bytes) when bytes < 1_073_741_824,
    do: "#{Float.round(bytes / 1_048_576, 2)} MB"

  defp format_file_size(bytes), do: "#{Float.round(bytes / 1_073_741_824, 2)} GB"

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
