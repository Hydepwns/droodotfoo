defmodule WikiWeb.Router do
  use WikiWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WikiWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug WikiWeb.Plugs.Subdomain
    plug WikiWeb.Plugs.CacheHeaders
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin do
    plug WikiWeb.Plugs.TailnetOnly
  end

  # ===========================================================================
  # Library Routes (lib.droo.foo) - Tailnet-only per plan
  # ===========================================================================
  # Note: Host-scoped routes must come BEFORE catch-all routes

  scope "/", WikiWeb.Library, host: "lib." do
    pipe_through [:browser, :admin]

    live "/", IndexLive, :index
    live "/upload", UploadLive, :new
    live "/doc/:slug", ReaderLive, :show
  end

  # ===========================================================================
  # Wiki Routes (wiki.droo.foo, localhost, and direct IP)
  # ===========================================================================

  scope "/", WikiWeb do
    pipe_through :browser

    live "/", LandingLive, :index
    live "/search", SearchLive, :index

    # Source-specific article routes (consistent :slug param)
    live "/osrs/:slug", ArticleLive, :show
    live "/nlab/:slug", ArticleLive, :show
    live "/wikipedia/:slug", ArticleLive, :show
    live "/art/:slug", ArticleLive, :show
    live "/machines/:slug", ArticleLive, :show

    # Auto parts catalog
    live "/parts", Parts.IndexLive, :index
    live "/parts/add", Parts.FormLive, :new
    live "/parts/:number", Parts.ShowLive, :show
  end

  # ===========================================================================
  # GEX API (Tailnet or tunnel)
  # ===========================================================================

  scope "/osrs/api/v1", WikiWeb.OSRS.V1 do
    pipe_through :api

    resources "/items", ItemController, only: [:index, :show]
    resources "/monsters", MonsterController, only: [:index, :show]
  end

  # ===========================================================================
  # Admin Routes (Tailnet-only)
  # ===========================================================================

  scope "/admin", WikiWeb.Admin do
    pipe_through [:browser, :admin]

    live "/sync", SyncLive, :index
    live "/pending", PendingLive, :index

    # WikiArt curation
    live "/art", ArtLive.Index, :index
    live "/art/add", ArtLive.Form, :new
    live "/art/:slug/edit", ArtLive.Form, :edit
  end

  # ===========================================================================
  # Development Routes
  # ===========================================================================

  if Application.compile_env(:wiki, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: WikiWeb.Telemetry
    end
  end

  # Health and metrics endpoints
  scope "/api" do
    pipe_through [:api]
    get "/health", WikiWeb.HealthController, :index
  end

  scope "/" do
    pipe_through [:api]
    get "/metrics", WikiWeb.MetricsController, :index
  end
end
