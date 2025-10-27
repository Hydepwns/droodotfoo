defmodule DroodotfooWeb.PageController do
  @moduledoc """
  Controller for static pages and test routes.
  """

  use DroodotfooWeb, :controller

  def astro_test(conn, _params) do
    # Serve the built Astro test page
    test_page_path =
      Path.join([
        Application.app_dir(:droodotfoo),
        "..",
        "src",
        "astro-components",
        "dist",
        "stl-test",
        "index.html"
      ])
      |> Path.expand()

    if File.exists?(test_page_path) do
      html_content = File.read!(test_page_path)
      html(conn, html_content)
    else
      html(conn, """
      <!DOCTYPE html>
      <html>
        <head>
          <title>Astro STL Viewer Test</title>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width">
        </head>
        <body>
          <h1>Astro STL Viewer Test</h1>
          <p>Test page not found. Please build the Astro components first:</p>
          <pre>cd src/astro-components && npm run build</pre>
        </body>
      </html>
      """)
    end
  end

  def download_resume(conn, %{"format" => format}) do
    alias Droodotfoo.Resume.PDFGenerator

    pdf_content = PDFGenerator.generate_pdf(format)
    filename = "resume_#{format}_#{Date.utc_today()}.pdf"

    conn
    |> put_resp_content_type("application/pdf")
    |> put_resp_header("content-disposition", "attachment; filename=\"#{filename}\"")
    |> send_resp(200, pdf_content)
  end

  def download_resume(conn, _params) do
    # Default to technical format if not specified
    download_resume(conn, %{"format" => "technical"})
  end
end
