defmodule Droodotfoo.Features.SSHContentTest do
  use ExUnit.Case, async: true

  alias Droodotfoo.Features.SSHContent

  describe "banner/0" do
    test "returns SSH banner string" do
      result = SSHContent.banner()
      assert is_binary(result)
      assert result =~ "SSH"
      assert result =~ "droo.foo"
    end

    test "includes security warning" do
      result = SSHContent.banner()
      assert result =~ "Unauthorized"
    end
  end

  describe "motd/0" do
    test "returns MOTD with system information" do
      result = SSHContent.motd()
      assert is_binary(result)
      assert result =~ "Last login:"
      assert result =~ "System information"
    end

    test "includes documentation links" do
      result = SSHContent.motd()
      assert result =~ "Documentation"
      assert result =~ "droo.foo"
    end

    test "includes system stats" do
      result = SSHContent.motd()
      assert result =~ "Memory usage"
      assert result =~ "Processes"
    end
  end

  describe "readme/0" do
    test "returns README content" do
      result = SSHContent.readme()
      assert is_binary(result)
      assert result =~ "# droo.foo Terminal System"
    end

    test "lists available commands" do
      result = SSHContent.readme()
      assert result =~ "ls"
      assert result =~ "cat"
      assert result =~ "cd"
      assert result =~ "help"
      assert result =~ "exit"
    end

    test "lists directories" do
      result = SSHContent.readme()
      assert result =~ "projects/"
      assert result =~ "skills/"
      assert result =~ "experience/"
    end
  end

  describe "help/0" do
    test "returns help text" do
      result = SSHContent.help()
      assert is_binary(result)
      assert result =~ "Available commands"
    end

    test "documents all basic commands" do
      result = SSHContent.help()
      assert result =~ "ls"
      assert result =~ "cat"
      assert result =~ "cd"
      assert result =~ "pwd"
      assert result =~ "whoami"
      assert result =~ "clear"
      assert result =~ "exit"
    end
  end
end
