if Mix.env() == :dev do
  defmodule Droodotfoo.Dev.FileWatcher do
    @moduledoc """
    Watches for changes to resume.json and posts in development.
    Automatically refreshes caches when files change.
    """

    use GenServer
    require Logger

    def start_link(_opts) do
      GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
    end

    @impl true
    def init(:ok) do
      # Subscribe to Phoenix LiveReload file system events
      Phoenix.PubSub.subscribe(Droodotfoo.PubSub, "phoenix:live_reload:file_event")
      {:ok, %{}}
    end

    @impl true
    def handle_info({:phoenix_live_reload, :file_event, _path}, state) do
      # Phoenix sends file change events through PubSub
      # The live_reload patterns will catch resume.json and posts changes
      refresh_caches()
      {:noreply, state}
    end

    def handle_info(_msg, state) do
      {:noreply, state}
    end

    defp refresh_caches do
      # Refresh resume data cache
      Droodotfoo.Resume.ResumeData.refresh_resume_data()
      Logger.info("FileWatcher: Refreshed resume data cache")

      # Refresh posts cache
      Droodotfoo.Content.Posts.reload()
      Logger.info("FileWatcher: Refreshed posts cache")
    end
  end
end
