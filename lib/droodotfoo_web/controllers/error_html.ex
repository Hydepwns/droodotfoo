defmodule DroodotfooWeb.ErrorHTML do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on HTML requests.

  See config/config.exs.
  """
  use DroodotfooWeb, :html

  # Custom error pages with monospace styling
  embed_templates "error_html/*"
end
