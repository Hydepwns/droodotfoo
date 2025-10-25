defmodule Droodotfoo.Features.SSHSimulator do
  @moduledoc """
  Simulates SSH login experience for the droo.foo.
  """

  alias Droodotfoo.Features.SSHContent

  defstruct [:state, :username, :authenticated, :login_attempts]

  def init_session do
    %__MODULE__{
      state: :connecting,
      username: nil,
      authenticated: false,
      login_attempts: 0
    }
  end

  def process_input(session, input) do
    case session.state do
      :connecting ->
        handle_connect(session, input)

      :login ->
        handle_login(session, input)

      :password ->
        handle_password(session, input)

      :authenticated ->
        handle_command(session, input)

      _ ->
        session
    end
  end

  defp handle_connect(session, "ssh" <> _) do
    %{session | state: :login}
    |> with_output(SSHContent.banner() <> "\nlogin as: ")
  end

  defp handle_connect(session, _) do
    session
    |> with_output("Type 'ssh droo@droo.foo' to connect\n")
  end

  defp handle_login(session, username) do
    %{session | username: username, state: :password}
    |> with_output("#{username}@droo.foo's password: ")
  end

  defp handle_password(session, _password) do
    # Accept any password for demo purposes
    %{session | authenticated: true, state: :authenticated}
    |> with_output("\n" <> SSHContent.motd() <> "\n[#{session.username}@droo ~]$ ")
  end

  defp handle_command(session, command) do
    output = execute_ssh_command(command, session)

    if command == "exit" do
      disconnect_session(session, output)
    else
      continue_session(session, output)
    end
  end

  defp execute_ssh_command("ls", _session),
    do: "README.md  projects/  skills/  experience/  contact/"

  defp execute_ssh_command("pwd", session), do: "/home/#{session.username}"
  defp execute_ssh_command("whoami", session), do: session.username

  defp execute_ssh_command("uname -a", _session),
    do: "Linux droo 5.15.0-91-generic #101-Ubuntu SMP x86_64 GNU/Linux"

  defp execute_ssh_command("cat README.md", _session), do: SSHContent.readme()
  defp execute_ssh_command("exit", _session), do: "logout\nConnection to droo.foo closed."
  defp execute_ssh_command("help", _session), do: SSHContent.help()
  defp execute_ssh_command(cmd, _session), do: "#{cmd}: command not found"

  defp disconnect_session(session, output) do
    %{session | state: :connecting, authenticated: false}
    |> with_output(output <> "\n")
  end

  defp continue_session(session, output) do
    session
    |> with_output(output <> "\n[#{session.username}@droo ~]$ ")
  end

  defp with_output(session, output) do
    {session, output}
  end
end
