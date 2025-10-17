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

  def service_worker(conn, _params) do
    # Serve the service worker file with proper headers
    service_worker_path =
      Path.join([
        Application.app_dir(:droodotfoo),
        "priv",
        "static",
        "sw.js"
      ])
      |> Path.expand()

    if File.exists?(service_worker_path) do
      conn
      |> put_resp_content_type("application/javascript")
      |> put_resp_header("cache-control", "no-cache, no-store, must-revalidate")
      |> put_resp_header("service-worker-allowed", "/")
      |> send_file(200, service_worker_path)
    else
      conn
      |> put_status(:not_found)
      |> text("Service worker not found")
    end
  end
end
