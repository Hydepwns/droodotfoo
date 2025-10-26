defmodule DroodotfooWeb.ErrorHTMLTest do
  use DroodotfooWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template, only: [render_to_string: 4]

  test "renders 404.html" do
    html = render_to_string(DroodotfooWeb.ErrorHTML, "404", "html", [])

    assert html =~ "PAGE NOT FOUND"
    assert html =~ "monospace-container"
    assert html =~ "[HOME]"
    assert html =~ "[SITEMAP]"
    assert html =~ "doesn't exist or has been moved"
  end

  test "renders 500.html" do
    html = render_to_string(DroodotfooWeb.ErrorHTML, "500", "html", [])

    assert html =~ "SERVER ERROR"
    assert html =~ "monospace-container"
    assert html =~ "Something went wrong"
    assert html =~ "[HOME]"
    assert html =~ "Troubleshooting steps"
  end
end
