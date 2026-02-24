defmodule Droodotfoo.Wiki.Ingestion.MediaWikiClient do
  @moduledoc """
  Rate-limited MediaWiki API client.

  Uses Req for HTTP requests with configurable rate limiting.
  Designed for the OSRS Wiki but works with any MediaWiki instance.

  ## Configuration

      config :droodotfoo, Droodotfoo.Wiki.Ingestion.MediaWikiClient,
        base_url: "https://oldschool.runescape.wiki/api.php",
        user_agent: "DrooFoo-WikiMirror/1.0 (https://droo.foo)",
        rate_limit_ms: 1000

  """

  require Logger

  @type page :: %{
          title: String.t(),
          pageid: integer(),
          revid: integer(),
          html: String.t(),
          wikitext: String.t() | nil
        }

  @type recent_change :: %{
          title: String.t(),
          pageid: integer(),
          revid: integer(),
          timestamp: DateTime.t(),
          type: String.t()
        }

  @rate_limit_table :mediawiki_rate_limit

  @doc """
  Initialize the rate limiter. Called by application supervisor.
  """
  def init do
    :ets.new(@rate_limit_table, [:set, :public, :named_table])
    :ok
  rescue
    ArgumentError -> :ok
  end

  @doc """
  Get a single page by title with parsed HTML.
  """
  @spec get_page(String.t(), keyword()) :: {:ok, page()} | {:error, term()}
  def get_page(title, opts \\ []) do
    rate_limit()

    params = %{
      action: "parse",
      page: title,
      format: "json",
      prop: "text|wikitext|revid"
    }

    case request(params, opts) do
      {:ok, %{"parse" => data}} ->
        {:ok,
         %{
           title: data["title"],
           pageid: data["pageid"],
           revid: data["revid"],
           html: get_in(data, ["text", "*"]) || "",
           wikitext: get_in(data, ["wikitext", "*"])
         }}

      {:ok, %{"error" => %{"code" => "missingtitle"}}} ->
        {:error, :not_found}

      {:ok, %{"error" => error}} ->
        {:error, {:api_error, error["code"], error["info"]}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get multiple pages by title (batched).
  """
  @spec get_pages([String.t()], keyword()) :: {:ok, %{String.t() => page()}} | {:error, term()}
  def get_pages(titles, opts \\ []) when is_list(titles) do
    titles
    |> Enum.chunk_every(50)
    |> Enum.reduce_while({:ok, %{}}, fn batch, {:ok, acc} ->
      case get_pages_batch(batch, opts) do
        {:ok, pages} -> {:cont, {:ok, Map.merge(acc, pages)}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp get_pages_batch(titles, opts) do
    rate_limit()

    params = %{
      action: "query",
      titles: Enum.join(titles, "|"),
      format: "json",
      prop: "revisions",
      rvprop: "content|ids",
      rvslots: "main"
    }

    case request(params, opts) do
      {:ok, %{"query" => %{"pages" => pages}}} ->
        result =
          pages
          |> Enum.reject(fn {_id, page} -> Map.has_key?(page, "missing") end)
          |> Enum.map(fn {_id, page} ->
            revision = get_in(page, ["revisions", Access.at(0)]) || %{}
            wikitext = get_in(revision, ["slots", "main", "*"]) || ""

            {page["title"],
             %{
               title: page["title"],
               pageid: page["pageid"],
               revid: revision["revid"],
               html: nil,
               wikitext: wikitext
             }}
          end)
          |> Map.new()

        {:ok, result}

      {:ok, %{"error" => error}} ->
        {:error, {:api_error, error["code"], error["info"]}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get recent changes since a timestamp.
  """
  @spec recent_changes(DateTime.t() | nil, keyword()) ::
          {:ok, [recent_change()]} | {:error, term()}
  def recent_changes(since \\ nil, opts \\ []) do
    limit = Keyword.get(opts, :limit, 500)

    params =
      %{
        action: "query",
        list: "recentchanges",
        format: "json",
        rcprop: "title|ids|timestamp",
        rclimit: min(limit, 500),
        rctype: "edit|new",
        rcnamespace: "0"
      }
      |> maybe_add_since(since)

    fetch_all_recent_changes(params, [], limit, opts)
  end

  defp fetch_all_recent_changes(_params, acc, limit, _opts) when length(acc) >= limit do
    {:ok, Enum.take(acc, limit)}
  end

  defp fetch_all_recent_changes(params, acc, limit, opts) do
    rate_limit()

    case request(params, opts) do
      {:ok, %{"query" => %{"recentchanges" => changes}} = response} ->
        parsed =
          Enum.map(changes, fn rc ->
            %{
              title: rc["title"],
              pageid: rc["pageid"],
              revid: rc["revid"],
              timestamp: parse_timestamp(rc["timestamp"]),
              type: rc["type"]
            }
          end)

        new_acc = acc ++ parsed

        case get_in(response, ["continue", "rccontinue"]) do
          nil ->
            {:ok, new_acc}

          continue_token when length(new_acc) < limit ->
            params
            |> Map.put(:rccontinue, continue_token)
            |> fetch_all_recent_changes(new_acc, limit, opts)

          _continue_token ->
            {:ok, Enum.take(new_acc, limit)}
        end

      {:ok, %{"error" => error}} ->
        {:error, {:api_error, error["code"], error["info"]}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get all pages in a category.
  """
  @spec category_members(String.t(), keyword()) :: {:ok, [String.t()]} | {:error, term()}
  def category_members(category, opts \\ []) do
    limit = Keyword.get(opts, :limit, 5000)
    category_title = normalize_category(category)

    params = %{
      action: "query",
      list: "categorymembers",
      cmtitle: category_title,
      format: "json",
      cmlimit: min(limit, 500),
      cmnamespace: "0"
    }

    fetch_all_category_members(params, [], limit, opts)
  end

  defp fetch_all_category_members(_params, acc, limit, _opts) when length(acc) >= limit do
    {:ok, Enum.take(acc, limit)}
  end

  defp fetch_all_category_members(params, acc, limit, opts) do
    rate_limit()

    case request(params, opts) do
      {:ok, %{"query" => %{"categorymembers" => members}} = response} ->
        titles = Enum.map(members, & &1["title"])
        new_acc = acc ++ titles

        case get_in(response, ["continue", "cmcontinue"]) do
          nil ->
            {:ok, new_acc}

          continue_token when length(new_acc) < limit ->
            params
            |> Map.put(:cmcontinue, continue_token)
            |> fetch_all_category_members(new_acc, limit, opts)

          _continue_token ->
            {:ok, Enum.take(new_acc, limit)}
        end

      {:ok, %{"error" => error}} ->
        {:error, {:api_error, error["code"], error["info"]}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Search pages by text.
  """
  @spec search(String.t(), keyword()) :: {:ok, [String.t()]} | {:error, term()}
  def search(query, opts \\ []) do
    rate_limit()

    limit = Keyword.get(opts, :limit, 50)

    params = %{
      action: "query",
      list: "search",
      srsearch: query,
      format: "json",
      srlimit: min(limit, 500),
      srnamespace: "0"
    }

    case request(params, opts) do
      {:ok, %{"query" => %{"search" => results}}} ->
        {:ok, Enum.map(results, & &1["title"])}

      {:ok, %{"error" => error}} ->
        {:error, {:api_error, error["code"], error["info"]}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private helpers

  defp request(params, opts) do
    base_url = config(:base_url)
    user_agent = config(:user_agent)

    req_opts =
      [
        base_url: base_url,
        headers: [{"user-agent", user_agent}],
        params: params,
        receive_timeout: Keyword.get(opts, :timeout, 30_000)
      ]
      |> maybe_add_bypass(opts)

    case Req.get(req_opts) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        {:ok, body}

      {:ok, %{status: 200, body: body}} when is_binary(body) ->
        case Jason.decode(body) do
          {:ok, decoded} -> {:ok, decoded}
          {:error, reason} -> {:error, {:json_decode_error, reason}}
        end

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:request_error, reason}}
    end
  end

  defp maybe_add_bypass(opts, keyword_opts) do
    case Keyword.get(keyword_opts, :bypass) do
      nil -> opts
      bypass -> Keyword.put(opts, :plug, {Bypass, bypass})
    end
  end

  defp maybe_add_since(params, nil), do: params

  defp maybe_add_since(params, %DateTime{} = since) do
    Map.put(params, :rcend, DateTime.to_iso8601(since))
  end

  defp parse_timestamp(nil), do: nil

  defp parse_timestamp(ts) do
    case DateTime.from_iso8601(ts) do
      {:ok, dt, _offset} -> dt
      _ -> nil
    end
  end

  defp normalize_category(cat) do
    if String.starts_with?(cat, "Category:") do
      cat
    else
      "Category:" <> cat
    end
  end

  defp rate_limit do
    rate_limit_ms = config(:rate_limit_ms) || 1000

    case :ets.lookup(@rate_limit_table, :last_request) do
      [{:last_request, last}] ->
        elapsed = System.monotonic_time(:millisecond) - last
        wait = max(0, rate_limit_ms - elapsed)

        if wait > 0 do
          Process.sleep(wait)
        end

      [] ->
        :ok
    end

    :ets.insert(@rate_limit_table, {:last_request, System.monotonic_time(:millisecond)})
  end

  defp config(key) do
    Application.get_env(:droodotfoo, __MODULE__, [])
    |> Keyword.get(key)
  end
end
