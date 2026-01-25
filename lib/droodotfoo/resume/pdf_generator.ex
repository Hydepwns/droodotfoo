defmodule Droodotfoo.Resume.PDFGenerator do
  @moduledoc """
  PDF generation for resume exports with multiple formats and real-time preview.
  """

  alias Droodotfoo.Resume.ResumeData
  alias Droodotfoo.Resume.PDF.Templates

  @formats ~w(technical executive minimal detailed)

  @doc """
  Generate PDF resume in the specified format.
  Returns the PDF binary content directly.
  """
  def generate_pdf(format \\ "technical") do
    format
    |> normalize_format()
    |> do_generate_pdf()
    |> unwrap_result()
  end

  @doc """
  Generate HTML preview for real-time viewing.
  """
  def generate_html_preview(format \\ "technical") do
    format
    |> normalize_format()
    |> generate_html()
  end

  defp normalize_format(format) when format in @formats, do: String.to_existing_atom(format)
  defp normalize_format(_), do: :technical

  defp do_generate_pdf(format) do
    format
    |> generate_html()
    |> convert_html_to_pdf()
  end

  defp generate_html(format) do
    ResumeData.get_resume_data()
    |> Templates.generate(format)
  end

  defp convert_html_to_pdf(html_content) do
    ChromicPDF.print_to_pdf({:html, html_content},
      format: :a4,
      margin: %{top: "0.5in", bottom: "0.5in", left: "0.5in", right: "0.5in"}
    )
  end

  defp unwrap_result({:ok, pdf_content}), do: pdf_content
  defp unwrap_result({:error, reason}), do: raise("PDF generation failed: #{reason}")
end
