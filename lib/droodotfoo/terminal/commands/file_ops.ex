defmodule Droodotfoo.Terminal.Commands.FileOps do
  @moduledoc """
  File operation command implementations for the terminal.

  Provides commands for:
  - find: Search for files by pattern
  - cat: Concatenate and display file contents
  - head/tail: Display beginning/end of files
  - grep: Search for patterns in files
  - rm: Remove files
  - touch: Create empty files
  - mkdir: Create directories
  - cp: Copy files
  - mv: Move/rename files
  - wc: Word/line count
  """

  alias Droodotfoo.Terminal.FileSystem

  # File Search

  @doc """
  Find files matching a pattern in a directory.
  """
  def find(args, state) do
    {opts, paths} = parse_find_args(args)
    name_pattern = opts[:name] || "*"
    search_path = List.first(paths) || "."

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

  # File Content Operations

  @doc """
  Concatenate and display file contents.
  """
  def cat([], _state) do
    {:error, "cat: missing operand"}
  end

  def cat(files, state) do
    output =
      Enum.map_join(files, "\n", fn file ->
        case FileSystem.read_file(file, state) do
          {:ok, content} -> content
          {:error, msg} -> "cat: #{msg}"
        end
      end)

    {:ok, output}
  end

  @doc """
  Display the first N lines of files (default 10).
  """
  def head(args, state) do
    {n, files} = parse_head_tail_args(args, 10)

    files = if files == [], do: ["README.md"], else: files

    output =
      Enum.map_join(files, "\n\n", fn file ->
        case FileSystem.read_file(file, state) do
          {:ok, content} ->
            lines =
              String.split(content, "\n")
              |> Enum.take(n)
              |> Enum.join("\n")

            format_file_output(file, lines, length(files))

          {:error, msg} ->
            "head: #{msg}"
        end
      end)

    {:ok, output}
  end

  @doc """
  Display the last N lines of files (default 10).
  """
  def tail(args, state) do
    {n, files} = parse_head_tail_args(args, 10)

    files = if files == [], do: ["README.md"], else: files

    output =
      Enum.map_join(files, "\n\n", fn file ->
        case FileSystem.read_file(file, state) do
          {:ok, content} ->
            lines =
              String.split(content, "\n")
              |> Enum.take(-n)
              |> Enum.join("\n")

            format_file_output(file, lines, length(files))

          {:error, msg} ->
            "tail: #{msg}"
        end
      end)

    {:ok, output}
  end

  @doc """
  Search for patterns in files (grep).
  """
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
            process_grep_matches(content, file, pattern, length(files))

          {:error, msg} ->
            "grep: #{msg}"
        end
      end)
      |> Enum.reject(&is_nil/1)
      |> Enum.join("\n")

    {:ok, output}
  end

  # File Management

  @doc """
  Remove files (with easter egg for dangerous commands).
  """
  def rm(args, _state) do
    case args do
      ["-rf", "/"] -> {:error, "rm: permission denied (nice try!)"}
      [] -> {:error, "rm: missing operand"}
      files -> {:ok, "rm: removed #{Enum.join(files, ", ")}"}
    end
  end

  @doc """
  Create empty files.
  """
  def touch(args, _state) do
    case args do
      [] -> {:error, "touch: missing file operand"}
      files -> {:ok, "touch: created #{Enum.join(files, ", ")}"}
    end
  end

  @doc """
  Create directories.
  """
  def mkdir(args, _state) do
    case args do
      [] -> {:error, "mkdir: missing operand"}
      ["-p" | dirs] -> {:ok, "mkdir: created directories #{Enum.join(dirs, ", ")} (with parents)"}
      dirs -> {:ok, "mkdir: created #{Enum.join(dirs, ", ")}"}
    end
  end

  @doc """
  Copy files and directories.
  """
  def cp(args, _state) do
    case args do
      [] -> {:error, "cp: missing file operand"}
      [_] -> {:error, "cp: missing destination file operand"}
      ["-r", source | dest] -> {:ok, "cp: copied directory #{source} to #{Enum.join(dest, ", ")}"}
      [source | dest] -> {:ok, "cp: copied #{source} to #{Enum.join(dest, ", ")}"}
    end
  end

  @doc """
  Move or rename files.
  """
  def mv(args, _state) do
    case args do
      [] -> {:error, "mv: missing file operand"}
      [_] -> {:error, "mv: missing destination file operand"}
      [source, dest] -> {:ok, "mv: renamed #{source} to #{dest}"}
      [source | dests] -> {:ok, "mv: moved #{source} to #{Enum.join(dests, ", ")}"}
    end
  end

  @doc """
  Count lines, words, and characters in files.
  """
  def wc(args, state) do
    files = if args == [], do: ["README.md"], else: args

    output =
      Enum.map_join(files, "\n", fn file ->
        case FileSystem.read_file(file, state) do
          {:ok, content} ->
            lines = String.split(content, "\n") |> length()
            words = String.split(content, ~r/\s+/) |> Enum.reject(&(&1 == "")) |> length()
            chars = String.length(content)

            "#{lines} #{words} #{chars} #{file}"

          {:error, msg} ->
            "wc: #{msg}"
        end
      end)

    {:ok, output}
  end

  # Helper Functions

  @doc false
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

  @doc false
  defp match_pattern?(_file, "*"), do: true

  defp match_pattern?(file, pattern) do
    pattern
    |> String.replace("*", ".*")
    |> Regex.compile!()
    |> Regex.match?(file)
  end

  @doc false
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

  defp format_file_output(file, lines, file_count) do
    if file_count > 1 do
      "==> #{file} <==\n#{lines}"
    else
      lines
    end
  end

  defp format_grep_line(file, line, num, file_count) do
    if file_count > 1 do
      "#{file}:#{num}:#{line}"
    else
      "#{num}:#{line}"
    end
  end

  defp process_grep_matches(content, file, pattern, file_count) do
    matching_lines =
      String.split(content, "\n")
      |> Enum.with_index(1)
      |> Enum.filter(fn {line, _} -> String.contains?(line, pattern) end)
      |> Enum.map_join("\n", fn {line, num} ->
        format_grep_line(file, line, num, file_count)
      end)

    if matching_lines == "" do
      nil
    else
      matching_lines
    end
  end
end
