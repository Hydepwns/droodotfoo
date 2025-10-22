defmodule Droodotfoo.Features.SSHContent do
  @moduledoc """
  Content for SSH simulator including banners, MOTD, and help text.
  """

  @doc """
  Returns the SSH login banner.
  """
  def banner do
    """
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                     SSH droo.foo Terminal v1.0                       ║
    ║                                                                      ║
    ║  Welcome to droo.foo secure shell access                             ║
    ║  Unauthorized access is prohibited and monitored                     ║
    ╚══════════════════════════════════════════════════════════════════════╝
    """
  end

  @doc """
  Returns the message of the day (MOTD).
  Dynamically loads support email from resume data.
  """
  def motd do
    {:ok, now} = DateTime.now("Europe/Madrid")
    resume = Droodotfoo.Resume.ResumeData.get_resume_data()

    """
    Last login: #{now |> DateTime.to_string()}

    Welcome to droo.foo OS 1.0 LTS (GNU/Linux 5.15.0-91-generic x86_64)

     * Documentation:  https://droo.foo/docs
     * Management:     https://droo.foo/admin
     * Support:        #{resume.contact.email}

    System information as of #{now |> DateTime.truncate(:second) |> DateTime.to_string()}:

      System load:  0.08               Processes:           121
      Usage of /:   42.0% of 20.04GB   Users logged in:     1
      Memory usage: 23%                IP address:          10.0.0.42
      Swap usage:   0%

    """
  end

  @doc """
  Returns the README content displayed by `cat README.md`.
  """
  def readme do
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

  @doc """
  Returns help content for SSH commands.
  """
  def help do
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
