defmodule DroodotfooWeb.SEO.JsonLD do
  @moduledoc """
  Generates JSON-LD structured data for SEO.
  Implements schema.org specifications for various content types.
  """

  @doc """
  Generates Person schema for the site owner.
  """
  def person_schema do
    %{
      "@context" => "https://schema.org",
      "@type" => "Person",
      "name" => "DROO",
      "url" => "https://droo.foo",
      "image" => "https://droo.foo/images/og-image.png",
      "sameAs" => [
        "https://github.com/Hydepwns",
        "https://twitter.com/MF_DROO",
        "https://www.linkedin.com/in/drewahyde"
      ],
      "jobTitle" => "Blockchain Infrastructure Engineer",
      "worksFor" => %{
        "@type" => "Organization",
        "name" => "axol.io",
        "url" => "https://github.com/axol-io"
      },
      "description" =>
        "Engineer building his Gundam - Building blockchain infrastructure and production-grade FOSS tooling for Cosmos and EVM ecosystems",
      "knowsAbout" => [
        "Blockchain",
        "Elixir",
        "Ethereum",
        "Phoenix Framework",
        "Web3",
        "Distributed Systems"
      ]
    }
    |> Jason.encode!()
  end

  @doc """
  Generates WebSite schema for the homepage.
  """
  def website_schema do
    %{
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => "DROO.FOO",
      "url" => "https://droo.foo",
      "description" =>
        "Engineer building his Gundam - Blockchain infrastructure and production-grade FOSS tooling",
      "author" => %{
        "@type" => "Person",
        "name" => "DROO"
      },
      "inLanguage" => "en-US"
    }
    |> Jason.encode!()
  end

  @doc """
  Generates Article schema for blog posts.
  """
  def article_schema(post) do
    %{
      "@context" => "https://schema.org",
      "@type" => "Article",
      "headline" => post.title,
      "description" => post.description,
      "image" => "https://droo.foo#{Droodotfoo.Content.Posts.social_image_url(post)}",
      "datePublished" => format_date(post.date),
      "dateModified" => format_date(post.modified_time || post.date),
      "author" => %{
        "@type" => "Person",
        "name" => "DROO",
        "url" => "https://droo.foo"
      },
      "publisher" => %{
        "@type" => "Person",
        "name" => "DROO",
        "url" => "https://droo.foo"
      },
      "mainEntityOfPage" => %{
        "@type" => "WebPage",
        "@id" => "https://droo.foo/posts/#{post.slug}"
      },
      "keywords" => Enum.join(post.tags, ", "),
      "articleSection" => List.first(post.tags),
      "inLanguage" => "en-US"
    }
    |> maybe_add_series(post)
    |> Jason.encode!()
  end

  @doc """
  Generates SoftwareSourceCode schema for projects.
  """
  def software_schema(project) do
    schema =
      %{
        "@context" => "https://schema.org",
        "@type" => "SoftwareSourceCode",
        "name" => project.name,
        "description" => project.description,
        "programmingLanguage" => project.tech_stack |> List.first(),
        "codeRepository" => project.github_url,
        "author" => %{
          "@type" => "Person",
          "name" => "DROO",
          "url" => "https://droo.foo"
        },
        "keywords" => Enum.join(project.topics, ", ")
      }
      |> maybe_add_github_data(project)

    Jason.encode!(schema)
  end

  @doc """
  Generates BreadcrumbList schema for navigation.
  """
  def breadcrumb_schema(items) do
    %{
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" =>
        items
        |> Enum.with_index(1)
        |> Enum.map(fn {{name, url}, position} ->
          %{
            "@type" => "ListItem",
            "position" => position,
            "name" => name,
            "item" => "https://droo.foo#{url}"
          }
        end)
    }
    |> Jason.encode!()
  end

  @doc """
  Generates Organization schema for axol.io.
  """
  def organization_schema do
    %{
      "@context" => "https://schema.org",
      "@type" => "Organization",
      "name" => "axol.io",
      "url" => "https://github.com/axol-io",
      "description" => "Open source blockchain infrastructure and tooling",
      "member" => %{
        "@type" => "Person",
        "name" => "DROO",
        "url" => "https://droo.foo"
      }
    }
    |> Jason.encode!()
  end

  # Private helpers

  defp format_date(%Date{} = date) do
    Date.to_iso8601(date) <> "T00:00:00Z"
  end

  defp format_date(nil), do: nil

  defp maybe_add_series(schema, %{series: series} = post) when not is_nil(series) do
    Map.put(schema, "isPartOf", %{
      "@type" => "CreativeWorkSeries",
      "name" => series,
      "position" => post.series_order || 1
    })
  end

  defp maybe_add_series(schema, _post), do: schema

  defp maybe_add_github_data(schema, %{github_data: github_data})
       when not is_nil(github_data) do
    case github_data do
      %{status: :ok, repo_info: repo_info} when not is_nil(repo_info) ->
        schema
        |> Map.put("interactionStatistic", [
          %{
            "@type" => "InteractionCounter",
            "interactionType" => "https://schema.org/LikeAction",
            "userInteractionCount" => repo_info.stars || 0
          },
          %{
            "@type" => "InteractionCounter",
            "interactionType" => "https://schema.org/ShareAction",
            "userInteractionCount" => repo_info.forks || 0
          }
        ])
        |> maybe_add_date_modified(repo_info)

      _ ->
        schema
    end
  end

  defp maybe_add_github_data(schema, _project), do: schema

  defp maybe_add_date_modified(schema, %{updated_at: updated_at})
       when not is_nil(updated_at) do
    Map.put(schema, "dateModified", updated_at)
  end

  defp maybe_add_date_modified(schema, _repo_info), do: schema
end
