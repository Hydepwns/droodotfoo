defmodule DroodotfooWeb.Router do
  use DroodotfooWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DroodotfooWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DroodotfooWeb do
    pipe_through :browser

    live "/", DroodotfooLive
    live "/posts/:slug", PostLive

    # Spotify OAuth routes
    get "/auth/spotify", SpotifyAuthController, :authorize
    get "/auth/spotify/callback", SpotifyAuthController, :callback
    get "/auth/spotify/logout", SpotifyAuthController, :logout
  end

  # API routes for Obsidian publishing
  scope "/api", DroodotfooWeb do
    pipe_through :api

    post "/posts", PostController, :create
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:droodotfoo, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DroodotfooWeb.Telemetry
      live "/raxol-demo", DroodotfooWeb.RaxolDemoLive
      live "/raxol-comparison", DroodotfooWeb.RaxolComparisonLive
      live "/stl-viewer-demo", DroodotfooWeb.STLViewerDemoLive
    end
  end
end
