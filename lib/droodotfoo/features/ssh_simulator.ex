defmodule Droodotfoo.Features.SSHSimulator do
  @moduledoc """
  Simulates SSH login experience for the droo.foo.
  """

  defstruct [:state, :username, :authenticated, :login_attempts]

  @banner """
  ╔══════════════════════════════════════════════════════════════════════╗
  ║                     SSH droo.foo Terminal v1.0                       ║
  ║                                                                      ║
  ║  Welcome to droo.foo secure shell access                             ║
  ║  Unauthorized access is prohibited and monitored                     ║
  ╚══════════════════════════════════════════════════════════════════════╝
  """

  @motd """
  Last login: #{DateTime.utc_now() |> DateTime.to_string()}

  Welcome to droo.foo OS 1.0 LTS (GNU/Linux 5.15.0-91-generic x86_64)

   * Documentation:  https://droo.foo/docs
   * Management:     https://droo.foo/admin
   * Support:        drew@axol.io

  System information as of #{DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_string()}:

    System load:  0.08               Processes:           121
    Usage of /:   42.0% of 20.04GB   Users logged in:     1
    Memory usage: 23%                IP address:          10.0.0.42
    Swap usage:   0%

  """

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
    |> with_output(@banner <> "\nlogin as: ")
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
    |> with_output("\n" <> @motd <> "\n[#{session.username}@droo ~]$ ")
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

  defp execute_ssh_command("cat README.md", _session), do: get_readme_content()
  defp execute_ssh_command("exit", _session), do: "logout\nConnection to droo.foo closed."
  defp execute_ssh_command("help", _session), do: get_help_content()
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

  defp get_readme_content do
    """
    # droo.foo Terminal System

    Welcome to my interactive droo.foo terminal!

    ## Available Commands:
    - ls         : List directory contents
    - cat <file> : Display file contents
    - cd <dir>   : Change directory
    - help       : Show available commands
    - exit       : Disconnect from SSH

    ## Directories:
    - projects/   : My recent projects
    - skills/     : Technical skills
    - experience/ : Work experience
    - contact/    : Contact information
    """
  end

  defp get_help_content do
    """
    GNU bash, version 5.1.16(1)-release
    Available commands:
      ls          List directory contents
      cat         Display file contents
      cd          Change directory
      pwd         Print working directory
      whoami      Display current user
      uname       System information
      clear       Clear the terminal
      help        Show this help message
      exit        Exit the SSH session
    """
  end
end
