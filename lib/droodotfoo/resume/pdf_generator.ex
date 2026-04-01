defmodule Droodotfoo.Resume.PDFGenerator do
  @moduledoc """
  PDF generation for resume exports with multiple formats and real-time preview.
  """

  alias Droodotfoo.Resume.PDF.Templates
  alias Droodotfoo.Resume.ResumeData

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
      print_to_pdf: %{
        paperWidth: 8.27,
        paperHeight: 11.69,
        marginTop: 0.5,
        marginBottom: 0.5,
        marginLeft: 0.5,
        marginRight: 0.5
      },
      output: fn path -> File.read!(path) end
    )
  end

  defp unwrap_result({:ok, pdf_binary}), do: pdf_binary
  defp unwrap_result(:ok), do: raise("PDF generation returned no output")
end
