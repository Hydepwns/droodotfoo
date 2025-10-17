defmodule Droodotfoo.Terminal.Commands.Fun do
  @moduledoc """
  Fun command implementations and easter eggs for the terminal.

  Provides commands for:
  - fortune: Display random inspirational quotes
  - cowsay: ASCII cow with speech bubble
  - sl: ASCII steam locomotive animation
  - sudo: Easter egg responses
  - vim: Easter egg vim trap
  - emacs: Easter egg editor joke
  - exit: Exit the terminal session
  """

  @doc """
  Returns a random fortune/inspirational quote.
  """
  def fortune(_state) do
    fortunes = [
      "The only way to do great work is to love what you do. - Steve Jobs",
      "Code is like humor. When you have to explain it, it's bad. - Cory House",
      "First, solve the problem. Then, write the code. - John Johnson",
      "Experience is the name everyone gives to their mistakes. - Oscar Wilde",
      "The best way to predict the future is to invent it. - Alan Kay",
      "Simplicity is the soul of efficiency. - Austin Freeman",
      "Make it work, make it right, make it fast. - Kent Beck"
    ]

    {:ok, Enum.random(fortunes)}
  end

  @doc """
  ASCII cow saying the provided text.
  """
  def cowsay([], _state) do
    cowsay(["moo!"], nil)
  end

  def cowsay(words, _state) do
    text = Enum.join(words, " ")
    width = String.length(text) + 2

    cow = """
     #{"_" |> String.duplicate(width)}
    < #{text} >
     #{"-" |> String.duplicate(width)}
            \\   ^__^
             \\  (oo)\\_______
                (__)\\       )\\/\\
                    ||----w |
                    ||     ||
    """

    {:ok, cow}
  end

  @doc """
  ASCII steam locomotive animation (sl command).
  """
  def sl(_state) do
    train = """
                        (@@) (  ) (@)  ( )  @@    ()    @     O     @
                   (   )
               (@@@@)
            (    )

          (@@@)
        ====        ________                ___________
    _D _|  |_______/        \\__I_I_____===__|_________|
     |(_)---  |   H\\________/ |   |        =|___ ___|
     /     |  |   H  |  |     |   |         ||_| |_||
    |      |  |   H  |__--------------------| [___] |
    | ________|___H__/__|_____/[][]~\\_______|       |
    |/ |   |-----------I_____I [][] []  D   |=======|__
    """

    {:ok, train}
  end

  @doc """
  Easter egg sudo command - catches dangerous commands.
  """
  def sudo(["rm", "-rf", "/"], _state) do
    {:error,
     """
     Nice try! :)

     This is a simulated terminal. No actual files were harmed.
     But I appreciate your commitment to chaos!
     """}
  end

  def sudo(_args, _state) do
    {:ok, "[sudo] password for drew: \n(Just kidding, running without sudo)"}
  end

  @doc """
  Easter egg vim command - the eternal trap.
  """
  def vim([], _state) do
    {:ok,
     """
     VIM - Vi IMproved

     ~
     ~
     ~
     ~  You are now trapped in vim.
     ~
     ~  Quick, press :q! to escape!
     ~  (Just kidding, type 'exit' to leave)
     ~
     ~
     """}
  end

  @doc """
  Easter egg emacs command - friendly editor war joke.
  """
  def emacs([], _state) do
    {:ok, "emacs: Real programmers use vim. (Just kidding, use what you like!)"}
  end

  @doc """
  Exit the terminal session.
  """
  def exit(_state) do
    {:exit, "Goodbye! Thanks for visiting droo.foo"}
  end
end
