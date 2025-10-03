defmodule Droodotfoo.Terminal.FileSystem do
  @moduledoc """
  Virtual file system for the terminal interface.
  Provides Unix-like directory structure and file operations.
  """

  @doc """
  Initialize the virtual file system structure.
  """
  def init do
    %{
      current_dir: "/home/drew",
      home_dir: "/home/drew",
      files: build_file_system()
    }
  end

  defp build_file_system do
    %{
      "/" => %{
        type: :directory,
        permissions: "drwxr-xr-x",
        owner: "root",
        size: 4096,
        modified: ~N[2024-01-01 00:00:00],
        contents: ["bin", "etc", "home", "usr", "var", "tmp"]
      },
      "/home" => %{
        type: :directory,
        permissions: "drwxr-xr-x",
        owner: "root",
        size: 4096,
        modified: ~N[2024-01-01 00:00:00],
        contents: ["drew"]
      },
      "/home/drew" => %{
        type: :directory,
        permissions: "drwxr-xr-x",
        owner: "drew",
        size: 4096,
        modified: DateTime.utc_now() |> DateTime.truncate(:second),
        contents: [
          "projects",
          "skills",
          "experience",
          "education",
          "contact",
          ".bashrc",
          ".profile",
          "resume.txt",
          "resume.pdf",
          "README.md"
        ]
      },
      "/home/drew/projects" => %{
        type: :directory,
        permissions: "drwxr-xr-x",
        owner: "drew",
        size: 4096,
        modified: DateTime.utc_now() |> DateTime.truncate(:second),
        contents: ["droo.foo", "axol-framework", "terminal-ui", "distributed-system", "README.md"]
      },
      "/home/drew/projects/droo.foo" => %{
        type: :directory,
        permissions: "drwxr-xr-x",
        owner: "drew",
        size: 4096,
        modified: DateTime.utc_now() |> DateTime.truncate(:second),
        contents: ["README.md", "mix.exs", "lib", "assets", "config", ".git"]
      },
      "/home/drew/projects/droo.foo/README.md" => %{
        type: :file,
        permissions: "-rw-r--r--",
        owner: "drew",
        size: 2048,
        modified: DateTime.utc_now() |> DateTime.truncate(:second),
        content: """
        # droo.foo Terminal Portfolio

        An interactive terminal portfolio built with Elixir, Phoenix LiveView, and Raxol.

        ## Features
        - Real Unix-like terminal experience
        - 60fps smooth animations
        - Interactive commands
        - Responsive design
        - Adaptive performance optimization

        ## Tech Stack
        - Elixir & Phoenix LiveView
        - Raxol Terminal UI Framework
        - WebSockets for real-time updates
        - Tailwind CSS

        ## Usage
        Try these commands:
        - `ls` - List directory contents
        - `cat resume.txt` - View my resume
        - `projects` - Browse my projects
        - `help` - Show available commands

        Source: https://github.com/hydepwns/droodotfoo
        """
      },
      "/home/drew/skills" => %{
        type: :directory,
        permissions: "drwxr-xr-x",
        owner: "drew",
        size: 4096,
        modified: DateTime.utc_now() |> DateTime.truncate(:second),
        contents: ["languages.txt", "frameworks.txt", "tools.txt", "databases.txt"]
      },
      "/home/drew/skills/languages.txt" => %{
        type: :file,
        permissions: "-rw-r--r--",
        owner: "drew",
        size: 512,
        modified: DateTime.utc_now() |> DateTime.truncate(:second),
        content: """
        Programming Languages
        ====================

        Expert:
        - Elixir/Erlang
        - JavaScript/TypeScript
        - Python
        - Rust

        Proficient:
        - Go
        - Ruby
        - Java
        - C/C++

        Familiar:
        - Haskell
        - Clojure
        - Swift
        """
      },
      "/home/drew/resume.txt" => %{
        type: :file,
        permissions: "-rw-r--r--",
        owner: "drew",
        size: 3072,
        modified: DateTime.utc_now() |> DateTime.truncate(:second),
        content: """
        Drew Hiro
        Senior Software Engineer
        ========================

        Email: drew@axol.io
        GitHub: https://github.com/hydepwns
        LinkedIn: https://linkedin.com/in/drew-hiro
        Twitter: @MF_DROO

        SUMMARY
        -------
        Experienced software engineer specializing in distributed systems,
        real-time applications, and developer tools. Passionate about
        functional programming and building performant, scalable solutions.

        EXPERIENCE
        ----------
        Senior Software Engineer | Tech Company | 2020-Present
        - Built distributed systems handling millions of requests
        - Led team of 5 engineers on critical infrastructure projects
        - Reduced latency by 60% through optimization

        Software Engineer | Startup | 2018-2020
        - Developed real-time collaboration features
        - Implemented WebSocket architecture
        - Scaled application from 0 to 100k users

        EDUCATION
        ---------
        B.S. Computer Science | University | 2014-2018

        SKILLS
        ------
        Languages: Elixir, JavaScript, Python, Rust, Go
        Frameworks: Phoenix, React, Node.js, FastAPI
        Databases: PostgreSQL, Redis, MongoDB, Cassandra
        Tools: Docker, Kubernetes, AWS, GCP, Terraform

        Type 'download resume.pdf' to get a PDF version
        """
      },
      "/home/drew/.bashrc" => %{
        type: :file,
        permissions: "-rw-r--r--",
        owner: "drew",
        size: 256,
        modified: DateTime.utc_now() |> DateTime.truncate(:second),
        content: """
        # droo.foo shell configuration
        export PS1='[\\u@droo.foo \\W]$ '
        export PATH=$PATH:/usr/local/bin
        alias ll='ls -la'
        alias ..='cd ..'
        alias projects='cd ~/projects'

        # Welcome message
        echo "Welcome to droo.foo terminal"
        echo "Type 'help' for available commands"
        """
      }
    }
  end

  @doc """
  Get file or directory info.
  """
  def get_file(path, state) do
    normalized_path = normalize_path(path, state.current_dir)
    Map.get(state.files, normalized_path)
  end

  @doc """
  List directory contents.
  """
  def list_directory(path, state) do
    normalized_path = normalize_path(path, state.current_dir)

    case get_file(normalized_path, state) do
      %{type: :directory, contents: contents} ->
        {:ok, contents}

      %{type: :file} ->
        {:error, "Not a directory: #{path}"}

      nil ->
        {:error, "No such file or directory: #{path}"}
    end
  end

  @doc """
  Change current directory.
  """
  def change_directory(path, state) do
    normalized_path = normalize_path(path, state.current_dir)

    case get_file(normalized_path, state) do
      %{type: :directory} ->
        {:ok, %{state | current_dir: normalized_path}}

      %{type: :file} ->
        {:error, "Not a directory: #{path}"}

      nil ->
        {:error, "No such directory: #{path}"}
    end
  end

  @doc """
  Read file contents.
  """
  def read_file(path, state) do
    normalized_path = normalize_path(path, state.current_dir)

    case get_file(normalized_path, state) do
      %{type: :file, content: content} ->
        {:ok, content}

      %{type: :directory} ->
        {:error, "Is a directory: #{path}"}

      nil ->
        {:error, "No such file: #{path}"}
    end
  end

  @doc """
  Normalize path (handle ., .., ~, relative paths).
  """
  def normalize_path(path, current_dir) do
    cond do
      # Absolute path
      String.starts_with?(path, "/") ->
        normalize_absolute_path(path)

      # Home directory
      String.starts_with?(path, "~") ->
        path
        |> String.replace_leading("~", "/home/drew")
        |> normalize_absolute_path()

      # Relative path
      true ->
        Path.join(current_dir, path)
        |> normalize_absolute_path()
    end
  end

  defp normalize_absolute_path(path) do
    path
    |> String.split("/")
    |> Enum.reject(&(&1 == "" || &1 == "."))
    |> resolve_parent_dirs([])
    |> case do
      [] -> "/"
      parts -> "/" <> Enum.join(parts, "/")
    end
  end

  defp resolve_parent_dirs([], acc), do: Enum.reverse(acc)
  defp resolve_parent_dirs([".." | rest], [_ | acc]), do: resolve_parent_dirs(rest, acc)
  defp resolve_parent_dirs([".." | rest], []), do: resolve_parent_dirs(rest, [])
  defp resolve_parent_dirs([part | rest], acc), do: resolve_parent_dirs(rest, [part | acc])

  @doc """
  Get directory completions for tab completion.
  """
  def get_directory_completions(partial_path, state) do
    dir = Path.dirname(partial_path)
    prefix = Path.basename(partial_path)

    normalized_dir = normalize_path(dir, state.current_dir)

    case list_directory(normalized_dir, state) do
      {:ok, contents} ->
        contents
        |> Enum.filter(fn name ->
          String.starts_with?(name, prefix) &&
            match?(%{type: :directory}, get_file(Path.join(normalized_dir, name), state))
        end)
        |> Enum.map(&Path.join(dir, &1))

      _ ->
        []
    end
  end

  @doc """
  Get file completions for tab completion.
  """
  def get_file_completions(partial_path, state) do
    dir = Path.dirname(partial_path)
    prefix = Path.basename(partial_path)

    normalized_dir = normalize_path(dir, state.current_dir)

    case list_directory(normalized_dir, state) do
      {:ok, contents} ->
        contents
        |> Enum.filter(&String.starts_with?(&1, prefix))
        |> Enum.map(&Path.join(dir, &1))

      _ ->
        []
    end
  end
end
