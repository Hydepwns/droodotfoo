defmodule Droodotfoo.Plugins.GitHub do
  @moduledoc """
  GitHub plugin for the terminal interface.
  Provides GitHub activity feed, repository browsing, and search.
  """

  @behaviour Droodotfoo.PluginSystem.Plugin

  alias Droodotfoo.Plugins.GameBase
  alias Droodotfoo.Plugins.GitHub.{ModeHandlers, RenderHelpers}

  import Droodotfoo.Plugins.UIHelpers

  defstruct [
    :mode,
    :username,
    :user_data,
    :repos,
    :activity,
    :current_repo,
    :commits,
    :issues,
    :pulls,
    :search_results,
    :search_query,
    :trending,
    :message,
    :error
  ]

  # Plugin Behaviour Callbacks

  @impl true
  def metadata do
    GameBase.game_metadata(
      "github",
      "1.0.0",
      "GitHub activity feed and repository browser",
      "droo.foo",
      ["github", "gh"],
      :utility
    )
  end

  @impl true
  def init(_terminal_state) do
    {:ok,
     %__MODULE__{
       mode: :input,
       username: nil,
       user_data: nil,
       repos: [],
       activity: [],
       current_repo: nil,
       commits: [],
       issues: [],
       pulls: [],
       search_results: [],
       search_query: "",
       trending: [],
       message: nil,
       error: nil
     }}
  end

  @impl true
  def handle_input(input, state, _terminal_state) do
    input = String.trim(input)

    case input do
      input when input in ["q", "Q", "quit", "exit"] ->
        {:exit, ["GitHub plugin closed."]}

      "help" ->
        {:continue, state, RenderHelpers.render_help()}

      _ ->
        ModeHandlers.handle(state.mode, input, state, &render/2)
    end
  end

  @impl true
  def render(state, _terminal_state) do
    header = header("GITHUB BROWSER", 78)

    mode_indicator = [
      "",
      "Mode: #{state.mode |> to_string() |> String.upcase()}" |> String.pad_trailing(78),
      ""
    ]

    content = RenderHelpers.render_mode_content(state)

    message_section = render_messages(state)

    footer = [
      "-" |> String.duplicate(78),
      "Commands: [h]elp [q]uit  |  Navigate: [m]ain [r]efresh [s]earch [t]rending",
      "-" |> String.duplicate(78)
    ]

    header ++ mode_indicator ++ content ++ message_section ++ footer
  end

  @impl true
  def cleanup(_state) do
    :ok
  end

  # Private helpers

  defp render_messages(%{error: error}) when not is_nil(error) do
    ["", "ERROR: #{error}", ""]
  end

  defp render_messages(%{message: message}) when not is_nil(message) do
    ["", ">> #{message}", ""]
  end

  defp render_messages(_state), do: []
end
