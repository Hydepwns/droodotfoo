defmodule Droodotfoo.GitHub.LanguageColors do
  @moduledoc """
  GitHub's official language colors for syntax highlighting.
  Source: https://github.com/github/linguist
  """

  @colors %{
    "Elixir" => "#6e4a7e",
    "JavaScript" => "#f1e05a",
    "TypeScript" => "#3178c6",
    "Python" => "#3572A5",
    "Rust" => "#dea584",
    "Go" => "#00ADD8",
    "Ruby" => "#701516",
    "Java" => "#b07219",
    "C" => "#555555",
    "C++" => "#f34b7d",
    "C#" => "#178600",
    "PHP" => "#4F5D95",
    "Swift" => "#F05138",
    "Kotlin" => "#A97BFF",
    "Scala" => "#c22d40",
    "Haskell" => "#5e5086",
    "Erlang" => "#B83998",
    "Clojure" => "#db5855",
    "Shell" => "#89e051",
    "Vim Script" => "#199f4b",
    "HTML" => "#e34c26",
    "CSS" => "#563d7c",
    "SCSS" => "#c6538c",
    "Vue" => "#41b883",
    "Svelte" => "#ff3e00",
    "Dart" => "#00B4AB",
    "R" => "#198CE7",
    "Lua" => "#000080",
    "Perl" => "#0298c3",
    "Objective-C" => "#438eff",
    "Dockerfile" => "#384d54",
    "Makefile" => "#427819",
    "CMake" => "#DA3434",
    "Assembly" => "#6E4C13",
    "WebAssembly" => "#04133b",
    "Solidity" => "#AA6746",
    "Nix" => "#7e7eff"
  }

  @doc """
  Returns the color for a given language.
  Falls back to a default gray if language is not found.
  """
  @spec get_color(String.t()) :: String.t()
  def get_color(language) when is_binary(language) do
    Map.get(@colors, language, "#858585")
  end

  def get_color(_), do: "#858585"
end
