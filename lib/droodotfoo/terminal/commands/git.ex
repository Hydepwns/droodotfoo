defmodule Droodotfoo.Terminal.Commands.Git do
  @moduledoc """
  Git and development tool command implementations for the terminal.

  Provides simulated commands for:
  - git: Version control operations
  - Package managers: npm, pip, yarn, cargo
  - Network tools: curl, wget, ping, ssh
  - Archive tools: tar
  """

  # Git Commands

  @doc """
  Simulated git commands (status, log, etc).
  """
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

  # Package Managers

  @doc """
  Simulated npm package manager commands.
  """
  def npm(args, _state) do
    case args do
      ["install"] ->
        {:ok, "npm install\n└── droo.foo@1.0.0\n\nAll dependencies installed successfully!"}

      ["start"] ->
        {:ok, "Starting development server...\nServer running at http://localhost:4000"}

      ["test"] ->
        {:ok, "Running test suite...\n\n[+] All tests passed!"}

      ["version"] ->
        {:ok, "8.19.2"}

      [] ->
        {:ok, "npm <command>\n\nCommands: install, start, test, build, version"}

      _ ->
        {:error, "npm: Unknown command"}
    end
  end

  @doc """
  Simulated pip package manager commands.
  """
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

  @doc """
  Simulated yarn package manager commands.
  """
  def yarn(args, _state) do
    case args do
      ["install"] ->
        {:ok,
         "yarn install v1.22.19\n[1/4] Resolving packages...\n[2/4] Fetching packages...\n[3/4] Linking dependencies...\n[4/4] Building fresh packages...\nDone in 2.34s."}

      ["start"] ->
        {:ok, "yarn run v1.22.19\nStarting development server at http://localhost:4000"}

      [] ->
        {:ok, "yarn <command>\n\nCommands: install, start, test, build, add, remove"}

      _ ->
        {:ok, "yarn: Unknown command '#{Enum.join(args, " ")}'"}
    end
  end

  @doc """
  Simulated cargo (Rust) package manager commands.
  """
  def cargo(args, _state) do
    case args do
      ["build"] ->
        {:ok,
         "   Compiling droo-foo v1.0.0\n    Finished dev [unoptimized + debuginfo] target(s) in 2.34s"}

      ["test"] ->
        {:ok,
         "   Compiling droo-foo v1.0.0\n    Finished test [unoptimized + debuginfo] target(s)\n     Running tests...\n\ntest result: ok. 42 passed; 0 failed"}

      ["run"] ->
        {:ok,
         "   Compiling droo-foo v1.0.0\n    Finished dev [unoptimized + debuginfo] target(s)\n     Running `target/debug/droo-foo`"}

      [] ->
        {:ok, "cargo <command>\n\nCommands: build, test, run, check, clean"}

      _ ->
        {:ok, "cargo: unknown command '#{Enum.join(args, " ")}'"}
    end
  end

  # Network Tools

  @doc """
  Simulated curl command with droo.foo easter egg.
  """
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

  @doc """
  Simulated wget download command.
  """
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

  @doc """
  Simulated ping network diagnostic command.
  """
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

  @doc """
  Simulated SSH connection command.
  """
  def ssh(args, _state) do
    host = List.first(args) || "example.com"

    {:ok,
     """
     ssh: connecting to #{host}...
     Permission denied (publickey).

     This is a simulated terminal. SSH connections are not available.
     Use the terminal commands to explore the system!
     """}
  end

  @doc """
  Simulated tar archive command.
  """
  def tar(args, _state) do
    case args do
      ["-xzf" | _files] ->
        {:ok, "tar: extracted archive successfully"}

      ["-czf" | _files] ->
        {:ok, "tar: created archive successfully"}

      [] ->
        {:ok,
         "tar: missing arguments\n\nUsage: tar -xzf file.tar.gz (extract)\n       tar -czf archive.tar.gz files (create)"}

      _ ->
        {:ok, "tar: processing #{Enum.join(args, " ")}"}
    end
  end
end
