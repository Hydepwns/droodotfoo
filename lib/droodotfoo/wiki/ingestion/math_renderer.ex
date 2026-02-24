defmodule Droodotfoo.Wiki.Ingestion.MathRenderer do
  @moduledoc """
  Math rendering utilities for nLab content.

  nLab uses itex notation which is largely compatible with LaTeX/KaTeX.
  """

  @doc """
  Process content and prepare math for KaTeX rendering.
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

  defp process_display_math(content) do
    Regex.replace(~r/\$\$(.+?)\$\$/s, content, fn _, math ->
      math = String.trim(math)
      escaped = html_escape(math)
      "<div class=\"math-display\" data-math=\"#{escaped}\">\\[#{escaped}\\]</div>"
    end)
  end

  defp process_inline_math(content) do
    Regex.replace(~r/(?<!\$)\$([^\$\n]+?)\$(?!\$)/, content, fn _, math ->
      math = String.trim(math)
      escaped = html_escape(math)
      "<span class=\"math-inline\" data-math=\"#{escaped}\">\\(#{escaped}\\)</span>"
    end)
  end

  defp normalize_itex_commands(content) do
    content
    |> String.replace(~r/\\array\{([^}]+)\}/, "\\begin{array}{\\1}")
    |> String.replace("\\leftarrow", "\\leftarrow")
    |> String.replace("\\rightarrow", "\\rightarrow")
    |> String.replace("\\Rightarrow", "\\Rightarrow")
    |> String.replace("\\Leftarrow", "\\Leftarrow")
    |> String.replace("\\coloneqq", "\\coloneqq")
    |> String.replace("\\eqqcolon", "\\eqqcolon")
  end

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
