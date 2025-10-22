defmodule Droodotfoo.MixProject do
  use Mix.Project

  def project do
    [
      app: :droodotfoo,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [
        tool: ExCoveralls,
        summary: [threshold: 85]
      ],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.github": :test
      ],
      docs: [
        main: "readme",
        name: "droo.foo Terminal",
        source_url: "https://github.com/hydepwns/droodotfoo",
        homepage_url: "https://droo.foo",
        extras: [
          "README.md",
          "docs/DEVELOPMENT.md",
          "docs/TODO.md",
          "docs/architecture.md",
          "docs/deployment.md"
        ],
        groups_for_modules: [
          Core: [
            Droodotfoo.RaxolApp,
            ~r/^Droodotfoo\.Raxol\./,
            Droodotfoo.TerminalBridge,
            Droodotfoo.Application
          ],
          "Plugin System": [
            Droodotfoo.PluginSystem,
            ~r/^Droodotfoo\.Plugins\./
          ],
          Integrations: [
            Droodotfoo.Spotify,
            ~r/^Droodotfoo\.Spotify\./,
            Droodotfoo.GitHub,
            ~r/^Droodotfoo\.GitHub\./
          ],
          Web3: [
            Droodotfoo.Web3,
            ~r/^Droodotfoo\.Web3\./
          ],
          Fileverse: [
            ~r/^Droodotfoo\.Fileverse\./
          ],
          Terminal: [
            ~r/^Droodotfoo\.Terminal\./
          ],
          "Content & Blog": [
            ~r/^Droodotfoo\.Content\./
          ],
          Web: [
            DroodotfooWeb,
            ~r/^DroodotfooWeb\./
          ]
        ],
        groups_for_extras: [
          Guides: [
            "README.md",
            "docs/DEVELOPMENT.md",
            "docs/architecture.md",
            "docs/deployment.md"
          ],
          Planning: ["docs/TODO.md"]
        ]
      ],
      compilers: Mix.compilers(),
      listeners: [Phoenix.CodeReloader]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Droodotfoo.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  def cli do
    [
      preferred_envs: [precommit: :test]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.8.1"},
      {:phoenix_html, "~> 4.1"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 1.1.12"},
      {:lazy_html, ">= 0.1.0", only: :test},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:telemetry_metrics, "~> 1.0"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.2.0"},
      {:bandit, "~> 1.5"},
      {:tzdata, "~> 1.1"},
      # Portal P2P dependencies
      {:phoenix_pubsub, "~> 2.0"},
      {:raxol, "~> 1.4.1", runtime: false},
      # Spotify integration dependencies
      {:req, "~> 0.5"},
      {:oauth2, "~> 2.1"},
      # Property-based testing
      {:stream_data, "~> 1.0", only: [:test, :dev]},
      # Code quality tools
      {:excoveralls, "~> 0.18", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_check, "~> 0.16.0", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.13", only: [:dev, :test], runtime: false},
      # Blog system dependencies
      {:mdex, "~> 0.2"},
      {:yaml_elixir, "~> 2.9"},
      {:plug_crypto, "~> 2.0"},
      # Web3 integration dependencies
      {:ethers, "~> 0.6.7"},
      {:ethereumex, "~> 0.10"},
      {:ex_keccak, "~> 0.7"},
      {:ex_secp256k1, "~> 0.7"},
      # E2E Encryption (Signal Protocol)
      {:libsignal_protocol, "~> 0.1.1"},
      # Email functionality
      {:swoosh, "~> 1.15"},
      # PDF generation (using system wkhtmltopdf)
      {:chromic_pdf, "~> 1.0"},
      # Documentation
      {:ex_doc, "~> 0.30", only: :dev, runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": [
        "compile",
        "tailwind droodotfoo",
        "esbuild droodotfoo",
        "cmd mkdir -p priv/static/astro && cp -r assets/astro/* priv/static/astro/"
      ],
      "assets.deploy": [
        "tailwind droodotfoo --minify",
        "esbuild droodotfoo --minify",
        "cmd mkdir -p priv/static/astro && cp -r assets/astro/* priv/static/astro/",
        "phx.digest"
      ],
      precommit: ["compile --warning-as-errors", "deps.unlock --unused", "format", "test"],
      check: ["ex_check"],
      "check.quick": ["compile --warning-as-errors", "format --check-formatted", "credo --strict"],
      "check.full": ["ex_check", "deps.unlock --unused"]
    ]
  end
end
