defmodule Droodotfoo.Resume.ResumeData do
  @moduledoc """
  Resume data structure and content management.
  """

  defstruct [
    :personal_info,
    :summary,
    :experience,
    :education,
    :skills,
    :projects,
    :certifications,
    :contact
  ]

  @type t :: %__MODULE__{
          personal_info: map(),
          summary: String.t(),
          experience: list(map()),
          education: list(map()),
          skills: list(map()),
          projects: list(map()),
          certifications: list(map()),
          contact: map()
        }

  def get_resume_data do
    %__MODULE__{
      personal_info: %{
        name: "DROO AMOR",
        title: "Blockchain Researcher & R&D Engineer",
        location: "Remote",
        website: "https://droo.foo"
      },
      summary: """
      Blockchain researcher and R&D engineer, previously with several years of
      experience as a multidisciplinary engineer in the defense industry
      building nuclear submarines. My motivation is to take ownership in an
      environment that empowers and rewards initiative. I look forward to
      seeking out technical challenges and affecting meaningful change to grow
      as an engineer and technical advisor.
      """,
      experience: [
        %{
          company: "axol.io",
          position: "Founder & Developer",
          location: "Remote",
          start_date: "2024",
          end_date: "Present",
          description: """
          • Lead architecture, product, and engineering for axol.io
          • Build real-time systems, distributed services, and developer tooling
          • Ship production Elixir/Phoenix services with strict reliability targets
          """,
          technologies: [
            "Elixir",
            "Phoenix",
            "LiveView",
            "PostgreSQL",
            "WebRTC",
            "Rust",
            "Terraform",
            "Docker"
          ]
        },
        %{
          company: "Blockdaemon",
          position: "R&D Protocol Research Specialist",
          location: "Remote",
          start_date: "January 2022",
          end_date: "Present",
          description: """
          • Blockdaemon is one of the top blockchain infrastructure companies that provides "nodes-as-a-service"
          • Code analysis and prototype deployment to evaluate blockchain project software infrastructure requirements
          • Examining JavaScript, Rust, and Go code repositories for code quality
          • Running & troubleshooting node infrastructure and monitoring network performance
          • Economic & Tokenomic analysis of blockchain projects for determining product feasibility and profitability
          • Engineering and Product Consulting for onboarding new blockchain protocols with Ansible, Terraform, Docker, Grafana, & Prometheus
          • Governance: Internal strategy and voting, and development of voting scripts using Authz module in Cosmos SDK
          """,
          technologies: [
            "JavaScript",
            "Rust",
            "Go",
            "Ansible",
            "Terraform",
            "Docker",
            "Grafana",
            "Prometheus",
            "Cosmos SDK"
          ]
        },
        %{
          company: "General Dynamics Electric Boat",
          position: "Mechanical & Electrical Test Engineering",
          location: "Groton, CT",
          start_date: "October 2020",
          end_date: "Present",
          description: """
          • Engineering Lead of JTG HM&E Engineering for $9bn+ of nuclear submarine PSA projects
          • Provided engineering consultation and troubleshooting that expedited engineering products deliveries by 11% compared to previous PSA projects
          • Program Management & QA of underway Sea Trials for leading testing & sales/certification process
          • Risk management: Handle high-risk re-entry controls, roadmap and product liability tracking for PSA & NEWCON nuclear submarines
          """,
          technologies: [
            "MATLAB",
            "Git",
            "MRPII",
            "ELCADD",
            "LabView",
            "AutoCAD",
            "Figma",
            "Teamcenter",
            "Trello"
          ]
        },
        %{
          company: "General Dynamics Electric Boat",
          position: "R&D Engineering",
          location: "Groton, CT",
          start_date: "December 2018",
          end_date: "November 2020",
          description: """
          • Technical Lead for cross-department design/develop, manufacture, and test of rapid prototyping inventions (Mech/Elec)
          • Project Management of 5-10 person teams, managing budgeting (up to $15m monthly per project) and materials
          • Calibration and repair process, saving ~$20mm of mechanical and electrical precision instruments replacement costs
          • Mechanical/Electrical invention for expediting submarine tactical weapon launch by 14%
          • Tools & Assembly for remote welding assembly to reduce manhours spent in radioactive zone by 34%
          """,
          technologies: [
            "MATLAB",
            "Git",
            "MRPII",
            "ELCADD",
            "LabView",
            "AutoCAD",
            "Figma",
            "Teamcenter",
            "Trello"
          ]
        },
        %{
          company: "General Dynamics Electric Boat",
          position: "Shipyard Test Organization Specialist",
          location: "Groton, CT",
          start_date: "June 2017",
          end_date: "December 2018",
          description: """
          • Field engineering and troubleshooting of mechanical and electrical submarine systems, material strength, and operation
          • Quality Assurance & Quality Control of Classified, NOFORN, DSS-SOC, and SUBSAFE systems
          • Operational Program Leadership and relationships between US Navy customer, private vendors, and shipyard personnel
          • Conducted hydrostatic tests, Lockout/Tag-out, shipboard troubleshooting, high-risk operations, and material strength tests
          """,
          technologies: [
            "Quality Assurance",
            "Quality Control",
            "Hydrostatic Testing",
            "Lockout/Tag-out",
            "Material Testing"
          ]
        }
      ],
      education: [
        %{
          institution: "SUNY Maritime College",
          degree: "Bachelor of Science",
          field: "Marine Operations, Concentration in Engineering",
          year: "2013-2017",
          location: "Bronx, NYC",
          minor: "Pre-law & Management",
          achievements: [
            "Licensed USCG Deck Officer, Third Mates Unlimited Tonnage Program",
            "SGA & Student Body Vice President 2013",
            "SGA & Student Body Secretary 2012",
            "Maritime Pre-Law Society Co-founder",
            "Tutor & Coach for all Navigation and Seamanship classes during tenure",
            "All-American Skipper/Crew for Competitive Dinghy and Offshore Sailing"
          ]
        }
      ],
      skills: [
        %{
          category: "Programming Languages",
          items: ["JavaScript", "Rust", "Go", "MATLAB", "Python"]
        },
        %{
          category: "Blockchain & Web3",
          items: [
            "Cosmos SDK",
            "Authz Module",
            "Tokenomics",
            "Node Infrastructure",
            "Protocol Research"
          ]
        },
        %{
          category: "Infrastructure & DevOps",
          items: ["Ansible", "Terraform", "Docker", "Grafana", "Prometheus", "Git", "CI/CD"]
        },
        %{
          category: "Engineering Tools",
          items: [
            "MATLAB",
            "LabView",
            "AutoCAD",
            "Figma",
            "Teamcenter",
            "Trello",
            "MRPII",
            "ELCADD"
          ]
        },
        %{
          category: "Project Management",
          items: [
            "Team Leadership",
            "Budget Management",
            "Risk Management",
            "Quality Assurance",
            "Process Optimization"
          ]
        },
        %{
          category: "Maritime & Defense",
          items: [
            "USCG License",
            "Nuclear Submarine Systems",
            "Hydrostatic Testing",
            "Lockout/Tag-out",
            "Material Testing"
          ]
        }
      ],
      projects: [
        %{
          name: "SCRT Network",
          description:
            "Secret Agent – DeveloperDAO project focused on decentralized privacy and blockchain infrastructure",
          technologies: ["Blockchain", "Privacy", "Decentralized Networks"],
          url: "https://scrt.network",
          status: "Active",
          role: "Developer"
        },
        %{
          name: "Hiro LaunchDAO",
          description:
            "Co-founder & Operations Lead of a decentralized venture funding platform built on Solana. Led a team of five developers in two hackathons pre-seed funding to bring novel approaches to decentralized decision making within DAOs, backed by c-suite advisors.",
          technologies: [
            "Solana",
            "DAO Governance",
            "Venture Funding",
            "Decentralized Decision Making"
          ],
          url: "https://hiro.xyz",
          status: "Completed",
          role: "Co-founder & Operations Lead"
        },
        %{
          name: "Nuclear Submarine Tactical Systems",
          description:
            "Mechanical/Electrical invention for expediting submarine tactical weapon launch by 14% (direct timing classified). Tools & Assembly for remote welding assembly to reduce manhours spent in radioactive zone by 34%.",
          technologies: [
            "Mechanical Engineering",
            "Electrical Engineering",
            "Nuclear Systems",
            "Precision Manufacturing"
          ],
          url: "Classified",
          status: "Completed",
          role: "Technical Lead"
        },
        %{
          name: "Precision Instrument Calibration System",
          description:
            "Calibration and repair process, saving ~$20mm of mechanical and electrical precision instruments replacement costs through innovative maintenance protocols.",
          technologies: [
            "Precision Calibration",
            "Cost Optimization",
            "Maintenance Protocols",
            "Quality Control"
          ],
          url: "Proprietary",
          status: "Completed",
          role: "R&D Engineer"
        }
      ],
      certifications: [
        %{
          name: "USGOV (R) Classified Secret Security Clearance",
          issuer: "United States Government",
          date: "Active",
          credential_id: "SECRET-CLEARANCE"
        },
        %{
          name: "Steam & Electric Plant S9G Reactor Qualified",
          issuer: "US Navy Nuclear Program",
          date: "Active",
          credential_id: "S9G-REACTOR-QUALIFIED"
        },
        %{
          name: "USCG Third Mate Unlimited Tonnage License",
          issuer: "United States Coast Guard",
          date: "Active",
          credential_id: "USCG-3RD-MATE-UNLIMITED"
        }
      ],
      contact: %{
        email: "drew@axol.io",
        website: "https://droo.foo",
        github: "https://github.com/hydepwns",
        linkedin: "https://linkedin.com/in/drew-hiro",
        twitter: "https://twitter.com/MF_DROO"
      }
    }
  end

  def get_resume_formats do
    [
      %{
        id: "technical",
        name: "Technical Resume",
        description: "Developer-focused format with emphasis on technical skills and projects"
      },
      %{
        id: "executive",
        name: "Executive Summary",
        description: "High-level overview suitable for leadership positions"
      },
      %{
        id: "minimal",
        name: "Minimal Resume",
        description: "Clean, concise format for quick scanning"
      },
      %{
        id: "detailed",
        name: "Detailed Resume",
        description: "Comprehensive format with full project descriptions"
      }
    ]
  end
end
