defmodule WikiWeb.LandingLive do
  @moduledoc """
  Landing page for wiki.droo.foo
  """

  use WikiWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "droo.foo wiki")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-4xl mx-auto px-4 py-8">
        <h1 class="text-3xl font-mono font-bold mb-6">droo.foo wiki</h1>

        <p class="text-zinc-400 mb-8 font-mono">
          Federated wiki mirror. OSRS, nLab, Wikipedia, and more.
        </p>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
          <.source_card
            title="OSRS Wiki"
            description="Old School RuneScape items, monsters, quests"
            href="/osrs"
            count={0}
          />
          <.source_card
            title="nLab"
            description="Mathematics and physics wiki"
            href="/nlab"
            count={0}
          />
        </div>

        <div class="mt-12">
          <.link navigate="/search" class="text-blue-400 hover:underline font-mono">
            Search all sources ->
          </.link>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp source_card(assigns) do
    ~H"""
    <.link
      navigate={@href}
      class="block p-6 bg-zinc-900 border border-zinc-800 rounded hover:border-zinc-700 transition"
    >
      <h2 class="text-xl font-mono font-bold text-white mb-2">{@title}</h2>
      <p class="text-zinc-500 font-mono text-sm mb-4">{@description}</p>
      <span class="text-zinc-600 font-mono text-xs">{@count} articles</span>
    </.link>
    """
  end
end
