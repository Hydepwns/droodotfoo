defmodule Droodotfoo.Features.ResumeExporter do
  @moduledoc """
  Export resume data in various formats.
  """

  def export_markdown do
    """
    # Droo - Senior Software Engineer

    **Email:** drew@axol.io
    **GitHub:** github.com/hydepwns
    **LinkedIn:** linkedin.com/in/drew-hiro
    **Twitter:** @MF_DROO

    ## Summary

    Senior Software Engineer with expertise in distributed systems and real-time applications.
    8+ years building scalable platforms with Elixir, Phoenix, and LiveView.
    Terminal UI and CLI enthusiast.

    ## Technical Skills

    ### Languages
    - **Elixir** (90%) - Primary expertise
    - **Phoenix** (85%) - Web framework
    - **JavaScript** (75%) - Frontend development
    - **TypeScript** (70%) - Type-safe JS

    ### Frameworks & Libraries
    - Phoenix, LiveView, Ecto, Broadway
    - React, Vue.js, Node.js, Express
    - GraphQL, REST APIs, WebSockets

    ### Infrastructure
    - Docker, Kubernetes, AWS, Fly.io
    - PostgreSQL, Redis, Kafka, ClickHouse

    ## Experience

    ### Senior Backend Engineer
    **Scale-up SaaS** | 2021 - Present
    - Built event-driven microservices architecture
    - Reduced API response time by 70%
    - Led team initiatives for system optimization

    ### Elixir Developer
    **FinTech Startup** | 2019 - 2021
    - Designed real-time payment processing system
    - Handled 1M+ transactions daily
    - Implemented fault-tolerant distributed systems

    ### Full Stack Developer
    **Digital Agency** | 2017 - 2019
    - Developed client web applications
    - Worked with modern JavaScript frameworks
    - Delivered projects on time and budget

    ## Projects

    ### Terminal droo.foo System
    This droo.foo! Built with Raxol terminal UI framework.
    Technologies: Elixir, Phoenix, LiveView, 60fps rendering

    ### Real-time Collaboration Platform
    WebRTC-based pair programming tool for remote teams.
    Technologies: Elixir, Phoenix Channels, WebRTC

    ### Distributed Event Processing
    High-throughput event stream processor handling millions of events.
    Technologies: Elixir, Broadway, Kafka, ClickHouse

    ## Recent Activity

    - **2025-09:** Building terminal droo.foo with Raxol + Phoenix LiveView
    - **2025-08:** Optimized real-time data pipeline
    - **2025-07:** Open sourced Elixir telemetry library

    ---
    *Generated from droo.foo terminal*
    """
  end

  def export_json do
    %{
      name: "Droo",
      title: "Senior Software Engineer",
      contact: %{
        email: "drew@axol.io",
        github: "github.com/hydepwns",
        linkedin: "linkedin.com/in/drew-hiro",
        twitter: "@MF_DROO"
      },
      summary: "Senior Software Engineer with expertise in distributed systems...",
      skills: %{
        languages: [
          %{name: "Elixir", proficiency: 90},
          %{name: "Phoenix", proficiency: 85},
          %{name: "JavaScript", proficiency: 75},
          %{name: "TypeScript", proficiency: 70}
        ],
        frameworks: [
          "Phoenix",
          "LiveView",
          "Ecto",
          "Broadway",
          "React",
          "Vue.js",
          "Node.js",
          "Express"
        ],
        infrastructure: [
          "Docker",
          "Kubernetes",
          "AWS",
          "Fly.io",
          "PostgreSQL",
          "Redis",
          "Kafka"
        ]
      },
      experience: [
        %{
          title: "Senior Backend Engineer",
          company: "Scale-up SaaS",
          period: "2021 - Present",
          achievements: [
            "Built event-driven microservices",
            "Reduced API response time by 70%"
          ]
        },
        %{
          title: "Elixir Developer",
          company: "FinTech Startup",
          period: "2019 - 2021",
          achievements: [
            "Designed real-time payment processing",
            "Handled 1M+ transactions daily"
          ]
        }
      ],
      projects: [
        %{
          name: "Terminal droo.foo System",
          description: "Interactive terminal droo.foo",
          technologies: ["Elixir", "Phoenix", "LiveView"]
        },
        %{
          name: "Real-time Collaboration Platform",
          description: "WebRTC pair programming tool",
          technologies: ["Elixir", "Phoenix Channels", "WebRTC"]
        }
      ]
    }
    |> Jason.encode!(pretty: true)
  end

  def export_text do
    """
    ================================================================================
                                      RESUME
    ================================================================================

    DROO
    Senior Software Engineer

    Contact:
    - Email: drew@axol.io
    - GitHub: github.com/hydepwns
    - LinkedIn: linkedin.com/in/drew-hiro
    - Twitter: @MF_DROO

    --------------------------------------------------------------------------------
    SUMMARY
    --------------------------------------------------------------------------------
    Senior Software Engineer with expertise in distributed systems and real-time
    applications. 8+ years building scalable platforms with Elixir, Phoenix, and
    LiveView. Terminal UI and CLI enthusiast.

    --------------------------------------------------------------------------------
    TECHNICAL SKILLS
    --------------------------------------------------------------------------------
    Languages:     Elixir (90%), Phoenix (85%), JavaScript (75%), TypeScript (70%)
    Frameworks:    Phoenix, LiveView, Ecto, Broadway, React, Vue.js, Node.js
    Infrastructure: Docker, Kubernetes, AWS, Fly.io, PostgreSQL, Redis, Kafka

    --------------------------------------------------------------------------------
    EXPERIENCE
    --------------------------------------------------------------------------------
    Senior Backend Engineer | Scale-up SaaS | 2021 - Present
    - Built event-driven microservices architecture
    - Reduced API response time by 70%

    Elixir Developer | FinTech Startup | 2019 - 2021
    - Designed real-time payment processing system
    - Handled 1M+ transactions daily

    Full Stack Developer | Digital Agency | 2017 - 2019
    - Developed client web applications
    - Delivered projects on time and budget

    --------------------------------------------------------------------------------
    PROJECTS
    --------------------------------------------------------------------------------
    * Terminal droo.foo System - Interactive terminal UI droo.foo
    * Real-time Collaboration Platform - WebRTC pair programming tool
    * Distributed Event Processing - High-throughput event processor

    ================================================================================
    Generated from droo.foo terminal
    ================================================================================
    """
  end
end
