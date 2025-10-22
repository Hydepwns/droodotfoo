defmodule Droodotfoo.Raxol.RendererTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.CursorTrail
  alias Droodotfoo.Raxol.Renderer

  describe "render/1" do
    test "creates a valid buffer with correct dimensions" do
      state = %{
        cursor_y: 0,
        current_section: :home,
        command_mode: false,
        command_buffer: "",
        trail_enabled: false,
        cursor_trail: nil,
        terminal_output: "",
        prompt: "",
        help_modal_open: false,
        privacy_mode: false,
        encryption_keys: %{},
        encryption_sessions: %{},
        web3_wallet_connected: false
      }

      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      assert is_map(buffer)
      assert Map.has_key?(buffer, :lines)
      assert is_list(buffer.lines)
      assert length(buffer.lines) == 45

      # Verify each line has correct structure
      Enum.each(buffer.lines, fn line ->
        assert is_map(line)
        assert Map.has_key?(line, :cells)
        assert is_list(line.cells)
        assert length(line.cells) == 110

        # Verify each cell has proper structure
        Enum.each(line.cells, fn cell ->
          assert is_map(cell)
          assert Map.has_key?(cell, :char)
          assert is_binary(cell.char)
          assert String.length(cell.char) <= 1
        end)
      end)
    end

    test "renders ASCII logo at correct position" do
      state = %{
        cursor_y: 0,
        current_section: :home,
        command_mode: false,
        command_buffer: "",
        trail_enabled: false,
        cursor_trail: nil,
        terminal_output: "",
        prompt: "",
        help_modal_open: false,
        privacy_mode: false,
        encryption_keys: %{},
        encryption_sessions: %{},
        web3_wallet_connected: false
      }

      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      # Check for DROO text in logo
      line_3 = Enum.at(buffer.lines, 2)
      line_text = Enum.map_join(line_3.cells, "", & &1.char)
      assert String.contains?(line_text, "██████╗")
      assert String.contains?(line_text, "██████╗")
      assert String.contains?(line_text, "██████╗")
      assert String.contains?(line_text, "██████╗")
    end

    test "renders navigation with correct cursor position" do
      state = %{
        cursor_y: 2,
        current_section: :contact,
        command_mode: false,
        command_buffer: "",
        trail_enabled: false,
        cursor_trail: nil,
        terminal_output: "",
        prompt: "",
        help_modal_open: false,
        privacy_mode: false,
        encryption_keys: %{},
        encryption_sessions: %{},
        web3_wallet_connected: false
      }

      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      # Check that cursor is on the contact line (index 2)
      # nav_y + 2 + cursor_y
      nav_line = Enum.at(buffer.lines, 15 + 2)
      line_text = Enum.map_join(nav_line.cells, "", & &1.char)
      assert String.contains?(line_text, "█")
      assert String.contains?(line_text, "Contact")
    end

    test "displays command mode prompt correctly" do
      state = %{
        cursor_y: 0,
        current_section: :home,
        command_mode: true,
        command_buffer: "help",
        trail_enabled: false,
        cursor_trail: nil,
        terminal_output: "",
        prompt: "",
        help_modal_open: false,
        privacy_mode: false,
        encryption_keys: %{},
        encryption_sessions: %{},
        web3_wallet_connected: false
      }

      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      # Check last line for command prompt
      last_line = List.last(buffer.lines)
      line_text = Enum.map_join(last_line.cells, "", & &1.char)
      assert String.contains?(line_text, ":help_")
    end

    test "displays hint when not in command mode" do
      state = %{
        cursor_y: 0,
        current_section: :home,
        command_mode: false,
        command_buffer: "",
        trail_enabled: false,
        cursor_trail: nil,
        terminal_output: "",
        prompt: "",
        help_modal_open: false,
        privacy_mode: false,
        encryption_keys: %{},
        encryption_sessions: %{},
        web3_wallet_connected: false
      }

      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      # Check last line for hint
      last_line = List.last(buffer.lines)
      line_text = Enum.map_join(last_line.cells, "", & &1.char)
      assert String.contains?(line_text, ": cmd") or String.contains?(line_text, "? help")
    end
  end

  describe "render/1 with cursor trail" do
    test "handles cursor trail when enabled with valid trail data" do
      # Create a cursor trail
      trail =
        CursorTrail.new()
        |> CursorTrail.add_position({10, 10})
        |> CursorTrail.add_position({15, 15})

      state = %{
        cursor_y: 0,
        current_section: :home,
        command_mode: false,
        command_buffer: "",
        trail_enabled: true,
        cursor_trail: trail,
        terminal_output: "",
        prompt: "",
        help_modal_open: false,
        privacy_mode: false,
        encryption_keys: %{},
        encryption_sessions: %{},
        web3_wallet_connected: false
      }

      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      assert is_map(buffer)
      assert Map.has_key?(buffer, :lines)

      # Trail should be drawn at the specified positions
      # Note: Actual verification depends on empty cells at those positions
    end

    test "handles nil cursor trail gracefully" do
      state = %{
        cursor_y: 0,
        current_section: :home,
        command_mode: false,
        command_buffer: "",
        trail_enabled: true,
        cursor_trail: nil,
        terminal_output: "",
        prompt: "",
        help_modal_open: false,
        privacy_mode: false,
        encryption_keys: %{},
        encryption_sessions: %{},
        web3_wallet_connected: false
      }

      # Should not crash
      {buffer, _clickable_regions, _content_height} = Renderer.render(state)
      assert is_map(buffer)
    end

    test "respects trail_enabled flag" do
      trail =
        CursorTrail.new()
        |> CursorTrail.add_position({10, 10})

      state = %{
        cursor_y: 0,
        current_section: :home,
        command_mode: false,
        command_buffer: "",
        # Trail disabled
        trail_enabled: false,
        cursor_trail: trail,
        terminal_output: "",
        prompt: "",
        help_modal_open: false,
        privacy_mode: false,
        encryption_keys: %{},
        encryption_sessions: %{},
        web3_wallet_connected: false
      }

      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      # Trail should not be drawn when disabled
      line = Enum.at(buffer.lines, 10)

      if line && line.cells do
        cell = Enum.at(line.cells, 10)
        if cell, do: refute(String.contains?(cell.char, "█"))
      end
    end

    test "handles trail positions at buffer boundaries" do
      trail =
        CursorTrail.new()
        # Top-left
        |> CursorTrail.add_position({0, 0})
        # Top-right
        |> CursorTrail.add_position({0, 79})
        # Bottom-left
        |> CursorTrail.add_position({23, 0})
        # Bottom-right
        |> CursorTrail.add_position({23, 79})

      state = %{
        cursor_y: 0,
        current_section: :home,
        command_mode: false,
        command_buffer: "",
        trail_enabled: true,
        cursor_trail: trail,
        terminal_output: "",
        prompt: "",
        help_modal_open: false,
        privacy_mode: false,
        encryption_keys: %{},
        encryption_sessions: %{},
        web3_wallet_connected: false
      }

      # Create another trail with out-of-bounds positions
      # The renderer should handle these gracefully
      trail_with_oob = %{trail: [{-1, 10, 5}, {10, -1, 5}, {80, 10, 5}, {10, 24, 5}]}

      state_with_oob = %{state | cursor_trail: trail_with_oob}

      # Should not crash with valid positions
      {buffer, _clickable_regions, _content_height} = Renderer.render(state)
      assert is_map(buffer)

      # Should not crash with out-of-bounds positions
      {buffer_oob, _regions_oob, _content_height_oob} = Renderer.render(state_with_oob)
      assert is_map(buffer_oob)
    end
  end

  describe "render/1 with different sections" do
    test "renders home section content" do
      state = create_state(:home)
      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      content_text = extract_content_area(buffer)
      assert String.contains?(content_text, "Blockchain Infrastructure Engineer")
      assert String.contains?(content_text, "Site Structure")
    end

    test "renders projects section content" do
      state = create_state(:projects)
      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      content_text = extract_content_area(buffer)
      assert String.contains?(content_text, "Project Showcase")
      assert String.contains?(content_text, "droo.foo Terminal Portfolio")
      assert String.contains?(content_text, "Real-time Collaboration Platform")
    end

    test "renders skills section content" do
      state = create_state(:skills)
      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      content_text = extract_content_area(buffer)
      assert String.contains?(content_text, "Technical Skills")
      assert String.contains?(content_text, "Elixir")
      assert String.contains?(content_text, "Phoenix")
    end

    test "renders experience section content" do
      state = create_state(:experience)
      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      content_text = extract_content_area(buffer)
      assert String.contains?(content_text, "Experience")
      assert String.contains?(content_text, "CEO") || String.contains?(content_text, "axol.io")
    end

    test "renders contact section content" do
      state = create_state(:contact)
      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      content_text = extract_content_area(buffer)
      assert String.contains?(content_text, "Contact")
      assert String.contains?(content_text, "drew@axol.io")
      assert String.contains?(content_text, "github.com/hydepwns")
    end

    test "renders matrix section content" do
      state = create_state(:matrix)
      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      content_text = extract_content_area(buffer)
      assert String.contains?(content_text, "Matrix Rain")
      assert String.contains?(content_text, "Follow the white rabbit")
    end

    test "renders ssh section content" do
      state = create_state(:ssh)
      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      content_text = extract_content_area(buffer)
      assert String.contains?(content_text, "SSH Session")
      assert String.contains?(content_text, "droo@droo.foo")
    end

    test "renders help section content" do
      state = create_state(:help)
      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      content_text = extract_content_area(buffer)
      assert String.contains?(content_text, "Available Commands")
      assert String.contains?(content_text, ":help")
      # Check for navigation instructions instead
      assert String.contains?(content_text, "hjkl") or
               String.contains?(content_text, "Navigation")
    end

    test "renders ls section content" do
      state = create_state(:ls)
      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      content_text = extract_content_area(buffer)
      assert String.contains?(content_text, "Directory Listing")
      assert String.contains?(content_text, "drwxr-xr-x")
    end

    test "renders performance section content" do
      state = create_state(:performance)
      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      # Extract all buffer text for more flexibility
      buffer_text =
        Enum.map_join(buffer.lines, "\n", fn line ->
          Enum.map_join(line.cells, "", & &1.char)
        end)

      assert String.contains?(buffer_text, "PERFORMANCE") or
               String.contains?(buffer_text, "Render")

      assert String.contains?(buffer_text, "Memory") or String.contains?(buffer_text, "Uptime")
    end

    test "renders analytics section content" do
      state = create_state(:analytics)
      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      content_text = extract_content_area(buffer)
      assert String.contains?(content_text, "Analytics Dashboard")
      assert String.contains?(content_text, "Page Views")
      assert String.contains?(content_text, "Top Commands")
    end

    test "renders terminal section with output" do
      state = %{
        cursor_y: 0,
        current_section: :terminal,
        command_mode: false,
        command_buffer: "",
        trail_enabled: false,
        cursor_trail: nil,
        terminal_output: "$ ls\nfile1.txt\nfile2.txt\n$ pwd\n/home/droo",
        prompt: "[droo@droo ~]$ ",
        help_modal_open: false,
        privacy_mode: false,
        encryption_keys: %{},
        encryption_sessions: %{},
        web3_wallet_connected: false
      }

      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      content_text = extract_content_area(buffer)
      assert String.contains?(content_text, "Terminal")
      assert String.contains?(content_text, "[droo@droo ~]$")
    end

    test "handles unknown section gracefully" do
      state = create_state(:unknown_section)

      # Should not crash
      {buffer, _clickable_regions, _content_height} = Renderer.render(state)
      assert is_map(buffer)
    end
  end

  describe "edge cases and error handling" do
    test "handles malformed state gracefully" do
      # Missing some optional fields
      state = %{
        cursor_y: 0,
        current_section: :home,
        command_mode: false,
        command_buffer: "",
        help_modal_open: false,
        privacy_mode: false,
        encryption_keys: %{},
        encryption_sessions: %{},
        web3_wallet_connected: false
        # Missing other optional fields
      }

      # Should not crash, uses defaults
      {buffer, _clickable_regions, _content_height} = Renderer.render(state)
      assert is_map(buffer)
    end

    test "handles nil state fields" do
      state = %{
        cursor_y: nil,
        current_section: nil,
        command_mode: nil,
        command_buffer: nil,
        trail_enabled: nil,
        cursor_trail: nil,
        terminal_output: nil,
        prompt: nil,
        help_modal_open: false,
        privacy_mode: false,
        encryption_keys: %{},
        encryption_sessions: %{},
        web3_wallet_connected: false
      }

      # Should not crash
      {buffer, _clickable_regions, _content_height} = Renderer.render(state)
      assert is_map(buffer)
    end

    test "handles very long command buffer" do
      long_command = String.duplicate("a", 200)

      state = %{
        cursor_y: 0,
        current_section: :home,
        command_mode: true,
        command_buffer: long_command,
        trail_enabled: false,
        cursor_trail: nil,
        terminal_output: "",
        prompt: "",
        help_modal_open: false,
        privacy_mode: false,
        encryption_keys: %{},
        encryption_sessions: %{},
        web3_wallet_connected: false
      }

      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      # Should truncate or handle gracefully
      last_line = List.last(buffer.lines)
      line_text = Enum.map_join(last_line.cells, "", & &1.char)
      assert String.length(line_text) <= 110
    end

    test "handles very long terminal output" do
      long_output = Enum.map_join(1..100, "\n", &"Line #{&1}")

      state = %{
        cursor_y: 0,
        current_section: :terminal,
        command_mode: false,
        command_buffer: "",
        trail_enabled: false,
        cursor_trail: nil,
        terminal_output: long_output,
        prompt: "[droo@droo ~]$ ",
        help_modal_open: false,
        privacy_mode: false,
        encryption_keys: %{},
        encryption_sessions: %{},
        web3_wallet_connected: false
      }

      {buffer, _clickable_regions, _content_height} = Renderer.render(state)

      # Should only show last 8 lines (as per renderer implementation)
      content_text = extract_content_area(buffer)
      assert String.contains?(content_text, "Line 100")
      assert String.contains?(content_text, "Line 93")
      refute String.contains?(content_text, "Line 92")
    end

    test "handles out-of-range cursor_y values" do
      for cursor_y <- [-10, -1, 5, 10, 100] do
        state = %{
          cursor_y: cursor_y,
          current_section: :home,
          command_mode: false,
          command_buffer: "",
          trail_enabled: false,
          cursor_trail: nil,
          terminal_output: "",
          prompt: "",
          help_modal_open: false,
          privacy_mode: false,
          encryption_keys: %{},
          encryption_sessions: %{},
          web3_wallet_connected: false
        }

        # Should not crash
        {buffer, _clickable_regions, _content_height} = Renderer.render(state)
        assert is_map(buffer)
      end
    end
  end

  # Helper functions

  defp create_state(section) do
    base_state = %{
      cursor_y: 0,
      current_section: section,
      command_mode: false,
      command_buffer: "",
      trail_enabled: false,
      cursor_trail: nil,
      terminal_output: "",
      prompt: if(section == :terminal, do: "[droo@droo ~]$", else: ""),
      help_modal_open: false,
      privacy_mode: false,
      encryption_keys: %{},
      encryption_sessions: %{},
      web3_wallet_connected: false,
      resume_data: Droodotfoo.Resume.ResumeData.get_resume_data(),
      scroll_positions: %{},
      scroll_offset: 0,
      content_height: 0,
      viewport_height: 28
    }

    # Add search_state for search_results section
    if section == :search_results do
      Map.put(base_state, :search_state, %{
        query: "test search",
        mode: :fuzzy,
        results: [
          %{
            section: :projects,
            line: "Test result line",
            line_number: 1,
            match_positions: [0, 1, 2],
            score: 0.85
          }
        ]
      })
    else
      base_state
    end
  end

  defp extract_content_area(buffer) do
    # Extract text from the content area (right side, starting at column 32)
    Enum.map_join(buffer.lines, "\n", fn line ->
      line.cells
      |> Enum.drop(32)
      |> Enum.map_join("", & &1.char)
    end)
  end
end
