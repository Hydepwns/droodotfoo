defmodule Droodotfoo.Features.TerminalMultiplexer do
  @moduledoc """
  Terminal multiplexing for split-screen views.
  """

  defstruct [:layout, :panes, :active_pane, :split_ratio]

  def init do
    %__MODULE__{
      layout: :single,
      panes: [%{id: 1, content: :home, active: true}],
      active_pane: 1,
      split_ratio: 0.5
    }
  end

  def split_horizontal(state) do
    case state.layout do
      :single ->
        %{
          state
          | layout: :horizontal_split,
            panes: [
              %{id: 1, content: :home, active: true, position: :top},
              %{id: 2, content: :projects, active: false, position: :bottom}
            ],
            active_pane: 1
        }

      _ ->
        state
    end
  end

  def split_vertical(state) do
    case state.layout do
      :single ->
        %{
          state
          | layout: :vertical_split,
            panes: [
              %{id: 1, content: :home, active: true, position: :left},
              %{id: 2, content: :skills, active: false, position: :right}
            ],
            active_pane: 1
        }

      _ ->
        state
    end
  end

  def split_quad(state) do
    %{
      state
      | layout: :quad,
        panes: [
          %{id: 1, content: :home, active: true, position: :top_left},
          %{id: 2, content: :projects, active: false, position: :top_right},
          %{id: 3, content: :skills, active: false, position: :bottom_left},
          %{id: 4, content: :experience, active: false, position: :bottom_right}
        ],
        active_pane: 1
    }
  end

  def cycle_pane(state) do
    next_id = rem(state.active_pane, length(state.panes)) + 1

    new_panes =
      Enum.map(state.panes, fn pane ->
        %{pane | active: pane.id == next_id}
      end)

    %{state | panes: new_panes, active_pane: next_id}
  end

  def close_pane(state, pane_id) do
    if length(state.panes) > 1 do
      new_panes = Enum.filter(state.panes, &(&1.id != pane_id))
      new_layout = if length(new_panes) == 1, do: :single, else: state.layout

      %{state | panes: new_panes, layout: new_layout, active_pane: List.first(new_panes).id}
    else
      state
    end
  end

  def resize_split(state, _direction, amount) do
    case state.layout do
      layout when layout in [:horizontal_split, :vertical_split] ->
        new_ratio = max(0.2, min(0.8, state.split_ratio + amount))
        %{state | split_ratio: new_ratio}

      _ ->
        state
    end
  end

  def get_pane_dimensions(state, pane_id, total_width, total_height) do
    pane = Enum.find(state.panes, &(&1.id == pane_id))

    case {state.layout, pane.position} do
      {:single, _} ->
        {0, 0, total_width, total_height}

      {:horizontal_split, :top} ->
        split_height = round(total_height * state.split_ratio)
        {0, 0, total_width, split_height}

      {:horizontal_split, :bottom} ->
        split_height = round(total_height * state.split_ratio)
        {0, split_height, total_width, total_height - split_height}

      {:vertical_split, :left} ->
        split_width = round(total_width * state.split_ratio)
        {0, 0, split_width, total_height}

      {:vertical_split, :right} ->
        split_width = round(total_width * state.split_ratio)
        {split_width, 0, total_width - split_width, total_height}

      {:quad, :top_left} ->
        {0, 0, div(total_width, 2), div(total_height, 2)}

      {:quad, :top_right} ->
        {div(total_width, 2), 0, div(total_width, 2), div(total_height, 2)}

      {:quad, :bottom_left} ->
        {0, div(total_height, 2), div(total_width, 2), div(total_height, 2)}

      {:quad, :bottom_right} ->
        {div(total_width, 2), div(total_height, 2), div(total_width, 2), div(total_height, 2)}

      _ ->
        {0, 0, total_width, total_height}
    end
  end

  def render_border(buffer, x, y, width, height, active?) do
    style = if active?, do: "═", else: "─"
    corner_style = if active?, do: {"╔", "╗", "╚", "╝"}, else: {"┌", "┐", "└", "┘"}

    {tl, tr, bl, br} = corner_style

    # Top border
    buffer
    |> draw_at(x, y, tl <> String.duplicate(style, width - 2) <> tr)
    # Bottom border
    |> draw_at(x, y + height - 1, bl <> String.duplicate(style, width - 2) <> br)
    # Side borders
    |> draw_vertical_borders(x, y + 1, height - 2, width, if(active?, do: "║", else: "│"))
  end

  defp draw_at(buffer, _x, _y, _text) do
    # Implementation would call TerminalBridge.write_at
    buffer
  end

  defp draw_vertical_borders(buffer, x, y, height, width, style) do
    Enum.reduce(0..(height - 1), buffer, fn offset, buf ->
      buf
      |> draw_at(x, y + offset, style)
      |> draw_at(x + width - 1, y + offset, style)
    end)
  end
end
