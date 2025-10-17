defmodule Droodotfoo.Terminal.Commands.Navigation do
  @moduledoc """
  Navigation command implementations for the terminal.

  Provides commands for directory navigation and listing:
  - ls: List directory contents
  - cd: Change directory
  - pwd: Print working directory
  """

  alias Droodotfoo.Terminal.FileSystem

  @doc """
  Lists directory contents with support for flags:
  - `-a`: Show hidden files
  - `-l`: Long format with details
  """
  def ls(args, state) do
    {opts, paths} = parse_ls_args(args)

    paths = if paths == [], do: ["."], else: paths

    output =
      Enum.map_join(paths, "\n", fn path ->
        case FileSystem.list_directory(path, state) do
          {:ok, contents} ->
            format_ls_output(contents, opts, path, state)

          {:error, msg} ->
            "ls: #{msg}"
        end
      end)

    {:ok, output}
  end

  @doc """
  Changes the current directory.
  With no arguments, changes to home directory.
  """
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

  @doc """
  Prints the current working directory.
  """
  def pwd(state) do
    {:ok, state.current_dir}
  end

  # Helper functions

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
      format_long_listing(filtered_contents, path, state)
    else
      # Simple format
      Enum.join(filtered_contents, "  ")
    end
  end

  defp format_long_listing(contents, path, state) do
    Enum.map_join(contents, "\n", fn name ->
      file_path = FileSystem.normalize_path(Path.join(path, name), state.current_dir)
      format_file_entry(file_path, name, state)
    end)
  end

  defp format_file_entry(file_path, name, state) do
    case FileSystem.get_file(file_path, state) do
      %{permissions: perms, owner: owner, size: size} ->
        "#{perms}  #{owner}  #{format_size(size)}  #{name}"

      _ ->
        name
    end
  end

  defp format_size(bytes) when bytes < 1024, do: "#{bytes}B"
  defp format_size(bytes) when bytes < 1024 * 1024, do: "#{div(bytes, 1024)}K"
  defp format_size(bytes), do: "#{div(bytes, 1024 * 1024)}M"
end
