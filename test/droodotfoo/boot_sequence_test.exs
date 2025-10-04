defmodule Droodotfoo.BootSequenceTest do
  use ExUnit.Case, async: true
  alias Droodotfoo.BootSequence

  describe "steps/0" do
    test "returns list of boot steps with delays" do
      steps = BootSequence.steps()
      assert is_list(steps)
      assert length(steps) == 6

      # Each step should be a tuple of {message, delay}
      Enum.each(steps, fn step ->
        assert {_msg, delay} = step
        assert is_binary(_msg)
        assert is_integer(delay)
        assert delay > 0
      end)
    end

    test "first step contains version info" do
      [{first_msg, _delay} | _rest] = BootSequence.steps()
      assert String.contains?(first_msg, "RAXOL TERMINAL")
      assert String.match?(first_msg, ~r/v\d+\.\d+\.\d+/)
    end

    test "steps include system initialization messages" do
      steps = BootSequence.steps()
      messages = Enum.map(steps, fn {msg, _} -> msg end)

      assert Enum.any?(messages, &String.contains?(&1, "kernel"))
      assert Enum.any?(messages, &String.contains?(&1, "modules"))
      assert Enum.any?(messages, &String.contains?(&1, "Phoenix LiveView"))
      assert Enum.any?(messages, &String.contains?(&1, "WebSocket"))
      assert Enum.any?(messages, &String.contains?(&1, "Ready"))
    end
  end

  describe "total_steps/0" do
    test "returns the correct total number of steps" do
      assert BootSequence.total_steps() == 6
    end
  end

  describe "delay_for_step/1" do
    test "returns delay for valid step numbers" do
      # Step 1 should have a delay
      delay1 = BootSequence.delay_for_step(1)
      assert is_integer(delay1)
      assert delay1 > 0

      # Step 6 (last step) should have a delay
      delay6 = BootSequence.delay_for_step(6)
      assert is_integer(delay6)
      assert delay6 > 0
    end

    test "returns 0 for invalid step numbers" do
      assert BootSequence.delay_for_step(0) == 0
      assert BootSequence.delay_for_step(-1) == 0
      assert BootSequence.delay_for_step(7) == 0
      assert BootSequence.delay_for_step(100) == 0
    end
  end

  describe "render/1" do
    test "returns empty lines for step 0" do
      lines = BootSequence.render(0)
      assert is_list(lines)
      # Should have spacing but no content
      assert Enum.all?(lines, &(&1 == ""))
    end

    test "returns first step for step 1" do
      lines = BootSequence.render(1)
      assert is_list(lines)
      # Should have spacing + 1 message + spacing
      assert length(lines) == 4

      # Skip empty lines and find the version message
      content_lines = Enum.reject(lines, &(&1 == ""))
      assert length(content_lines) == 1
      assert String.contains?(hd(content_lines), "RAXOL TERMINAL")
    end

    test "returns all steps for step 6" do
      lines = BootSequence.render(6)
      assert is_list(lines)
      # Should have spacing + 6 messages + spacing
      assert length(lines) == 9

      content_lines = Enum.reject(lines, &(&1 == ""))
      assert length(content_lines) == 6
    end

    test "returns empty for invalid step numbers" do
      assert BootSequence.render(-1) == []
      assert BootSequence.render(7) == []
      assert BootSequence.render(100) == []
    end

    test "renders steps incrementally" do
      # Simulate progressive rendering
      step1_lines = BootSequence.render(1)
      step2_lines = BootSequence.render(2)
      step3_lines = BootSequence.render(3)

      # Each subsequent step should have more content
      content1 = Enum.reject(step1_lines, &(&1 == ""))
      content2 = Enum.reject(step2_lines, &(&1 == ""))
      content3 = Enum.reject(step3_lines, &(&1 == ""))

      assert length(content1) == 1
      assert length(content2) == 2
      assert length(content3) == 3
    end
  end

  describe "complete?/1" do
    test "returns false for steps in progress" do
      refute BootSequence.complete?(0)
      refute BootSequence.complete?(1)
      refute BootSequence.complete?(5)
      refute BootSequence.complete?(6)
    end

    test "returns true when all steps are done" do
      assert BootSequence.complete?(7)
      assert BootSequence.complete?(100)
    end
  end

  describe "welcome_message/0" do
    test "returns a list of welcome lines" do
      lines = BootSequence.welcome_message()
      assert is_list(lines)
      assert length(lines) > 0
    end

    test "welcome message contains instructions" do
      lines = BootSequence.welcome_message()
      message = Enum.join(lines, " ")

      assert String.contains?(message, "droo.foo")
      assert String.contains?(message, "help")
    end
  end

  describe "boot sequence timing" do
    test "total boot time is reasonable" do
      # Calculate total boot time
      total_time =
        1..6
        |> Enum.map(&BootSequence.delay_for_step/1)
        |> Enum.sum()

      # Boot should complete in under 2 seconds
      assert total_time < 2000
      # But should take at least 1 second for good effect
      assert total_time >= 1000
    end

    test "delays are progressive and reasonable" do
      delays = Enum.map(1..6, &BootSequence.delay_for_step/1)

      # Each delay should be between 100ms and 500ms
      Enum.each(delays, fn delay ->
        assert delay >= 100
        assert delay <= 500
      end)
    end
  end
end
