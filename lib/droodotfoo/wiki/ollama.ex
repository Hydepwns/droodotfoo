defmodule Droodotfoo.Wiki.Ollama do
  @moduledoc """
  HTTP client for Ollama embedding API.

  Uses nomic-embed-text model (768 dimensions, 8192 token context).
  Connects to Ollama running on mini-axol's RTX 2080.
  """

  require Logger

  @default_model "nomic-embed-text"
  @max_chars 4000

  @doc """
  Generate embedding for a single text.

  Options:
    - `:timeout` - request timeout in ms (default: config timeout)

  Returns `{:ok, [float()]}` or `{:error, reason}`.
  """
  @spec embed(String.t(), keyword()) :: {:ok, [float()]} | {:error, term()}
  def embed(text, opts \\ []) when is_binary(text) do
    case embed_batch([text], opts) do
      {:ok, [embedding]} -> {:ok, embedding}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Generate embeddings for multiple texts in a single request.

  More efficient than calling embed/1 multiple times.

  Options:
    - `:timeout` - request timeout in ms (default: config timeout)

  Returns `{:ok, [[float()]]}` or `{:error, reason}`.
  """
  @spec embed_batch([String.t()], keyword()) :: {:ok, [[float()]]} | {:error, term()}
  def embed_batch(texts, opts \\ []) when is_list(texts) do
    config = config()
    url = "#{config.base_url}/api/embed"
    timeout = Keyword.get(opts, :timeout, config.timeout)

    body = %{
      model: config.model,
      input: texts
    }

    case Req.post(url, json: body, receive_timeout: timeout) do
      {:ok, %{status: 200, body: %{"embeddings" => embeddings}}} ->
        {:ok, embeddings}

      {:ok, %{status: status, body: body}} ->
        Logger.error("Ollama embed failed: status=#{status} body=#{inspect(body)}")
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        Logger.error("Ollama embed request failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Check if Ollama is healthy and model is loaded.
  """
  @spec health_check() :: :ok | {:error, term()}
  def health_check do
    config = config()
    url = "#{config.base_url}/api/tags"

    case Req.get(url, receive_timeout: 5_000) do
      {:ok, %{status: 200, body: %{"models" => models}}} ->
        # Model names may include tags like "nomic-embed-text:latest"
        # Check if any model starts with our configured model name
        model_loaded? =
          Enum.any?(models, fn m ->
            name = m["name"] || ""
            name == config.model or String.starts_with?(name, "#{config.model}:")
          end)

        if model_loaded? do
          :ok
        else
          {:error, {:model_not_loaded, config.model}}
        end

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Prepare text for embedding by concatenating title and content,
  then truncating to fit within model context window.

  nomic-embed-text supports 8192 tokens (~32K chars), but we truncate
  to 8000 chars for safety margin.
  """
  @spec prepare_text(String.t(), String.t() | nil) :: String.t()
  def prepare_text(title, text) do
    content = (text || "") |> String.trim()
    full_text = "#{title}\n\n#{content}"

    if String.length(full_text) > @max_chars do
      String.slice(full_text, 0, @max_chars)
    else
      full_text
    end
  end

  defp config do
    %{
      base_url:
        Application.get_env(:droodotfoo, __MODULE__, [])[:base_url] || "http://localhost:11434",
      model: Application.get_env(:droodotfoo, __MODULE__, [])[:model] || @default_model,
      timeout: Application.get_env(:droodotfoo, __MODULE__, [])[:timeout] || 60_000
    }
  end
end
