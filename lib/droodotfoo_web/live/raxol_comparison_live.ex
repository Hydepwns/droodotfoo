defmodule DroodotfooWeb.RaxolComparisonLive do
  @moduledoc """
  Side-by-side comparison of original TerminalBridge vs RaxolWeb prototype.

  This validates the extraction by comparing:
  - Rendering output
  - Performance characteristics
  - Cache efficiency
  - Memory usage
  """

  use DroodotfooWeb, :live_view
  alias Droodotfoo.TerminalBridge
  alias RaxolWeb.Renderer
  alias Droodotfoo.RaxolApp

  @impl true
  def mount(_params, _session, socket) do
    # Use real buffer from RaxolApp for comparison
    buffer = RaxolApp.get_buffer()

    # Initialize both renderers
    raxol_renderer = Renderer.new()

    # Benchmark both approaches
    {original_time, original_html} = :timer.tc(fn -> TerminalBridge.terminal_to_html(buffer) end)
    {raxol_time, {raxol_html, new_renderer}} = :timer.tc(fn -> Renderer.render(raxol_renderer, buffer) end)

    {:ok,
     socket
     |> assign(:buffer, buffer)
     |> assign(:original_html, original_html)
     |> assign(:raxol_html, raxol_html)
     |> assign(:original_time_us, original_time)
     |> assign(:raxol_time_us, raxol_time)
     |> assign(:raxol_renderer, new_renderer)
     |> assign(:render_count, 1)
     |> assign(:original_total_time, original_time)
     |> assign(:raxol_total_time, raxol_time)
     |> assign(:show_diff, false)
     |> assign(:benchmarking, false)
     |> assign(:benchmark_results, nil)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div style="max-width: 1600px; margin: 0 auto; padding: 2rem; font-family: monospace; background: #0a0a0a; color: #e0e0e0; min-height: 100vh;">
      <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem; padding-bottom: 1rem; border-bottom: 2px solid #00ff88;">
        <h1 style="font-size: 2rem; color: #00ff88; margin: 0;">RaxolWeb Validation</h1>
        <div style="text-align: right;">
          <div style="color: #666; font-size: 0.8rem;">Render Count</div>
          <div style="font-size: 2rem; font-weight: bold; color: #00ff88;"><%= @render_count %></div>
        </div>
      </div>

      <!-- Performance Grid -->
      <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; margin-bottom: 2rem;">
        <!-- Original Stats -->
        <div style="padding: 1.25rem; background: #1a1a1a; border: 1px solid #444; border-radius: 6px;">
          <div style="color: #ffaa00; font-size: 1rem; margin-bottom: 1rem; font-weight: bold;">Original TerminalBridge</div>
          <div style="display: flex; justify-content: space-between; margin-bottom: 0.5rem;">
            <span style="color: #666;">Last:</span>
            <strong style="color: #fff;"><%= format_time(@original_time_us) %></strong>
          </div>
          <div style="display: flex; justify-content: space-between; margin-bottom: 0.5rem;">
            <span style="color: #666;">Avg:</span>
            <strong style="color: #fff;"><%= format_time(div(@original_total_time, @render_count)) %></strong>
          </div>
          <div style="display: flex; justify-content: space-between;">
            <span style="color: #666;">Size:</span>
            <strong style="color: #fff;"><%= byte_size(@original_html) %>b</strong>
          </div>
        </div>

        <!-- RaxolWeb Stats -->
        <div style="padding: 1.25rem; background: #1a1a1a; border: 1px solid #444; border-radius: 6px;">
          <div style="color: #00ff88; font-size: 1rem; margin-bottom: 1rem; font-weight: bold;">RaxolWeb Renderer</div>
          <div style="display: flex; justify-content: space-between; margin-bottom: 0.5rem;">
            <span style="color: #666;">Last:</span>
            <strong style="color: #fff;"><%= format_time(@raxol_time_us) %></strong>
          </div>
          <div style="display: flex; justify-content: space-between; margin-bottom: 0.5rem;">
            <span style="color: #666;">Avg:</span>
            <strong style="color: #fff;"><%= format_time(div(@raxol_total_time, @render_count)) %></strong>
          </div>
          <div style="display: flex; justify-content: space-between;">
            <span style="color: #666;">Size:</span>
            <strong style="color: #fff;"><%= byte_size(@raxol_html) %>b</strong>
          </div>
        </div>

        <!-- Cache Stats -->
        <% stats = Renderer.stats(@raxol_renderer) %>
        <div style="padding: 1.25rem; background: #1a1a1a; border: 1px solid #444; border-radius: 6px;">
          <div style="color: #00ccff; font-size: 1rem; margin-bottom: 1rem; font-weight: bold;">Cache Performance</div>
          <div style="display: flex; justify-content: space-between; margin-bottom: 0.5rem;">
            <span style="color: #666;">Hits:</span>
            <strong style="color: #0ff;"><%= stats.cache_hits %></strong>
          </div>
          <div style="display: flex; justify-content: space-between; margin-bottom: 0.5rem;">
            <span style="color: #666;">Misses:</span>
            <strong style="color: #f80;"><%= stats.cache_misses %></strong>
          </div>
          <div style="display: flex; justify-content: space-between; padding-top: 0.5rem; border-top: 1px solid #333; margin-top: 0.5rem;">
            <span style="color: #666;">Ratio:</span>
            <strong style="color: #0f0; font-size: 1.2rem;"><%= Float.round(stats.hit_ratio * 100, 1) %>%</strong>
          </div>
        </div>
      </div>

      <!-- Speedup Banner -->
      <div style={"padding: 1.25rem; background: #{performance_bg_color(@raxol_time_us, @original_time_us)}; border-radius: 6px; color: #000; font-weight: bold; font-size: 1.2rem; text-align: center; margin-bottom: 2rem;"}>
        <%= if @raxol_time_us < @original_time_us do %>
          [OK] RaxolWeb is <%= Float.round(@original_time_us / @raxol_time_us, 2) %>x faster
        <% else %>
          [!!] RaxolWeb is <%= Float.round(@raxol_time_us / @original_time_us, 2) %>x slower
        <% end %>
      </div>

      <!-- Controls & Validation -->
      <div style="display: grid; grid-template-columns: auto 1fr; gap: 1rem; margin-bottom: 2rem;">
        <div style="display: flex; gap: 1rem;">
          <button phx-click="re_render" style="padding: 0.75rem 1.25rem; font-family: monospace; background: #00ff88; color: #000; border: none; border-radius: 6px; cursor: pointer; font-weight: bold;">
            [>] Re-render
          </button>
          <button phx-click="toggle_diff" style="padding: 0.75rem 1.25rem; font-family: monospace; background: #1a1a1a; color: #00ccff; border: 1px solid #00ccff; border-radius: 6px; cursor: pointer; font-weight: bold;">
            <%= if @show_diff, do: "[x] Hide", else: "[+] Show" %> Diff
          </button>
          <button phx-click="benchmark" style={"padding: 0.75rem 1.25rem; font-family: monospace; background: #{if @benchmark_results, do: "#2a1a2a", else: "#1a1a1a"}; color: #ff00ff; border: 1px solid #ff00ff; border-radius: 6px; cursor: pointer; font-weight: bold;"}>
            <%= if @benchmark_results, do: "[#] Run Again", else: "[#] Benchmark x100" %>
          </button>
        </div>

        <div style="padding: 0.75rem 1.25rem; background: #1a1a1a; border: 1px solid #444; border-radius: 6px; display: flex; gap: 2rem; align-items: center;">
          <div style="display: flex; gap: 0.5rem; align-items: center;">
            <span style={"color: #{if @raxol_time_us < 16000, do: "#0f0", else: "#f00"}; font-weight: bold;"}><%= if @raxol_time_us < 16000, do: "[OK]", else: "[X]" %></span>
            <span style="color: #666; font-size: 0.9rem;">&lt;16ms</span>
          </div>
          <div style="display: flex; gap: 0.5rem; align-items: center;">
            <span style={"color: #{if Renderer.stats(@raxol_renderer).hit_ratio > 0.9, do: "#0f0", else: "#f00"}; font-weight: bold;"}><%= if Renderer.stats(@raxol_renderer).hit_ratio > 0.9, do: "[OK]", else: "[X]" %></span>
            <span style="color: #666; font-size: 0.9rem;">&gt;90% cache</span>
          </div>
          <div style="display: flex; gap: 0.5rem; align-items: center;">
            <span style={"color: #{if byte_size(@raxol_html) < byte_size(@original_html) * 1.5, do: "#0f0", else: "#f00"}; font-weight: bold;"}><%= if byte_size(@raxol_html) < byte_size(@original_html) * 1.5, do: "[OK]", else: "[X]" %></span>
            <span style="color: #666; font-size: 0.9rem;">&lt;150% size</span>
          </div>
          <div style="display: flex; gap: 0.5rem; align-items: center;">
            <span style={"color: #{if @render_count > 5, do: "#0f0", else: "#ff0"}; font-weight: bold;"}><%= if @render_count > 5, do: "[OK]", else: "[..]" %></span>
            <span style="color: #666; font-size: 0.9rem;"><%= @render_count %>/5 renders</span>
          </div>
        </div>
      </div>

      <!-- HTML Diff (if requested) -->
      <%= if @show_diff do %>
        <div style="margin-bottom: 2rem; padding: 1.5rem; background: #1a1a1a; border: 1px solid #333; border-radius: 4px;">
          <h3 style="margin-bottom: 1rem; color: #00ccff; font-size: 1.3rem;">HTML Output Comparison</h3>

          <!-- Summary Stats -->
          <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; margin-bottom: 1.5rem;">
            <div style="padding: 1rem; background: #0f0f0f; border: 1px solid #444; border-radius: 4px;">
              <div style="color: #888; font-size: 0.8rem; margin-bottom: 0.5rem;">Original Size</div>
              <div style="color: #ffaa00; font-size: 1.2rem; font-weight: bold;"><%= byte_size(@original_html) %> bytes</div>
            </div>
            <div style="padding: 1rem; background: #0f0f0f; border: 1px solid #444; border-radius: 4px;">
              <div style="color: #888; font-size: 0.8rem; margin-bottom: 0.5rem;">RaxolWeb Size</div>
              <div style="color: #00ff88; font-size: 1.2rem; font-weight: bold;"><%= byte_size(@raxol_html) %> bytes</div>
            </div>
            <div style="padding: 1rem; background: #0f0f0f; border: 1px solid #444; border-radius: 4px;">
              <div style="color: #888; font-size: 0.8rem; margin-bottom: 0.5rem;">Match Status</div>
              <%= if @original_html == @raxol_html do %>
                <div style="color: #0f0; font-size: 1.2rem; font-weight: bold;">[OK] Identical</div>
              <% else %>
                <div style="color: #ff0; font-size: 1.2rem; font-weight: bold;">[!!] Different</div>
              <% end %>
            </div>
          </div>

          <!-- Difference Analysis -->
          <%= if @original_html != @raxol_html do %>
            <% diff_info = find_first_difference(@original_html, @raxol_html) %>
            <div style="margin-bottom: 1.5rem; padding: 1rem; background: #2a1a1a; border: 1px solid #ff0; border-radius: 4px;">
              <h4 style="color: #ff0; margin-bottom: 0.75rem; font-size: 0.95rem;">First Difference at position <%= diff_info.position %></h4>
              <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; font-size: 0.75rem;">
                <div>
                  <div style="color: #888; margin-bottom: 0.25rem;">Original context:</div>
                  <pre style="overflow: auto; background: #1a0a0a; color: #ffaa00; padding: 0.5rem; border: 1px solid #ff0; border-radius: 4px; white-space: pre-wrap; word-wrap: break-word; font-size: 0.7rem; line-height: 1.3; max-height: 150px;"><%= diff_info.original_context %></pre>
                </div>
                <div>
                  <div style="color: #888; margin-bottom: 0.25rem;">RaxolWeb context:</div>
                  <pre style="overflow: auto; background: #0a1a0a; color: #00ff88; padding: 0.5rem; border: 1px solid #0f0; border-radius: 4px; white-space: pre-wrap; word-wrap: break-word; font-size: 0.7rem; line-height: 1.3; max-height: 150px;"><%= diff_info.raxol_context %></pre>
                </div>
              </div>
            </div>
          <% end %>

          <!-- HTML Previews -->
          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem; font-size: 0.75rem;">
            <div>
              <h4 style="color: #ffaa00; margin-bottom: 0.5rem; font-size: 0.9rem;">Original TerminalBridge (first 500 chars)</h4>
              <pre style="overflow: auto; background: #000; color: #0f0; padding: 0.75rem; border: 1px solid #333; border-radius: 4px; max-height: 300px; white-space: pre-wrap; word-wrap: break-word; font-size: 0.7rem; line-height: 1.4;"><%= String.slice(@original_html, 0, 500) %><%= if byte_size(@original_html) > 500, do: "\n...", else: "" %></pre>
            </div>
            <div>
              <h4 style="color: #00ff88; margin-bottom: 0.5rem; font-size: 0.9rem;">RaxolWeb Renderer (first 500 chars)</h4>
              <pre style="overflow: auto; background: #000; color: #0f0; padding: 0.75rem; border: 1px solid #333; border-radius: 4px; max-height: 300px; white-space: pre-wrap; word-wrap: break-word; font-size: 0.7rem; line-height: 1.4;"><%= String.slice(@raxol_html, 0, 500) %><%= if byte_size(@raxol_html) > 500, do: "\n...", else: "" %></pre>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Benchmark Results (if available) -->
      <%= if @benchmark_results do %>
        <div style="margin-bottom: 2rem; padding: 1.5rem; background: #1a1a1a; border: 1px solid #ff00ff; border-radius: 6px;">
          <h3 style="margin-bottom: 1rem; color: #ff00ff; font-size: 1.3rem; font-weight: bold;">[#] Benchmark Results (100 iterations)</h3>
          <div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 1.5rem; margin-bottom: 1rem;">
            <div>
              <div style="color: #888; font-size: 0.9rem; margin-bottom: 0.5rem;">Total Time</div>
              <div style="display: flex; justify-content: space-between; margin-bottom: 0.5rem;">
                <span style="color: #ffaa00;">Original:</span>
                <strong style="color: #fff;"><%= format_time(@benchmark_results.original) %></strong>
              </div>
              <div style="display: flex; justify-content: space-between;">
                <span style="color: #00ff88;">RaxolWeb:</span>
                <strong style="color: #fff;"><%= format_time(@benchmark_results.raxol) %></strong>
              </div>
            </div>
            <div>
              <div style="color: #888; font-size: 0.9rem; margin-bottom: 0.5rem;">Average per Render</div>
              <div style="display: flex; justify-content: space-between; margin-bottom: 0.5rem;">
                <span style="color: #ffaa00;">Original:</span>
                <strong style="color: #fff;"><%= format_time(@benchmark_results.original_avg) %></strong>
              </div>
              <div style="display: flex; justify-content: space-between;">
                <span style="color: #00ff88;">RaxolWeb:</span>
                <strong style="color: #fff;"><%= format_time(@benchmark_results.raxol_avg) %></strong>
              </div>
            </div>
            <div>
              <div style="color: #888; font-size: 0.9rem; margin-bottom: 0.5rem;">Performance</div>
              <div style="text-align: center; padding: 1rem; background: #2a1a2a; border-radius: 4px;">
                <div style="font-size: 2rem; font-weight: bold; color: #ff00ff;"><%= @benchmark_results.speedup %>x</div>
                <div style="color: #888; font-size: 0.8rem;">faster</div>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Visual Comparison -->
      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1.5rem;">
        <div>
          <div style="margin-bottom: 0.75rem; padding: 0.5rem 1rem; background: #1a1a1a; border-left: 3px solid #ffaa00; color: #ffaa00; font-weight: bold;">
            Original TerminalBridge
          </div>
          <div style="border: 1px solid #333; padding: 1rem; background: #000; border-radius: 4px; overflow: auto;">
            <%= Phoenix.HTML.raw(@original_html) %>
          </div>
        </div>

        <div>
          <div style="margin-bottom: 0.75rem; padding: 0.5rem 1rem; background: #1a1a1a; border-left: 3px solid #00ff88; color: #00ff88; font-weight: bold;">
            RaxolWeb Renderer
          </div>
          <div style="border: 1px solid #333; padding: 1rem; background: #000; border-radius: 4px; overflow: auto;">
            <%= Phoenix.HTML.raw(@raxol_html) %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("re_render", _params, socket) do
    buffer = RaxolApp.get_buffer()

    # Re-render with both approaches
    {original_time, original_html} = :timer.tc(fn -> TerminalBridge.terminal_to_html(buffer) end)

    {raxol_time, {raxol_html, new_renderer}} =
      :timer.tc(fn -> Renderer.render(socket.assigns.raxol_renderer, buffer) end)

    {:noreply,
     socket
     |> assign(:buffer, buffer)
     |> assign(:original_html, original_html)
     |> assign(:raxol_html, raxol_html)
     |> assign(:original_time_us, original_time)
     |> assign(:raxol_time_us, raxol_time)
     |> assign(:raxol_renderer, new_renderer)
     |> update(:render_count, &(&1 + 1))
     |> update(:original_total_time, &(&1 + original_time))
     |> update(:raxol_total_time, &(&1 + raxol_time))}
  end

  def handle_event("toggle_diff", _params, socket) do
    {:noreply, update(socket, :show_diff, &(!&1))}
  end

  def handle_event("benchmark", _params, socket) do
    buffer = RaxolApp.get_buffer()

    # Run 100 iterations and measure
    {original_total, _} =
      :timer.tc(fn ->
        for _ <- 1..100 do
          TerminalBridge.terminal_to_html(buffer)
        end
      end)

    renderer = Renderer.new()

    {raxol_total, _} =
      :timer.tc(fn ->
        Enum.reduce(1..100, renderer, fn _, r ->
          {_html, new_r} = Renderer.render(r, buffer)
          new_r
        end)
      end)

    # Store results and display
    results = %{
      original: original_total,
      raxol: raxol_total,
      iterations: 100,
      speedup: Float.round(original_total / raxol_total, 2),
      original_avg: div(original_total, 100),
      raxol_avg: div(raxol_total, 100)
    }

    {:noreply,
     socket
     |> assign(:benchmarking, false)
     |> assign(:benchmark_results, results)}
  end


  # Helpers

  defp performance_bg_color(raxol_time, original_time) do
    if raxol_time < original_time, do: "#d4edda", else: "#f8d7da"
  end

  defp format_time(microseconds) when microseconds < 1000 do
    "#{microseconds}μs"
  end

  defp format_time(microseconds) when microseconds < 1_000_000 do
    "#{Float.round(microseconds / 1000, 2)}ms"
  end

  defp format_time(microseconds) do
    "#{Float.round(microseconds / 1_000_000, 2)}s"
  end

  defp find_first_difference(str1, str2) do
    # Find the first position where strings differ
    position =
      str1
      |> String.graphemes()
      |> Enum.zip(String.graphemes(str2))
      |> Enum.find_index(fn {c1, c2} -> c1 != c2 end)

    case position do
      nil ->
        # Strings are identical or one is prefix of other
        %{
          position: min(String.length(str1), String.length(str2)),
          original_context: "End of string",
          raxol_context: "End of string"
        }

      pos ->
        # Show 100 chars before and after the difference
        context_start = max(0, pos - 100)
        context_end = pos + 100

        original_context = String.slice(str1, context_start, context_end - context_start)
        raxol_context = String.slice(str2, context_start, context_end - context_start)

        %{
          position: pos,
          original_context: original_context,
          raxol_context: raxol_context
        }
    end
  end
end
