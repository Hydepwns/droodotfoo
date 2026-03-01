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

  # Wiki browser pipeline with wiki-specific settings
  pipeline :wiki_browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DroodotfooWeb.Wiki.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug DroodotfooWeb.Plugs.Subdomain
    plug DroodotfooWeb.Plugs.WikiCacheHeaders
  end

  # Git browser pipeline
  pipeline :git_browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DroodotfooWeb.Git.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug DroodotfooWeb.Plugs.ContentSecurityPolicy
    plug DroodotfooWeb.Plugs.Subdomain
  end

  # Wiki admin pipeline (Tailnet-only)
  pipeline :wiki_admin do
    plug DroodotfooWeb.Plugs.TailnetOnly
  end

  # Health check routes (no auth, no rate limiting)
  scope "/health", DroodotfooWeb do
    pipe_through :api

    get "/", HealthController, :index
    get "/ready", HealthController, :ready
  end

  # ===========================================================================
  # Git Subdomain (git.droo.foo) - Public repository browser
  # ===========================================================================
  # Host-scoped routes MUST come BEFORE catch-all routes

  scope "/", DroodotfooWeb.Git, host: "git." do
    pipe_through :git_browser

    live "/", RepoListLive, :index
    live "/:source/:owner/:repo", RepoDetailLive, :show
    live "/:source/:owner/:repo/tree/:branch", FileBrowserLive, :index
    live "/:source/:owner/:repo/tree/:branch/*path", FileBrowserLive, :show
    live "/:source/:owner/:repo/blob/:branch/*path", FileViewerLive, :show
    live "/:source/:owner/:repo/commits/:branch", CommitsLive, :index
  end

  # ===========================================================================
  # Library Subdomain (lib.droo.foo) - Tailnet-only
  # ===========================================================================

  scope "/", DroodotfooWeb.Wiki.Library, host: "lib." do
    pipe_through [:wiki_browser, :wiki_admin]

    live "/", IndexLive, :index
    live "/upload", UploadLive, :new
    live "/doc/:slug", ReaderLive, :show
  end

  # ===========================================================================
  # Wiki Routes (wiki.droo.foo subdomain)
  # ===========================================================================

  # OSRS REST API (no session, JSON only)
  scope "/osrs/api/v1", DroodotfooWeb.Wiki.OSRS.V1, host: "wiki." do
    pipe_through :api

    resources "/items", ItemController, only: [:index, :show]
    resources "/monsters", MonsterController, only: [:index, :show]
  end

  # Wiki Admin routes (Tailnet-only)
  scope "/admin", DroodotfooWeb.Wiki.Admin, host: "wiki." do
    pipe_through [:wiki_browser, :wiki_admin]

    live "/sync", SyncLive, :index
    live "/pending", PendingLive, :index
    live "/pending/:id", PendingLive, :show
    live "/redirects", RedirectsLive, :index

    # WikiArt curation
    live "/art", ArtLive.Index, :index
    live "/art/add", ArtLive.Form, :new
    live "/art/:slug/edit", ArtLive.Form, :edit
  end

  # Wiki public routes
  scope "/", DroodotfooWeb.Wiki, host: "wiki." do
    pipe_through :wiki_browser

    # RSS feeds
    get "/feed.xml", FeedController, :index
    get "/:source/feed.xml", FeedController, :source

    # Sitemap
    get "/sitemap.xml", SitemapController, :index

    live "/", LandingLive, :index
    live "/search", SearchLive, :index

    # Auto parts catalog
    live "/parts", Parts.IndexLive, :index
    live "/parts/add", Parts.FormLive, :new
    live "/parts/:number", Parts.ShowLive, :show

    # Source index routes (browse articles by source)
    live "/osrs", SourceIndexLive, :index, as: :osrs_index
    live "/nlab", SourceIndexLive, :index, as: :nlab_index
    live "/wikipedia", SourceIndexLive, :index, as: :wikipedia_index
    live "/art", SourceIndexLive, :index, as: :wikiart_index
    live "/machines", SourceIndexLive, :index, as: :machines_index

    # Source-specific article routes
    live "/osrs/:slug", ArticleLive, :show
    live "/nlab/:slug", ArticleLive, :show
    live "/wikipedia/:slug", ArticleLive, :show
    live "/art/:slug", ArticleLive, :show
    live "/machines/:slug", ArticleLive, :show
  end

  # ===========================================================================
  # Main Site Routes (droo.foo)
  # ===========================================================================

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
      live "/contact", ContactLive
      live "/resume", ResumeLive
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
