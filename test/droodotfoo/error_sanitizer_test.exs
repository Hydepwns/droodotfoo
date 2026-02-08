defmodule Droodotfoo.ErrorSanitizerTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.ErrorSanitizer

  describe "sanitize/1" do
    test "extracts message from map with :message key" do
      assert ErrorSanitizer.sanitize(%{message: "Connection failed"}) == "Connection failed"
    end

    test "extracts reason from map with :reason key" do
      assert ErrorSanitizer.sanitize(%{reason: "timeout"}) == "timeout"
    end

    test "returns string as-is" do
      assert ErrorSanitizer.sanitize("Some error") == "Some error"
    end

    test "extracts message from exception struct" do
      error = %RuntimeError{message: "oops"}
      assert ErrorSanitizer.sanitize(error) == "oops"
    end

    test "handles ArgumentError" do
      error = %ArgumentError{message: "bad argument"}
      assert ErrorSanitizer.sanitize(error) == "bad argument"
    end

    test "converts atom to string" do
      assert ErrorSanitizer.sanitize(:unknown_error) == "unknown_error"
      assert ErrorSanitizer.sanitize(:timeout) == "timeout"
    end

    test "returns generic message for unknown types" do
      assert ErrorSanitizer.sanitize(123) == "An error occurred"
      assert ErrorSanitizer.sanitize([1, 2, 3]) == "An error occurred"
      assert ErrorSanitizer.sanitize({:error, :reason}) == "An error occurred"
    end

    test "handles struct without exception" do
      # Use a known struct that's not an exception
      uri = %URI{host: "example.com", path: "/test"}
      result = ErrorSanitizer.sanitize(uri)
      assert result =~ "URI"
    end
  end
end
