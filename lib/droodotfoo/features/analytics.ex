defmodule Droodotfoo.Features.Analytics do
  @moduledoc """
  Analytics tracking for droo.foo interactions.
  """

  use GenServer

  defstruct [
    :page_views,
    :command_usage,
    :section_visits,
    :session_duration,
    :unique_visitors,
    :popular_times
  ]

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(_opts) do
    state = %__MODULE__{
      page_views: 0,
      command_usage: %{},
      section_visits: %{},
      session_duration: [],
      unique_visitors: MapSet.new(),
      popular_times: %{}
    }

    {:ok, state}
  end

  # Public API

  def track_page_view(session_id) do
    GenServer.cast(__MODULE__, {:page_view, session_id})
  end

  def track_command(command, session_id) do
    GenServer.cast(__MODULE__, {:command, command, session_id})
  end

  def track_section_visit(section, session_id) do
    GenServer.cast(__MODULE__, {:section_visit, section, session_id})
  end

  def track_session_start(session_id) do
    GenServer.cast(__MODULE__, {:session_start, session_id})
  end

  def track_session_end(session_id) do
    GenServer.cast(__MODULE__, {:session_end, session_id})
  end

  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  def get_dashboard_data do
    GenServer.call(__MODULE__, :get_dashboard)
  end

  # Server callbacks

  def handle_cast({:page_view, session_id}, state) do
    new_state = %{
      state
      | page_views: state.page_views + 1,
        unique_visitors: MapSet.put(state.unique_visitors, session_id)
    }

    {:noreply, new_state}
  end

  def handle_cast({:command, command, _session_id}, state) do
    new_command_usage = Map.update(state.command_usage, command, 1, &(&1 + 1))
    {:noreply, %{state | command_usage: new_command_usage}}
  end

  def handle_cast({:section_visit, section, _session_id}, state) do
    new_section_visits = Map.update(state.section_visits, section, 1, &(&1 + 1))
    {:noreply, %{state | section_visits: new_section_visits}}
  end

  def handle_cast({:session_start, session_id}, state) do
    session_start = {session_id, System.monotonic_time(:second)}
    new_sessions = [{session_start} | state.session_duration]
    {:noreply, %{state | session_duration: new_sessions}}
  end

  def handle_cast({:session_end, session_id}, state) do
    now = System.monotonic_time(:second)

    updated_sessions =
      Enum.map(state.session_duration, fn
        {{^session_id, start_time}} ->
          {session_id, start_time, now - start_time}

        other ->
          other
      end)

    # Track popular times
    hour = DateTime.utc_now().hour
    new_popular_times = Map.update(state.popular_times, hour, 1, &(&1 + 1))

    {:noreply, %{state | session_duration: updated_sessions, popular_times: new_popular_times}}
  end

  def handle_call(:get_stats, _from, state) do
    stats = %{
      total_views: state.page_views,
      unique_visitors: MapSet.size(state.unique_visitors),
      top_commands: get_top_items(state.command_usage, 5),
      top_sections: get_top_items(state.section_visits, 5),
      avg_session_duration: calculate_avg_duration(state.session_duration),
      peak_hours: get_peak_hours(state.popular_times)
    }

    {:reply, stats, state}
  end

  def handle_call(:get_dashboard, _from, state) do
    dashboard = generate_dashboard(state)
    {:reply, dashboard, state}
  end

  # Helper functions

  defp get_top_items(map, limit) do
    map
    |> Enum.sort_by(fn {_k, v} -> v end, :desc)
    |> Enum.take(limit)
    |> Enum.map(fn {k, v} -> %{name: k, count: v} end)
  end

  defp calculate_avg_duration(sessions) do
    completed =
      Enum.filter(sessions, fn
        {_id, _start, _duration} -> true
        _ -> false
      end)

    if completed != [] do
      total = Enum.reduce(completed, 0, fn {_id, _start, duration}, acc -> acc + duration end)
      div(total, length(completed))
    else
      0
    end
  end

  defp get_peak_hours(times_map) do
    times_map
    |> Enum.sort_by(fn {_hour, count} -> count end, :desc)
    |> Enum.take(3)
    |> Enum.map(fn {hour, count} -> %{hour: hour, visits: count} end)
  end

  defp generate_dashboard(state) do
    """
    ╔════════════════════════════════════════════════════════════════════╗
    ║                      ANALYTICS DASHBOARD                           ║
    ╠════════════════════════════════════════════════════════════════════╣
    ║                                                                     ║
    ║  Total Page Views:     #{String.pad_leading(to_string(state.page_views), 10)}                              ║
    ║  Unique Visitors:      #{String.pad_leading(to_string(MapSet.size(state.unique_visitors)), 10)}                              ║
    ║                                                                     ║
    ║  ┌─ Top Commands ─────────────────┐  ┌─ Top Sections ────────────┐║
    ║  │                                 │  │                           │║
    ║  │ #{format_top_item(state.command_usage, 0)} │  │ #{format_top_item(state.section_visits, 0)} │║
    ║  │ #{format_top_item(state.command_usage, 1)} │  │ #{format_top_item(state.section_visits, 1)} │║
    ║  │ #{format_top_item(state.command_usage, 2)} │  │ #{format_top_item(state.section_visits, 2)} │║
    ║  │ #{format_top_item(state.command_usage, 3)} │  │ #{format_top_item(state.section_visits, 3)} │║
    ║  │ #{format_top_item(state.command_usage, 4)} │  │ #{format_top_item(state.section_visits, 4)} │║
    ║  └─────────────────────────────────┘  └───────────────────────────┘║
    ║                                                                     ║
    ║  Session Metrics:                                                  ║
    ║  ├─ Average Duration: #{format_duration(calculate_avg_duration(state.session_duration))}                                  ║
    ║  ├─ Active Sessions:  #{String.pad_leading(to_string(count_active_sessions(state.session_duration)), 3)}                                          ║
    ║  └─ Peak Hours:       #{format_peak_hours(state.popular_times)}                              ║
    ║                                                                     ║
    ╚════════════════════════════════════════════════════════════════════╝
    """
  end

  defp format_top_item(map, index) do
    items =
      map
      |> Enum.sort_by(fn {_k, v} -> v end, :desc)
      |> Enum.map(fn {k, v} -> "#{k}: #{v}" end)

    item = Enum.at(items, index, "---")
    String.pad_trailing(item, 30)
  end

  defp format_duration(seconds) do
    minutes = div(seconds, 60)
    secs = rem(seconds, 60)
    "#{minutes}m #{secs}s"
  end

  defp count_active_sessions(sessions) do
    Enum.count(sessions, fn
      {_id, _start} -> true
      _ -> false
    end)
  end

  defp format_peak_hours(times_map) do
    peak =
      times_map
      |> Enum.max_by(fn {_hour, count} -> count end, fn -> {0, 0} end)

    case peak do
      {hour, _count} -> "#{hour}:00-#{hour + 1}:00"
      _ -> "N/A"
    end
  end
end
