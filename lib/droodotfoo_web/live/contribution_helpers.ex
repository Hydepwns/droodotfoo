defmodule DroodotfooWeb.ContributionHelpers do
  @moduledoc """
  Shared contribution graph loading for LiveViews.
  Handles PubSub subscription, async fetch, and grid computation.
  """

  alias Droodotfoo.GitHub.Contributions

  defmacro __using__(_opts) do
    quote do
      @impl true
      def handle_info(:load_contributions, socket) do
        grid =
          case Contributions.fetch_and_broadcast() do
            {:ok, data} -> DroodotfooWeb.GithubComponents.to_grid(data)
            {:error, _} -> nil
          end

        {:noreply,
         socket
         |> assign(:contribution_grid, grid)
         |> assign(:contributions_loading, false)}
      end

      @impl true
      def handle_info({:contribution_data, data}, socket) do
        {:noreply,
         socket
         |> assign(:contribution_grid, DroodotfooWeb.GithubComponents.to_grid(data))
         |> assign(:contributions_loading, false)}
      end
    end
  end

  @doc "Default assigns for contribution graph loading state."
  def contribution_assigns do
    [contribution_grid: nil, contributions_loading: true]
  end

  @doc "Subscribe and trigger async load. Call in mount when connected."
  def init_contributions do
    Contributions.subscribe()
    send(self(), :load_contributions)
  end
end
