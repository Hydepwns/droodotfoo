defmodule DroodotfooWeb.Router do
  use DroodotfooWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DroodotfooWeb.Layouts, :root}
    plug :protect_from_forgery
    plug DroodotfooWeb.Plugs.ContentSecurityPolicy
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DroodotfooWeb do
    pipe_through :browser

    live "/", DroodotfooLive
    live "/about", AboutLive
    live "/projects", ProjectsLive
    live "/web3", Web3Live
    live "/contact", ContactLive
    live "/resume", ResumeLive
    get "/resume/download", PageController, :download_resume
    live "/stl-viewer", STLViewerLive
    live "/spotify", SpotifyLive
    # PWA archived - see .archived_pwa/README.md
    # live "/pwa", PWALive
    live "/posts/:slug", PostLive
    # Test route for Astro STL viewer
    get "/astro-test", PageController, :astro_test

    # Spotify OAuth routes
    get "/auth/spotify", SpotifyAuthController, :authorize
    get "/auth/spotify/callback", SpotifyAuthController, :callback
    get "/auth/spotify/logout", SpotifyAuthController, :logout
  end

  # Service Worker route (no CSP needed)
  scope "/", DroodotfooWeb do
    get "/sw.js", PageController, :service_worker
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
    end
  end
end
