defmodule Droodotfoo.Github.AsciiArt do
  @moduledoc """
  ASCII art rendering for GitHub data.
  Creates terminal-friendly visualizations for repositories, commits, and activity.
  """

  alias Droodotfoo.Ascii

  @doc """
  Renders GitHub logo in ASCII art.
  """
  def github_logo do
    [
      "   _____ _ _   _    _       _     ",
      "  / ____(_) | | |  | |     | |    ",
      " | |  __ _| |_| |__| |_   _| |__  ",
      " | | |_ | | __|  __  | | | | '_ \\ ",
      " | |__| | | |_| |  | | |_| | |_) |",
      "  \\_____|_|\\__|_|  |_|\\__,_|_.__/ "
    ]
  end

  @doc """
  Renders user profile display.
  """
  def render_user_profile(user, options \\ []) do
    width = Keyword.get(options, :width, 78)
    border = String.duplicate("=", width - 2)

    header = build_profile_header(user, width, border)
    bio_section = build_bio_section(user, width)
    stats_section = build_stats_section(user, width)
    details_section = build_details_section(user, width)
    footer = ["+" <> border <> "+"]

    header ++ bio_section ++ stats_section ++ details_section ++ footer
  end

  defp build_profile_header(user, width, border) do
    name_line = if user.name, do: user.name, else: user.login

    [
      "+" <> border <> "+",
      "| #{String.pad_trailing("@#{user.login} - #{name_line}", width - 4)}|",
      "+" <> border <> "+"
    ]
  end

  defp build_bio_section(user, width) do
    bio_lines = if user.bio, do: Ascii.wrap_text(user.bio, width - 6), else: []

    if Enum.any?(bio_lines) do
      ["| #{String.pad_trailing("", width - 4)}|"] ++
        Enum.map(bio_lines, fn line -> "| #{String.pad_trailing(line, width - 4)}|" end)
    else
      []
    end
  end

  defp build_stats_section(user, width) do
    [
      "| #{String.pad_trailing("", width - 4)}|",
      "| #{String.pad_trailing("Stats:", width - 4)}|",
      "| #{String.pad_trailing("  Repos: #{user.public_repos}  Followers: #{user.followers}  Following: #{user.following}", width - 4)}|"
    ]
  end

  defp build_details_section(user, width) do
    []
    |> maybe_add_location(user, width)
    |> maybe_add_company(user, width)
    |> maybe_add_blog(user, width)
  end

  defp maybe_add_location(lines, %{location: location}, width)
       when not is_nil(location) and location != "" do
    lines ++ ["| #{String.pad_trailing(" Location: #{location}", width - 4)}|"]
  end

  defp maybe_add_location(lines, _, _), do: lines

  defp maybe_add_company(lines, %{company: company}, width)
       when not is_nil(company) and company != "" do
    lines ++ ["| #{String.pad_trailing(" Company: #{company}", width - 4)}|"]
  end

  defp maybe_add_company(lines, _, _), do: lines

  defp maybe_add_blog(lines, %{blog: blog}, width) when not is_nil(blog) and blog != "" do
    lines ++ ["| #{String.pad_trailing(" Website: #{blog}", width - 4)}|"]
  end

  defp maybe_add_blog(lines, _, _), do: lines

  @doc """
  Renders repository list.
  """
  def render_repo_list(repos, options \\ []) do
    max_items = Keyword.get(options, :max_items, 10)
    width = Keyword.get(options, :width, 78)

    header = [
      "+-- Repositories " <> String.duplicate("-", width - 18) <> "+",
      "| #{String.pad_trailing("Name", 30)} #{String.pad_trailing("Stars", 8)} #{String.pad_trailing("Language", 15)} #{String.pad_trailing("Updated", 18)}|",
      "+" <> String.duplicate("-", width - 2) <> "+"
    ]

    content =
      if Enum.empty?(repos) do
        ["| #{String.pad_trailing("No repositories found", width - 4)}|"]
      else
        repos
        |> Enum.take(max_items)
        |> Enum.map(fn repo ->
          name = Ascii.truncate_text(repo.name, 28)
          stars = String.pad_leading("#{repo.stargazers_count}", 6)
          lang = Ascii.truncate_text(repo.language || "N/A", 13)
          updated = format_relative_time(repo.updated_at)

          "| #{String.pad_trailing(name, 30)} #{String.pad_trailing(stars, 8)} #{String.pad_trailing(lang, 15)} #{String.pad_trailing(updated, 18)}|"
        end)
      end

    footer = [
      "+" <> String.duplicate("-", width - 2) <> "+"
    ]

    header ++ content ++ footer
  end

  @doc """
  Renders repository details.
  """
  def render_repo_details(repo, options \\ []) do
    width = Keyword.get(options, :width, 78)
    border = String.duplicate("=", width - 2)

    desc_lines =
      if repo.description,
        do: Ascii.wrap_text(repo.description, width - 6),
        else: ["No description"]

    stars = Ascii.format_number(repo.stargazers_count)
    forks = Ascii.format_number(repo.forks_count)
    watchers = Ascii.format_number(repo.watchers_count)
    issues = Ascii.format_number(repo.open_issues_count)

    [
      "+" <> border <> "+",
      "| #{String.pad_trailing(repo.full_name, width - 4)}|",
      "+" <> border <> "+",
      "| #{String.pad_trailing("", width - 4)}|"
    ] ++
      Enum.map(desc_lines, fn line -> "| #{String.pad_trailing(line, width - 4)}|" end) ++
      [
        "| #{String.pad_trailing("", width - 4)}|",
        "| #{String.pad_trailing("Language: #{repo.language || "N/A"}", width - 4)}|",
        "| #{String.pad_trailing("Stars: #{stars}  Forks: #{forks}  Watchers: #{watchers}  Issues: #{issues}", width - 4)}|",
        "| #{String.pad_trailing("", width - 4)}|",
        "| #{String.pad_trailing("URL: #{repo.html_url}", width - 4)}|",
        "+" <> border <> "+"
      ]
  end

  @doc """
  Renders commit history.
  """
  def render_commits(commits, options \\ []) do
    max_items = Keyword.get(options, :max_items, 15)
    width = Keyword.get(options, :width, 78)

    header = [
      "+-- Recent Commits " <> String.duplicate("-", width - 20) <> "+"
    ]

    content =
      if Enum.empty?(commits) do
        ["| #{String.pad_trailing("No commits found", width - 4)}|"]
      else
        commits
        |> Enum.take(max_items)
        |> Enum.flat_map(&format_commit_lines(&1, width))
      end

    footer = [
      "+" <> String.duplicate("-", width - 2) <> "+"
    ]

    header ++ content ++ footer
  end

  @doc """
  Renders user activity feed.
  """
  def render_activity(events, options \\ []) do
    max_items = Keyword.get(options, :max_items, 15)
    width = Keyword.get(options, :width, 78)

    header = [
      "+-- Recent Activity " <> String.duplicate("-", width - 21) <> "+"
    ]

    content =
      if Enum.empty?(events) do
        ["| #{String.pad_trailing("No recent activity", width - 4)}|"]
      else
        events
        |> Enum.take(max_items)
        |> Enum.map(fn event ->
          icon = event_icon(event.type)
          action = event_action(event.type, event.payload)
          repo = Ascii.truncate_text(event.repo.name, 35)
          time = format_relative_time(event.created_at)

          "| #{icon} #{String.pad_trailing(action, 15)} #{String.pad_trailing(repo, 37)} #{String.pad_trailing(time, 10)}|"
        end)
      end

    footer = [
      "+" <> String.duplicate("-", width - 2) <> "+"
    ]

    header ++ content ++ footer
  end

  @doc """
  Renders issue/PR list.
  """
  def render_issues(items, type \\ :issue, options \\ []) do
    max_items = Keyword.get(options, :max_items, 15)
    width = Keyword.get(options, :width, 78)

    title = if type == :pull, do: "Pull Requests", else: "Issues"

    header = [
      "+-- #{title} " <> String.duplicate("-", width - String.length(title) - 6) <> "+"
    ]

    content =
      if Enum.empty?(items) do
        ["| #{String.pad_trailing("No #{String.downcase(title)} found", width - 4)}|"]
      else
        items
        |> Enum.take(max_items)
        |> Enum.map(&format_issue_line(&1, width))
      end

    footer = [
      "+" <> String.duplicate("-", width - 2) <> "+"
    ]

    header ++ content ++ footer
  end

  # Private Functions

  defp event_icon(type) do
    event_icon_map()[type] || "•"
  end

  defp event_icon_map do
    %{
      "PushEvent" => "→",
      "PullRequestEvent" => "⇄",
      "IssuesEvent" => "◉",
      "CreateEvent" => "+",
      "DeleteEvent" => "-",
      "ForkEvent" => "⑂",
      "WatchEvent" => "★",
      "ReleaseEvent" => "↑"
    }
  end

  defp event_action("PushEvent", payload) do
    count = length(payload["commits"] || [])
    "pushed #{count} commit#{if count != 1, do: "s", else: ""}"
  end

  defp event_action("PullRequestEvent", payload), do: "#{payload["action"]} PR"
  defp event_action("IssuesEvent", payload), do: "#{payload["action"]} issue"
  defp event_action("CreateEvent", payload), do: "created #{payload["ref_type"]}"
  defp event_action("DeleteEvent", payload), do: "deleted #{payload["ref_type"]}"
  defp event_action("ForkEvent", _), do: "forked"
  defp event_action("WatchEvent", _), do: "starred"
  defp event_action("ReleaseEvent", _), do: "released"
  defp event_action(type, _), do: type

  defp format_relative_time(datetime_string) when is_binary(datetime_string) do
    case DateTime.from_iso8601(datetime_string) do
      {:ok, dt, _} ->
        diff_seconds = DateTime.diff(DateTime.utc_now(), dt)
        Ascii.format_relative_time(diff_seconds)

      _ ->
        "unknown"
    end
  end

  defp format_relative_time(_), do: "unknown"

  defp format_commit_lines(commit, width) do
    sha_short = String.slice(commit.sha, 0..6)
    author = Ascii.truncate_text(commit.author.name, 20)
    date = format_relative_time(commit.author.date)
    message_lines = Ascii.wrap_text(commit.message, width - 8)

    [
      "| #{sha_short} #{String.pad_trailing(author, 22)} #{String.pad_trailing(date, width - 36)}|"
    ] ++ Enum.map(message_lines, &format_message_line(&1, width))
  end

  defp format_message_line(line, width) do
    "| #{String.pad_trailing("  " <> line, width - 4)}|"
  end

  defp format_issue_line(item, width) do
    num = "##{item.number}"
    state_icon = if item.state == "open", do: "○", else: "●"
    title_text = Ascii.truncate_text(item.title, width - 20)
    author = "@#{item.user.login}"

    "| #{state_icon} #{String.pad_trailing(num, 6)} #{String.pad_trailing(title_text, width - 25)} #{String.pad_trailing(author, 12)}|"
  end
end
