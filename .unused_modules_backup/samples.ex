defmodule Droodotfoo.Resume.Samples do
  @moduledoc """
  Sample resume data for testing and demo purposes.
  Used by the terminal's `loadresume` command.
  Matches the current ResumeData structure.
  """

  @doc """
  Returns sample resume data matching the current structure.
  """
  def sample do
    %{
      personal_info: %{
        name: "SAMPLE USER",
        title: "Senior Software Engineer",
        location: "Remote",
        timezone: "America/New_York",
        website: "https://example.com",
        languages: %{
          english: "native",
          spanish: "intermediate"
        }
      },
      summary:
        "Senior Software Engineer with 10+ years in distributed systems and real-time applications. Expert in Elixir, Phoenix, and LiveView with track record of delivering scalable solutions.",
      availability: "open_to_consulting",
      focus_areas: ["Distributed Systems", "Real-time Applications", "Event-driven Architecture"],
      experience: [
        %{
          company: "axol.io",
          position: "Senior Software Engineer",
          location: "Remote",
          employment_type: "full-time",
          start_date: "2023-01",
          end_date: "Current",
          description:
            "Building scalable distributed systems with focus on real-time collaboration features.",
          achievements: [
            "Architected and built event-driven microservices platform handling 10M+ events/day",
            "Reduced API response time by 70% through caching and query optimization",
            "Led team of 5 engineers in building real-time collaboration features",
            "Implemented comprehensive test suite achieving 95% code coverage"
          ],
          technologies: %{
            languages: ["Elixir", "JavaScript", "TypeScript"],
            frameworks: ["Phoenix", "LiveView", "React"],
            tools: ["Docker", "Kubernetes", "PostgreSQL", "Redis"]
          }
        },
        %{
          company: "TechCorp",
          position: "Staff Engineer",
          location: "San Francisco, CA",
          employment_type: "full-time",
          start_date: "2021-03",
          end_date: "2023-01",
          description:
            "Technical leadership for core platform services and infrastructure optimization.",
          achievements: [
            "Designed distributed system handling 10M+ requests/day with 99.99% uptime",
            "Mentored junior engineers and conducted code reviews for team of 12",
            "Built real-time collaboration features using Phoenix LiveView",
            "Reduced infrastructure costs by 40% through optimization and right-sizing"
          ],
          technologies: %{
            languages: ["Elixir", "Go", "Python"],
            frameworks: ["Phoenix", "Ecto"],
            tools: ["AWS", "Terraform", "Grafana", "Prometheus"]
          }
        },
        %{
          company: "FinTech Startup",
          position: "Senior Elixir Developer",
          location: "New York, NY",
          employment_type: "full-time",
          start_date: "2019-06",
          end_date: "2021-02",
          description: "Payment processing and fraud detection system development.",
          achievements: [
            "Implemented real-time payment processing system handling 1M+ transactions daily",
            "Achieved 99.9% uptime through fault-tolerant design and monitoring",
            "Built fraud detection system reducing fraudulent transactions by 80%",
            "Designed and implemented API gateway for microservices architecture"
          ],
          technologies: %{
            languages: ["Elixir", "Python"],
            frameworks: ["Phoenix", "Broadway"],
            tools: ["Kafka", "PostgreSQL", "Redis", "Docker"]
          }
        },
        %{
          company: "Digital Agency",
          position: "Full Stack Developer",
          location: "Boston, MA",
          employment_type: "full-time",
          start_date: "2017-01",
          end_date: "2019-05",
          description: "Web application development for enterprise clients.",
          achievements: [
            "Built web applications for Fortune 500 clients with strict SLA requirements",
            "Developed e-commerce platforms handling $10M+ in annual sales",
            "Created custom CMS solutions using Phoenix and React",
            "Implemented CI/CD pipelines reducing deployment time by 60%"
          ],
          technologies: %{
            languages: ["Elixir", "JavaScript"],
            frameworks: ["Phoenix", "React", "Vue.js"],
            tools: ["Git", "Jenkins", "PostgreSQL"]
          }
        },
        %{
          company: "Startup Inc",
          position: "Backend Developer",
          location: "Austin, TX",
          employment_type: "full-time",
          start_date: "2015-03",
          end_date: "2016-12",
          description: "API development and real-time communication systems.",
          achievements: [
            "Developed RESTful APIs using Elixir and Phoenix serving 100K+ daily users",
            "Built real-time chat system with presence tracking and message history",
            "Optimized database queries reducing page load time by 60%",
            "Implemented OAuth2 authentication and role-based authorization"
          ],
          technologies: %{
            languages: ["Elixir", "JavaScript"],
            frameworks: ["Phoenix"],
            tools: ["PostgreSQL", "Redis"]
          }
        }
      ],
      education: [
        %{
          institution: "State University",
          degree: "Bachelor of Science",
          field: "Computer Science",
          concentration: "Software Engineering",
          start_date: "2009-09",
          end_date: "2013-05",
          location: "Boston, MA",
          minor: "Mathematics",
          achievements: %{
            academic: [
              "Graduated Summa Cum Laude with 3.9 GPA",
              "Dean's List all semesters"
            ],
            leadership: [
              "Computer Science Club President 2012-2013",
              "Led hackathon team to first place"
            ]
          }
        }
      ],
      defense_projects: [],
      portfolio: %{
        organization: %{
          name: "sample-projects",
          url: "https://github.com/sample",
          description: "Open source tools and libraries"
        },
        projects: [
          %{
            name: "distributed-cache",
            url: "https://github.com/sample/distributed-cache",
            description: "High-performance distributed caching solution in Elixir",
            language: "Elixir",
            status: "active"
          },
          %{
            name: "realtime-dashboard",
            url: "https://github.com/sample/dashboard",
            description: "Real-time analytics dashboard using Phoenix LiveView",
            language: "Elixir",
            status: "active"
          }
        ]
      },
      certifications: [
        %{
          name: "AWS Certified Solutions Architect",
          issuer: "Amazon Web Services",
          date: "2022",
          credential_id: "AWS-SA-2022"
        },
        %{
          name: "Certified Kubernetes Administrator",
          issuer: "Cloud Native Computing Foundation",
          date: "2021",
          credential_id: "CKA-2021"
        }
      ],
      contact: %{
        email: "sample@example.com",
        website: "https://example.com",
        github: "https://github.com/sample",
        linkedin: "https://linkedin.com/in/sample",
        twitter: "https://twitter.com/sample"
      }
    }
  end

  @doc """
  Parses resume data from JSON string.
  Returns sample data if parsing fails.
  """
  def parse(json_string) when is_binary(json_string) do
    case Jason.decode(json_string, keys: :atoms) do
      {:ok, data} -> data
      {:error, _} -> sample()
    end
  end

  def parse(_), do: sample()
end
