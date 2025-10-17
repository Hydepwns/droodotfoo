defmodule Droodotfoo.Terminal.Commands.DrooFoo do
  @moduledoc """
  Droo.foo specific command implementations for the terminal.

  Provides commands for:
  - Personal information: skills, contact, resume
  - Projects: projects, project (with details)
  - Content: charts, download
  - API integration: api status
  - Resume export: resume_export, resume_formats, resume_preview
  - Contact form: contact_form, contact_status
  """

  alias Droodotfoo.Contact.RateLimiter
  alias Droodotfoo.Github.Client, as: GithubClient
  alias Droodotfoo.Terminal.Commands.FileOps

  # Personal Information

  @doc """
  Display technical skills and capabilities.
  """
  def skills([], _state) do
    {:ok,
     """
     Technical Skills
     ================

     Languages:
       Expert: Elixir, JavaScript, Python, Rust
       Proficient: Go, Ruby, Java, C++

     Frameworks:
       Backend: Phoenix, Node.js, FastAPI, Actix
       Frontend: React, Vue, Svelte, LiveView

     Databases:
       SQL: PostgreSQL, MySQL, SQLite
       NoSQL: Redis, MongoDB, Cassandra

     Tools & Platforms:
       Cloud: AWS, GCP, Azure
       DevOps: Docker, Kubernetes, Terraform
       CI/CD: GitHub Actions, GitLab CI, Jenkins

     Type 'cat skills/<category>.txt' for detailed info.
     """}
  end

  @doc """
  Display resume from resume.txt file.
  """
  def resume([], state) do
    # Delegate to FileOps.cat
    FileOps.cat(["resume.txt"], state)
  end

  @doc """
  Display contact information.
  """
  def contact([], _state) do
    {:ok,
     """
     Contact Information
     ===================

     Email:    drew@axol.io
     GitHub:   https://github.com/hydepwns
     LinkedIn: https://linkedin.com/in/drew-hiro
     Twitter:  @MF_DROO

     Feel free to reach out for:
     - Job opportunities
     - Open source collaboration
     - Technical discussions
     - Coffee chat

     PGP Key available at: https://droo.foo/pgp
     """}
  end

  @doc """
  Download resume PDF (simulated).
  """
  def download(["resume.pdf"], _state) do
    {:ok,
     """
     Downloading resume.pdf...

     [============================] 100%

     Downloaded: resume.pdf (142 KB)

     Note: In a real terminal, this would trigger a file download.
     Visit https://droo.foo/resume.pdf to download.
     """}
  end

  def download([], state) do
    download(["resume.pdf"], state)
  end

  # Projects

  @doc """
  Fetch and display pinned GitHub repositories.
  """
  def projects([], _state) do
    result =
      case GithubClient.fetch_pinned_repos("hydepwns") do
        {:ok, repos} -> GithubClient.format_repos(repos)
        {:error, _reason} = error -> GithubClient.format_repos(error)
      end

    {:ok, result}
  end

  @doc """
  Navigate to projects section or view specific project.
  """
  def project([], state) do
    {:ok, "Navigating to projects...", %{state | current_section: :projects}}
  end

  def project([project_name], state) do
    projects = Droodotfoo.Projects.all()

    matching_project =
      Enum.find_index(projects, fn p ->
        String.downcase(p.name) =~ String.downcase(project_name) or
          Atom.to_string(p.id) == String.downcase(project_name)
      end)

    case matching_project do
      nil ->
        {:error, "Project not found: #{project_name}"}

      idx ->
        {:ok, "Opening project: #{Enum.at(projects, idx).name}",
         %{
           state
           | current_section: :projects,
             selected_project_index: idx,
             project_detail_view: true
         }}
    end
  end

  @doc """
  Display ASCII chart showcase.
  """
  def charts(_state) do
    output =
      Droodotfoo.AsciiChart.showcase()
      |> Enum.join("\n")

    {:ok, output}
  end

  # API Integration

  @doc """
  Display API status and available endpoints.
  """
  def api(["status"], _state) do
    {:ok,
     """
     API Status: Online

     Endpoints:
       GET  /api/projects     - List all projects
       GET  /api/skills       - Get skills data
       GET  /api/resume       - Resume in JSON format
       POST /api/contact      - Send a message
       GET  /api/stats        - Visitor statistics

     Base URL: https://droo.foo/api
     Docs: https://droo.foo/api/docs
     """}
  end

  # Resume Export

  @doc """
  Display resume export options.
  """
  def resume_export(_args, _state) do
    output = """
    ┌─ Resume Export ─────────────────────────────────────────────────────────┐
    │                                                                       │
    │  /resume                                                              │
    │                                                                       │
    │  :resume_formats                                                      │
    │  :resume_preview <format>                                             │
    │                                                                       │
    └───────────────────────────────────────────────────────────────────────┘
    """

    {:ok, output}
  end

  @doc """
  Display available resume formats.
  """
  def resume_formats(_args, _state) do
    output = """
    ┌─ Resume Formats ───────────────────────────────────────────────────────┐
    │                                                                       │
    │  Available Formats:                                                   │
    │                                                                       │
    │  • technical  - Developer-focused with technical skills emphasis     │
    │  • executive - High-level overview for leadership positions          │
    │  • minimal   - Clean, concise format for quick scanning             │
    │  • detailed  - Comprehensive format with full descriptions           │
    │                                                                       │
    │  Usage: :resume_preview <format>                                     │
    │                                                                       │
    └───────────────────────────────────────────────────────────────────────┘
    """

    {:ok, output}
  end

  @doc """
  Preview resume in specified format.
  """
  def resume_preview(args, _state) do
    format =
      case args do
        [format] when format in ["technical", "executive", "minimal", "detailed"] -> format
        _ -> "technical"
      end

    output = """
    ┌─ Resume Preview: #{String.upcase(format)} ───────────────────────────────────────┐
    │                                                                       │
    │  Opening resume preview in browser...                                │
    │                                                                       │
    │  Format: #{format}                                                    │
    │  URL: /resume                                                        │
    │                                                                       │
    │  Features:                                                           │
    │  • Real-time preview                                                  │
    │  • Multiple format options                                           │
    │  • PDF generation                                                    │
    │  • Instant download                                                  │
    │                                                                       │
    └───────────────────────────────────────────────────────────────────────┘
    """

    {:ok, output}
  end

  # Contact Form

  @doc """
  Display contact form information.
  """
  def contact_form(_args, _state) do
    output = """
    ┌─ Contact ───────────────────────────────────────────────────────────┐
    │                                                                   │
    │  /contact                                                         │
    │                                                                   │
    │  :contact_status                                                  │
    │                                                                   │
    └─────────────────────────────────────────────────────────────────────┘
    """

    {:ok, output}
  end

  @doc """
  Display contact form rate limiting status.
  """
  def contact_status(_args, _state) do
    case RateLimiter.get_status("127.0.0.1") do
      {:ok, status} ->
        output = """
        ┌─ Contact Status ────────────────────────────────────────────────────┐
        │                                                                   │
        │  Rate: #{status.hourly_submissions}/#{status.hourly_limit}h, #{status.daily_submissions}/#{status.daily_limit}d  │
        │  Status: #{if status.can_submit, do: "OK", else: "RATE_LIMITED"}  │
        │  Email: #{DateTime.utc_now() |> DateTime.to_string()}             │
        │                                                                   │
        └─────────────────────────────────────────────────────────────────────┘
        """

        {:ok, output}

      {:error, reason} ->
        {:error, "Failed to get contact form status: #{reason}"}
    end
  end
end
