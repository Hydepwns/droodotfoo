defmodule DroodotfooWeb.Router do
  use DroodotfooWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DroodotfooWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug DroodotfooWeb.Plugs.ContentSecurityPolicy
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Health check routes (no auth, no rate limiting)
  scope "/health", DroodotfooWeb do
    pipe_through :api

    get "/", HealthController, :index
    get "/ready", HealthController, :ready
  end

  scope "/", DroodotfooWeb do
    pipe_through :browser

    # All LiveViews share a session so navigation preserves the music player
    live_session :default, layout: {DroodotfooWeb.Layouts, :app} do
      live "/", DroodotfooLive
      live "/about", AboutLive
      live "/now", NowLive
      live "/projects", ProjectsLive
      live "/posts", PostsLive
      live "/posts/:slug", PostLive
      live "/sitemap", SitemapLive
      live "/pattern-gallery", PatternGalleryLive
    end

    # RSS feed
    get "/feed.xml", FeedController, :rss

    # Sitemap for SEO
    get "/sitemap.xml", SitemapController, :index

    # Generated patterns for posts
    get "/patterns/:slug", PatternController, :show

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
    end
  end
end
