defmodule Droodotfoo.CircuitBreakerTest do
  use ExUnit.Case, async: false

  alias Droodotfoo.CircuitBreaker

  setup do
    # Reset circuit state before each test
    CircuitBreaker.reset(:test_service)
    :ok
  end

  describe "call/3" do
    test "allows successful calls through" do
      result = CircuitBreaker.call(:test_service, fn -> {:ok, "success"} end)
      assert result == {:ok, "success"}
    end

    test "records failures and opens circuit after threshold" do
      # Configure low threshold for testing
      CircuitBreaker.configure(:test_service, failure_threshold: 3)

      # Fail 3 times to open the circuit
      for _ <- 1..3 do
        CircuitBreaker.call(:test_service, fn -> {:error, :failed} end)
      end

      # Circuit should now be open
      assert CircuitBreaker.get_state(:test_service) == :open

      # Next call should fail fast
      result = CircuitBreaker.call(:test_service, fn -> {:ok, "should not run"} end)
      assert result == {:error, :circuit_open}
    end

    test "resets failure count on success" do
      CircuitBreaker.configure(:test_service, failure_threshold: 3)

      # Fail twice
      CircuitBreaker.call(:test_service, fn -> {:error, :failed} end)
      CircuitBreaker.call(:test_service, fn -> {:error, :failed} end)

      # Succeed once - should reset counter
      CircuitBreaker.call(:test_service, fn -> {:ok, "success"} end)

      # Fail twice more - should not open circuit
      CircuitBreaker.call(:test_service, fn -> {:error, :failed} end)
      CircuitBreaker.call(:test_service, fn -> {:error, :failed} end)

      assert CircuitBreaker.get_state(:test_service) == :closed
    end

    test "transitions to half-open after timeout" do
      CircuitBreaker.configure(:test_service, failure_threshold: 1, reset_timeout_ms: 10)

      # Open the circuit
      CircuitBreaker.call(:test_service, fn -> {:error, :failed} end)
      assert CircuitBreaker.get_state(:test_service) == :open

      # Wait for reset timeout
      Process.sleep(20)

      # Next call should go through (half-open state)
      result = CircuitBreaker.call(:test_service, fn -> {:ok, "recovered"} end)
      assert result == {:ok, "recovered"}

      # Circuit should be closed again
      assert CircuitBreaker.get_state(:test_service) == :closed
    end

    test "reopens circuit if half-open request fails" do
      CircuitBreaker.configure(:test_service, failure_threshold: 1, reset_timeout_ms: 10)

      # Open the circuit
      CircuitBreaker.call(:test_service, fn -> {:error, :failed} end)

      # Wait for reset timeout
      Process.sleep(20)

      # Fail in half-open state
      CircuitBreaker.call(:test_service, fn -> {:error, :still_failing} end)

      # Circuit should be open again
      assert CircuitBreaker.get_state(:test_service) == :open
    end

    test "handles exceptions gracefully" do
      CircuitBreaker.configure(:test_service, failure_threshold: 1)

      result =
        CircuitBreaker.call(:test_service, fn ->
          raise "boom"
        end)

      assert result == {:error, :exception}
      assert CircuitBreaker.get_state(:test_service) == :open
    end
  end

  describe "status/0" do
    test "returns status of all circuits" do
      CircuitBreaker.call(:service_a, fn -> {:ok, "a"} end)
      CircuitBreaker.call(:service_b, fn -> {:error, :b} end)

      status = CircuitBreaker.status()

      assert Map.has_key?(status, :service_a)
      assert Map.has_key?(status, :service_b)
      assert status[:service_a].state == :closed
    end
  end

  describe "reset/1" do
    test "resets circuit to closed state" do
      CircuitBreaker.configure(:test_service, failure_threshold: 1)
      CircuitBreaker.call(:test_service, fn -> {:error, :failed} end)

      assert CircuitBreaker.get_state(:test_service) == :open

      CircuitBreaker.reset(:test_service)

      assert CircuitBreaker.get_state(:test_service) == :closed
    end
  end
end
