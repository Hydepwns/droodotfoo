defmodule DroodotfooWeb.GithubComponents do
  @moduledoc """
  Components for GitHub data display.
  Grid layout derived from flat contribution data at render time.
  """

  use DroodotfooWeb, :html

  alias Droodotfoo.GitHub.Contributions

  @month_abbr ~w(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec)
  @day_labels ["", "Mon", "", "Wed", "", "Fri", ""]

  attr :id, :string, default: "contribution-graph"
  attr :grid, :map, default: nil
  attr :loading, :boolean, default: true

  def contribution_graph(assigns) do
    ~H"""
    <div id={@id} phx-hook="ContributionGraphHook">
      <.contrib_loading :if={@loading} />
      <div :if={!@loading && @grid}>
        <.contrib_grid grid={@grid} />
        <.contrib_summary grid={@grid} />
      </div>
      <p :if={!@loading && !@grid} class="text-muted">Unable to load contribution data.</p>
      <div class="contrib-tooltip"></div>
    </div>
    """
  end

  # -- Grid presenter: flat days -> week grid with month labels and streak --

  @doc "Transform flat contribution data into a grid structure for rendering."
  def to_grid(%{days: days, total: total, source: source}) do
    first_date = days |> hd() |> Map.get(:date) |> Date.from_iso8601!()
    padding = Date.day_of_week(first_date, :sunday) - 1
    empty = Contributions.empty_day()

    weeks =
      (List.duplicate(empty, padding) ++ days)
      |> Enum.chunk_every(7, 7, List.duplicate(empty, 7))

    %{
      weeks: weeks,
      month_labels: derive_month_labels(weeks),
      total: total,
      streak: calculate_streak(days),
      source: source
    }
  end

  defp derive_month_labels(weeks) do
    weeks
    |> Enum.with_index()
    |> Enum.reduce({%{}, nil}, fn {week, idx}, {labels, last} ->
      case hd(week) do
        %{date: date} when date != "" ->
          %Date{month: m} = Date.from_iso8601!(date)

          if m != last,
            do: {Map.put(labels, idx, Enum.at(@month_abbr, m - 1)), m},
            else: {labels, last}

        _ ->
          {labels, last}
      end
    end)
    |> elem(0)
  end

  defp calculate_streak(days) do
    days
    |> Enum.reverse()
    |> Enum.take_while(&(&1.count > 0))
    |> length()
  end

  defp cell_label(%{date: ""}), do: "No data"

  defp cell_label(%{date: date, count: count}) do
    "#{date}: #{count} contribution#{if count == 1, do: "", else: "s"}"
  end

  # -- Template components --

  defp contrib_loading(assigns) do
    ~H"""
    <div class="contrib-loading">
      <div class="contrib-loading-grid">
        <%= for _i <- 1..49 do %>
          <div class="contrib-loading-cell"></div>
        <% end %>
      </div>
      <div class="contrib-summary">
        <span class="text-muted">Loading contributions...</span>
      </div>
    </div>
    """
  end

  defp contrib_grid(assigns) do
    assigns = assign(assigns, :day_labels, @day_labels)

    ~H"""
    <div class="contrib-graph">
      <div class="contrib-body">
        <div class="contrib-day-labels">
          <div class="contrib-day-spacer"></div>
          <%= for label <- @day_labels do %>
            <div class="contrib-day-label">{label}</div>
          <% end %>
        </div>
        <div class="contrib-main">
          <div class="contrib-month-row">
            <%= for {_week, idx} <- Enum.with_index(@grid.weeks) do %>
              <div class="contrib-month-cell">
                {Map.get(@grid.month_labels, idx, "")}
              </div>
            <% end %>
          </div>
          <div class="contrib-weeks" role="grid" aria-label="Contribution graph">
            <%= for week <- @grid.weeks do %>
              <div class="contrib-week" role="row">
                <%= for {day, day_idx} <- Enum.with_index(week) do %>
                  <div
                    class={"contrib-cell contrib-level-#{day.level}"}
                    role="gridcell"
                    tabindex={if(day.date != "" && day_idx == 0, do: "0", else: "-1")}
                    aria-label={cell_label(day)}
                    data-date={day.date}
                    data-count={to_string(day.count)}
                    data-repos={if(day.repos != [], do: Enum.join(day.repos, ", "))}
                    data-types={if(day.activity_types != [], do: Enum.join(day.activity_types, ", "))}
                  >
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp contrib_summary(assigns) do
    ~H"""
    <div class="contrib-summary">
      <span>
        <strong class="contrib-accent">{@grid.total}</strong> contributions in the last year
      </span>
      <%= if @grid.streak > 0 do %>
        <span class="contrib-divider">|</span>
        <span>
          <strong class="contrib-accent">{@grid.streak}</strong> day streak
        </span>
      <% end %>
      <%= if @grid.source == :rest do %>
        <span class="contrib-source">(partial -- REST API)</span>
      <% end %>
    </div>
    """
  end
end
