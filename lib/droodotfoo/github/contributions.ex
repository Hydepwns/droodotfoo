defmodule Droodotfoo.GitHub.Contributions do
  @moduledoc """
  Fetches GitHub contribution data.
  GraphQL primary (full year with levels), REST Events fallback (recent activity).
  Returns flat day lists -- grid layout is a view concern handled by GithubComponents.
  """

  require Logger

  alias Droodotfoo.GitHub.{Cache, HttpClient}

  @topic "contributions"

  @username "Hydepwns"
  @cache_key {:contributions, @username}
  @cache_ttl :timer.hours(4)
  @rest_max_pages 10

  @empty_day %{date: "", count: 0, level: 0, repos: [], activity_types: []}

  @type day :: %{
          date: String.t(),
          count: non_neg_integer(),
          level: 0..4,
          repos: [String.t()],
          activity_types: [String.t()]
        }

  @type contribution_data :: %{
          days: [day()],
          total: non_neg_integer(),
          source: :graphql | :rest
        }

  @spec empty_day() :: day()
  def empty_day, do: @empty_day

  @doc "Subscribe to contribution data updates via PubSub."
  @spec subscribe() :: :ok | {:error, term()}
  def subscribe, do: Phoenix.PubSub.subscribe(Droodotfoo.PubSub, @topic)

  @spec fetch() :: {:ok, contribution_data()} | {:error, term()}
  def fetch do
    case Cache.get(@cache_key) do
      {:ok, data, _cached_at} -> {:ok, data}
      :miss -> fetch_and_cache()
    end
  end

  @doc "Fetch and broadcast to all subscribers."
  @spec fetch_and_broadcast() :: {:ok, contribution_data()} | {:error, term()}
  def fetch_and_broadcast do
    result = fetch()

    case result do
      {:ok, data} ->
        Phoenix.PubSub.broadcast(Droodotfoo.PubSub, @topic, {:contribution_data, data})

      _ ->
        :ok
    end

    result
  end

  defp fetch_and_cache do
    with {:ok, data} <- do_fetch() do
      Cache.put(@cache_key, data, ttl: @cache_ttl)
      {:ok, data}
    end
  end

  defp do_fetch do
    case System.get_env("GITHUB_TOKEN") do
      token when token not in [nil, ""] -> fetch_graphql_enriched()
      _ -> fetch_rest()
    end
  end

  # Hybrid: GraphQL for full year grid, REST events for recent repo/activity detail
  defp fetch_graphql_enriched do
    with {:ok, data} <- fetch_graphql() do
      detail = rest_detail_map()
      enriched_days = Enum.map(data.days, &merge_rest_detail(&1, detail))
      {:ok, %{data | days: enriched_days}}
    end
  end

  defp rest_detail_map do
    case fetch_all_event_pages() do
      {:error, _} -> %{}
      events -> index_events_by_date(events)
    end
  end

  defp index_events_by_date(events) do
    Enum.reduce(events, %{}, fn event, acc ->
      date = event["created_at"] |> String.slice(0, 10)
      repo = get_in(event, ["repo", "name"]) |> short_repo()
      type = event_label(event["type"])

      Map.update(acc, date, %{repos: [repo], types: [type]}, fn prev ->
        %{repos: Enum.uniq([repo | prev.repos]), types: Enum.uniq([type | prev.types])}
      end)
    end)
  end

  defp merge_rest_detail(day, detail) do
    case Map.get(detail, day.date) do
      nil ->
        day

      %{repos: repos, types: types} ->
        %{
          day
          | repos: Enum.reject(repos, &is_nil/1),
            activity_types: Enum.reject(types, &is_nil/1)
        }
    end
  end

  # -- GraphQL --

  defp fetch_graphql do
    query = """
    {
      user(login: "#{@username}") {
        contributionsCollection {
          contributionCalendar {
            totalContributions
            weeks {
              contributionDays {
                date
                contributionCount
                contributionLevel
              }
            }
          }
        }
      }
    }
    """

    case HttpClient.graphql_request(query) do
      {:ok, body} ->
        body |> Jason.decode!() |> parse_graphql_response()

      {:error, reason} ->
        Logger.warning("GraphQL contributions failed: #{inspect(reason)}, trying REST")
        fetch_rest()
    end
  end

  defp parse_graphql_response(%{
         "data" => %{
           "user" => %{
             "contributionsCollection" => %{
               "contributionCalendar" => %{
                 "totalContributions" => total,
                 "weeks" => weeks_data
               }
             }
           }
         }
       }) do
    days =
      weeks_data
      |> Enum.flat_map(fn %{"contributionDays" => days} ->
        Enum.map(days, fn day ->
          %{
            date: day["date"],
            count: day["contributionCount"],
            level: graphql_level(day["contributionLevel"]),
            repos: [],
            activity_types: []
          }
        end)
      end)

    {:ok, %{days: days, total: total, source: :graphql}}
  end

  defp parse_graphql_response(_), do: {:error, :invalid_graphql_response}

  @graphql_levels %{
    "NONE" => 0,
    "FIRST_QUARTILE" => 1,
    "SECOND_QUARTILE" => 2,
    "THIRD_QUARTILE" => 3,
    "FOURTH_QUARTILE" => 4
  }

  defp graphql_level(level), do: Map.get(@graphql_levels, level, 0)

  # -- REST fallback --

  defp fetch_rest do
    case fetch_all_event_pages() do
      {:error, reason} -> {:error, reason}
      events -> build_from_events(events)
    end
  end

  defp fetch_all_event_pages(page \\ 1, acc \\ [])
  defp fetch_all_event_pages(page, acc) when page > @rest_max_pages, do: collect_pages(acc)

  defp fetch_all_event_pages(page, acc) do
    path = "/users/#{@username}/events?per_page=30&page=#{page}"

    case HttpClient.rest_request(path) do
      {:ok, %{status: 200, body: body}} when is_list(body) and body != [] ->
        fetch_all_event_pages(page + 1, [body | acc])

      {:ok, %{status: 200}} ->
        collect_pages(acc)

      {:ok, %{status: status}} ->
        if acc == [], do: {:error, {:api_error, status}}, else: collect_pages(acc)

      {:error, reason} ->
        if acc == [], do: {:error, reason}, else: collect_pages(acc)
    end
  end

  defp collect_pages(acc), do: acc |> Enum.reverse() |> List.flatten()

  defp build_from_events(events) do
    today = Date.utc_today()
    year_ago = Date.add(today, -364)

    by_date =
      Enum.reduce(events, %{}, fn event, acc ->
        date = event["created_at"] |> String.slice(0, 10)
        count = event_count(event)
        repo = get_in(event, ["repo", "name"]) |> short_repo()
        type = event_label(event["type"])

        Map.update(acc, date, %{count: count, repos: [repo], types: [type]}, fn prev ->
          %{
            count: prev.count + count,
            repos: Enum.uniq([repo | prev.repos]),
            types: Enum.uniq([type | prev.types])
          }
        end)
      end)

    max_count = by_date |> Map.values() |> Enum.map(& &1.count) |> Enum.max(fn -> 0 end)

    days =
      Date.range(year_ago, today)
      |> Enum.map(fn date ->
        date_str = Date.to_iso8601(date)
        info = Map.get(by_date, date_str, %{count: 0, repos: [], types: []})

        %{
          date: date_str,
          count: info.count,
          level: quantize_level(info.count, max_count),
          repos: Enum.reject(info.repos, &is_nil/1),
          activity_types: Enum.reject(info.types, &is_nil/1)
        }
      end)

    total = days |> Enum.map(& &1.count) |> Enum.sum()

    {:ok, %{days: days, total: total, source: :rest}}
  end

  # -- Event parsing --

  defp event_count(%{"type" => "PushEvent", "payload" => %{"size" => n}}), do: n

  defp event_count(%{"type" => t})
       when t in ~w(PullRequestEvent IssuesEvent PullRequestReviewEvent CreateEvent),
       do: 1

  defp event_count(_), do: 0

  @event_labels %{
    "PushEvent" => "commits",
    "PullRequestEvent" => "prs",
    "IssuesEvent" => "issues",
    "PullRequestReviewEvent" => "reviews",
    "CreateEvent" => "created"
  }

  defp event_label(type), do: Map.get(@event_labels, type)

  defp short_repo(nil), do: nil
  defp short_repo(name), do: name |> String.split("/") |> List.last()

  defp quantize_level(0, _), do: 0
  defp quantize_level(_, 0), do: 1

  defp quantize_level(count, max) do
    case count / max do
      r when r <= 0.25 -> 1
      r when r <= 0.50 -> 2
      r when r <= 0.75 -> 3
      _ -> 4
    end
  end
end
