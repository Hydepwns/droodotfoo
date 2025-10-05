defmodule Droodotfoo.Projects do
  @moduledoc """
  Portfolio project data management.
  Stores and retrieves project information for showcase.
  """

  defstruct [
    :id,
    :name,
    :tagline,
    :description,
    :tech_stack,
    :github_url,
    :demo_url,
    :live_demo,
    :status,
    :highlights,
    :year,
    :ascii_thumbnail
  ]

  @type t :: %__MODULE__{
          id: atom(),
          name: String.t(),
          tagline: String.t(),
          description: String.t(),
          tech_stack: list(String.t()),
          github_url: String.t() | nil,
          demo_url: String.t() | nil,
          live_demo: boolean(),
          status: :active | :completed | :archived,
          highlights: list(String.t()),
          year: integer(),
          ascii_thumbnail: list(String.t())
        }

  @doc """
  Returns all projects in the portfolio
  """
  @spec all() :: list(t())
  def all do
    [
      %__MODULE__{
        id: :droodotfoo,
        name: "droo.foo Terminal Portfolio",
        tagline: "This site! Real-time terminal UI in the browser",
        description:
          "A unique portfolio website built as a terminal interface using Phoenix LiveView and the Raxol framework. Features real-time rendering at 60fps, vim-style navigation, plugin system, and integrations with Spotify and GitHub.",
        tech_stack: ["Elixir", "Phoenix", "LiveView", "Raxol", "WebSockets", "JavaScript"],
        github_url: "https://github.com/hydepwns/droodotfoo",
        demo_url: "https://droo.foo",
        live_demo: true,
        status: :active,
        highlights: [
          "60fps terminal rendering with virtual DOM",
          "Vim keybindings and command mode",
          "Plugin system (Tetris, 2048, Wordle, Conway)",
          "Spotify & GitHub API integrations",
          "CRT effects and accessibility features",
          "665 passing tests, 100% pass rate"
        ],
        year: 2025,
        ascii_thumbnail: [
          "╭──────────────────────╮",
          "│ ░▒▓ Terminal UI ▓▒░ │",
          "│                     │",
          "│ [drew@droo.foo ~]$  │",
          "│ > ls -la            │",
          "│ ░░░░░░░░░░░░░░░░░░░ │",
          "│ ╭─ Navigation ────╮ │",
          "│ │ ▓ Home          │ │",
          "│ │ ░ Projects      │ │",
          "╰─│ ░ Skills        │─╯",
          "  ╰─────────────────╯  "
        ]
      },
      %__MODULE__{
        id: :raxol_web,
        name: "RaxolWeb Framework",
        tagline: "Web rendering components for Raxol terminal UI",
        description:
          "Extracted from droo.foo and contributed to the Raxol project. Provides Phoenix LiveView components for rendering terminal UIs in the browser with theme support and performance optimization.",
        tech_stack: ["Elixir", "Phoenix LiveView", "Virtual DOM", "CSS"],
        github_url: "https://github.com/Hydepwns/raxol",
        demo_url: nil,
        live_demo: false,
        status: :completed,
        highlights: [
          "Buffer to HTML rendering engine",
          "7 built-in terminal themes",
          "Virtual DOM diffing for performance",
          "67 comprehensive tests",
          "60fps capable rendering",
          "90%+ cache hit ratio"
        ],
        year: 2025,
        ascii_thumbnail: [
          "╭──────────────────────╮",
          "│ defmodule RaxolWeb  │",
          "│   use Phoenix.      │",
          "│       LiveView      │",
          "│                     │",
          "│  Buffer ░▒▓ HTML    │",
          "│         ░▒▓         │",
          "│  ▓▓▓▓▓▓▓▓▓▓ 60fps   │",
          "│  ░░░░░░░░░░ render  │",
          "╰──────────────────────╯"
        ]
      },
      %__MODULE__{
        id: :crdt_collab,
        name: "Real-time Collaboration Platform",
        tagline: "Distributed systems with CRDT-based sync",
        description:
          "A real-time collaborative editing platform using Conflict-free Replicated Data Types (CRDTs) for distributed synchronization. Built with Elixir's OTP for fault tolerance and Phoenix Channels for real-time communication.",
        tech_stack: ["Elixir", "Phoenix", "CRDTs", "OTP", "WebSockets", "PostgreSQL"],
        github_url: nil,
        demo_url: nil,
        live_demo: false,
        status: :active,
        highlights: [
          "CRDT-based conflict resolution",
          "Distributed state synchronization",
          "OTP supervision trees for fault tolerance",
          "Phoenix Channels for real-time updates",
          "Handles 1000+ concurrent users",
          "Sub-100ms latency for sync operations"
        ],
        year: 2024,
        ascii_thumbnail: [
          "╭──────────────────────╮",
          "│  ░ Real-time Sync ░  │",
          "│                     │",
          "│     ▓━━━━━━━▓       │",
          "│    ╱ ░░░░░░ ╲      │",
          "│   ╱  ░░░░░░  ╲     │",
          "│  ▓   ░░░░░░   ▓    │",
          "│   ╲  ▒▒▒▒▒▒  ╱     │",
          "│    ╲ ▒▒▒▒▒▒ ╱      │",
          "│     ▓━━━━━━━▓       │",
          "╰─── CRDT Network ────╯"
        ]
      },
      %__MODULE__{
        id: :obsidian_blog,
        name: "Obsidian Publishing Pipeline",
        tagline: "Obsidian -> Phoenix publishing system",
        description:
          "A content management system that transforms Obsidian markdown notes into a Phoenix-powered blog. Features automatic deployment, markdown processing, and content API.",
        tech_stack: ["Elixir", "Phoenix", "Markdown", "File System", "API", "GitHub Actions"],
        github_url: nil,
        demo_url: nil,
        live_demo: false,
        status: :completed,
        highlights: [
          "Automated markdown processing pipeline",
          "Obsidian vault integration",
          "Full-text search with PostgreSQL",
          "RESTful API for content access",
          "Continuous deployment via GitHub Actions",
          "Support for frontmatter and wikilinks"
        ],
        year: 2023,
        ascii_thumbnail: [
          "╭──────────────────────╮",
          "│ # Notes.md          │",
          "│ ══════════════════  │",
          "│ ▓▓ Obsidian Vault   │",
          "│        ║            │",
          "│      ░▒▓▒░          │",
          "│        ║            │",
          "│ ╭──────────────╮    │",
          "│ │  Transform   │    │",
          "│ ╰──────║───────╯    │",
          "│   ░▒▓ Phoenix Blog  │",
          "╰──────────────────────╯"
        ]
      },
      %__MODULE__{
        id: :fintech_payments,
        name: "Real-time Payment Processing System",
        tagline: "High-throughput financial transaction engine",
        description:
          "Built at a FinTech startup to handle millions of daily transactions. Designed for fault tolerance, compliance, and real-time processing with comprehensive audit trails.",
        tech_stack: ["Elixir", "PostgreSQL", "Broadway", "Telemetry", "Kafka", "Redis"],
        github_url: nil,
        demo_url: nil,
        live_demo: false,
        status: :archived,
        highlights: [
          "Processes 1M+ transactions daily",
          "99.9% uptime SLA maintained",
          "Broadway for event-driven processing",
          "Comprehensive audit logging",
          "PCI DSS compliance implementation",
          "Real-time fraud detection"
        ],
        year: 2021,
        ascii_thumbnail: [
          "╭──────────────────────╮",
          "│  ░▒▓ Payment Flow   │",
          "│                     │",
          "│  ╭────────────╮     │",
          "│  │ Validate   │     │",
          "│  ╰──────▓─────╯     │",
          "│      ░░▒▒▓▓         │",
          "│  ╭────────────╮     │",
          "│  │  Process   │     │",
          "│  ╰──────▓─────╯     │",
          "│                     │",
          "│  ████████ 1M+/day   │",
          "╰──────────────────────╯"
        ]
      },
      %__MODULE__{
        id: :event_microservices,
        name: "Event-Driven Microservices Platform",
        tagline: "Scalable backend architecture at axol.io",
        description:
          "Architected and built a microservices platform using event sourcing and CQRS patterns. Reduced API response times by 70% through optimization and caching strategies.",
        tech_stack: [
          "Elixir",
          "Phoenix",
          "Event Sourcing",
          "CQRS",
          "Docker",
          "Kubernetes",
          "Redis"
        ],
        github_url: nil,
        demo_url: nil,
        live_demo: false,
        status: :active,
        highlights: [
          "70% reduction in API response time",
          "Event sourcing with audit trails",
          "CQRS pattern implementation",
          "Docker/K8s deployment",
          "Redis caching layer",
          "GraphQL API gateway"
        ],
        year: 2023,
        ascii_thumbnail: [
          "╭──────────────────────╮",
          "│ ╭───╮  ╭───╮  ╭───╮ │",
          "│ │API│  │DB │  │SVC│ │",
          "│ ╰─▓─╯  ╰─▓─╯  ╰─▓─╯ │",
          "│   ║      ║      ║   │",
          "│   ╚══════╬══════╝   │",
          "│       ░▒▓▒░         │",
          "│     Event Bus       │",
          "│       ░▒▓▒░         │",
          "│   ╭──────────────╮  │",
          "│   │ ▓▓ Cache ░░  │  │",
          "│   │ -70% latency │  │",
          "╰───╰──────────────╯──╯"
        ]
      }
    ]
  end

  @doc """
  Gets a project by ID
  """
  @spec get(atom()) :: t() | nil
  def get(id) do
    Enum.find(all(), &(&1.id == id))
  end

  @doc """
  Returns active projects only
  """
  @spec active() :: list(t())
  def active do
    all()
    |> Enum.filter(&(&1.status == :active))
  end

  @doc """
  Returns projects with live demos
  """
  @spec with_live_demos() :: list(t())
  def with_live_demos do
    all()
    |> Enum.filter(&(&1.live_demo == true))
  end

  @doc """
  Filters projects by tech stack
  """
  @spec filter_by_tech(String.t()) :: list(t())
  def filter_by_tech(tech) do
    tech_lower = String.downcase(tech)

    all()
    |> Enum.filter(fn project ->
      Enum.any?(project.tech_stack, fn stack_item ->
        String.downcase(stack_item) == tech_lower
      end)
    end)
  end

  @doc """
  Returns a color-coded status indicator for a project.
  Uses ASCII art and gradient characters for visual appeal.
  """
  @spec status_indicator(:active | :completed | :archived) :: String.t()
  def status_indicator(:active), do: "█ Active"
  def status_indicator(:completed), do: "▓ Done"
  def status_indicator(:archived), do: "░ Archive"

  @doc """
  Returns count of projects
  """
  @spec count() :: integer()
  def count, do: length(all())
end
