defmodule Wiki.Ingestion.MathRenderer do
  @moduledoc """
  Math rendering utilities for nLab content.

  nLab uses itex notation which is largely compatible with LaTeX/KaTeX.
  This module:
  - Extracts math blocks from content
  - Wraps them for client-side KaTeX rendering
  - Handles both inline ($...$) and display ($$...$$) math

  ## Output Format

  Math is wrapped in spans with data attributes for client-side rendering:
  - `<span class="math-inline" data-math="...">` for inline
  - `<div class="math-display" data-math="...">` for display

  The frontend uses KaTeX to render these on page load.
  """

  @doc """
  Process content and prepare math for KaTeX rendering.

  Replaces itex/LaTeX math notation with KaTeX-ready HTML wrappers.
  """
  @spec prepare_math(String.t()) :: String.t()
  def prepare_math(content) when is_binary(content) do
    content
    |> process_display_math()
    |> process_inline_math()
    |> normalize_itex_commands()
  end

  @doc """
  Extract all math expressions from content.

  Returns a list of {type, math} tuples where type is :inline or :display.
  """
  @spec extract_math(String.t()) :: [{:inline | :display, String.t()}]
  def extract_math(content) when is_binary(content) do
    display_math =
      Regex.scan(~r/\$\$(.+?)\$\$/s, content)
      |> Enum.map(fn [_, math] -> {:display, math} end)

    inline_math =
      Regex.scan(~r/(?<!\$)\$([^\$\n]+?)\$(?!\$)/, content)
      |> Enum.map(fn [_, math] -> {:inline, math} end)

    display_math ++ inline_math
  end

  @doc """
  Check if content contains math notation.
  """
  @spec has_math?(String.t()) :: boolean()
  def has_math?(content) when is_binary(content) do
    String.contains?(content, "$")
  end

  # Process display math ($$...$$)
  defp process_display_math(content) do
    Regex.replace(~r/\$\$(.+?)\$\$/s, content, fn _, math ->
      math = String.trim(math)
      escaped = html_escape(math)
      "<div class=\"math-display\" data-math=\"#{escaped}\">\\[#{escaped}\\]</div>"
    end)
  end

  # Process inline math ($...$)
  defp process_inline_math(content) do
    # Match single $ but not $$
    Regex.replace(~r/(?<!\$)\$([^\$\n]+?)\$(?!\$)/, content, fn _, math ->
      math = String.trim(math)
      escaped = html_escape(math)
      "<span class=\"math-inline\" data-math=\"#{escaped}\">\\(#{escaped}\\)</span>"
    end)
  end

  # Normalize itex-specific commands to standard LaTeX
  defp normalize_itex_commands(content) do
    content
    # itex uses \array, KaTeX prefers \begin{array}
    |> String.replace(~r/\\array\{([^}]+)\}/, "\\begin{array}{\\1}")
    # Handle common itex macros
    |> String.replace("\\leftarrow", "\\leftarrow")
    |> String.replace("\\rightarrow", "\\rightarrow")
    |> String.replace("\\Rightarrow", "\\Rightarrow")
    |> String.replace("\\Leftarrow", "\\Leftarrow")
    # itex-specific commands that need translation
    |> String.replace("\\coloneqq", "\\coloneqq")
    |> String.replace("\\eqqcolon", "\\eqqcolon")
  end

  # Escape HTML special characters in math for data attribute
  defp html_escape(str) do
    str
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
    |> String.replace("'", "&#39;")
  end

  @doc """
  Generate the KaTeX JavaScript initialization code.

  Include this in the page to render all math elements.
  """
  @spec katex_init_script() :: String.t()
  def katex_init_script do
    """
    <script>
    document.addEventListener('DOMContentLoaded', function() {
      document.querySelectorAll('.math-inline').forEach(function(el) {
        katex.render(el.dataset.math, el, {throwOnError: false, displayMode: false});
      });
      document.querySelectorAll('.math-display').forEach(function(el) {
        katex.render(el.dataset.math, el, {throwOnError: false, displayMode: true});
      });
    });
    </script>
    """
  end
end
