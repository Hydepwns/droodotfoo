defmodule Droodotfoo.Resume.FileverseLoader do
  @moduledoc """
  Loads resume data from Fileverse/IPFS.

  Supports loading resume from:
  - IPFS CID (e.g., "QmHash...")
  - Fileverse document URL (e.g., "https://docs.fileverse.io/...")
  - Direct IPFS gateway URL

  Resume data should be stored as JSON with the following structure:

  ```json
  {
    "personal_info": {
      "name": "Your Name",
      "title": "Your Title",
      "location": "Location",
      "timezone": "Europe/Madrid",
      "website": "https://your-site.com",
      "languages": {"english": "native"}
    },
    "summary": "Professional summary...",
    "availability": "open_to_consulting",
    "focus_areas": ["Area 1", "Area 2"],
    "experience": [
      {
        "company": "Company Name",
        "position": "Position",
        "location": "Remote",
        "employment_type": "full-time",
        "start_date": "2020-01",
        "end_date": "Current",
        "description": "Job description",
        "achievements": ["Achievement 1", "Achievement 2"],
        "technologies": {
          "languages": ["Elixir", "JavaScript"],
          "frameworks": ["Phoenix"],
          "tools": ["Docker"]
        }
      }
    ],
    "education": [...],
    "defense_projects": [...],
    "portfolio": {
      "organization": {...},
      "projects": [...]
    },
    "certifications": [...],
    "contact": {...}
  }
  ```

  ## Configuration

  Set the resume source in your config:

      config :droodotfoo, :resume_source,
        type: :ipfs,  # or :fileverse
        cid: "QmYourCIDHere..."

  Or via environment variable:

      export RESUME_IPFS_CID="QmYourCIDHere..."
  """

  require Logger

  alias Droodotfoo.Web3.IPFS
  alias Droodotfoo.Resume.ResumeData

  @doc """
  Loads resume from configured Fileverse/IPFS source.

  Returns `{:ok, resume_data}` on success, falls back to default on error.
  """
  @spec load() :: {:ok, map()} | {:error, term()}
  def load do
    case get_resume_source() do
      {:ok, source} ->
        fetch_resume(source)

      {:error, :no_source} ->
        Logger.info("No Fileverse resume source configured, using default")
        {:ok, ResumeData.get_resume_data()}
    end
  end

  @doc """
  Loads resume from a specific IPFS CID.

  ## Examples

      iex> FileverseLoader.load_from_cid("QmHash...")
      {:ok, %{personal_info: %{...}, experience: [...]}}
  """
  @spec load_from_cid(String.t()) :: {:ok, map()} | {:error, term()}
  def load_from_cid(cid) when is_binary(cid) do
    fetch_resume({:ipfs, cid})
  end

  @doc """
  Loads resume from a Fileverse document URL.

  Extracts the CID from the URL and fetches the content.

  ## Examples

      iex> FileverseLoader.load_from_url("https://docs.fileverse.io/doc/QmHash...")
      {:ok, %{personal_info: %{...}, experience: [...]}}
  """
  @spec load_from_url(String.t()) :: {:ok, map()} | {:error, term()}
  def load_from_url(url) when is_binary(url) do
    case extract_cid_from_url(url) do
      {:ok, cid} -> load_from_cid(cid)
      {:error, _} = error -> error
    end
  end

  @doc """
  Validates that resume data has the required structure.
  """
  @spec valid_resume?(map()) :: boolean()
  def valid_resume?(data) when is_map(data) do
    # Check for essential fields
    has_personal_info = Map.has_key?(data, :personal_info) or Map.has_key?(data, "personal_info")
    has_experience = Map.has_key?(data, :experience) or Map.has_key?(data, "experience")

    has_personal_info and has_experience
  end

  def valid_resume?(_), do: false

  # Private Functions

  defp get_resume_source do
    # Check environment variable first
    cond do
      cid = System.get_env("RESUME_IPFS_CID") ->
        {:ok, {:ipfs, cid}}

      url = System.get_env("RESUME_FILEVERSE_URL") ->
        {:ok, {:url, url}}

      # Check application config
      config = Application.get_env(:droodotfoo, :resume_source) ->
        parse_config_source(config)

      true ->
        {:error, :no_source}
    end
  end

  defp parse_config_source(config) do
    case Keyword.get(config, :type) do
      :ipfs ->
        if cid = Keyword.get(config, :cid) do
          {:ok, {:ipfs, cid}}
        else
          {:error, :missing_cid}
        end

      :fileverse ->
        if url = Keyword.get(config, :url) do
          {:ok, {:url, url}}
        else
          {:error, :missing_url}
        end

      _ ->
        {:error, :invalid_config}
    end
  end

  defp fetch_resume({:ipfs, cid}) do
    Logger.info("Fetching resume from IPFS: #{cid}")

    case IPFS.cat(cid, timeout: 15_000) do
      {:ok, %{data: data}} ->
        parse_resume_json(data)

      {:error, reason} ->
        Logger.warning("Failed to fetch resume from IPFS: #{inspect(reason)}")
        {:error, {:ipfs_fetch_failed, reason}}
    end
  end

  defp fetch_resume({:url, url}) do
    Logger.info("Fetching resume from URL: #{url}")

    case extract_cid_from_url(url) do
      {:ok, cid} ->
        fetch_resume({:ipfs, cid})

      {:error, _} = error ->
        error
    end
  end

  defp parse_resume_json(data) when is_binary(data) do
    case Jason.decode(data, keys: :atoms) do
      {:ok, resume_data} ->
        if valid_resume?(resume_data) do
          Logger.info("Successfully loaded resume from Fileverse")
          {:ok, normalize_resume_data(resume_data)}
        else
          Logger.warning("Invalid resume structure in Fileverse document")
          {:error, :invalid_structure}
        end

      {:error, reason} ->
        Logger.warning("Failed to parse resume JSON: #{inspect(reason)}")
        {:error, {:json_parse_error, reason}}
    end
  end

  defp extract_cid_from_url(url) do
    # Extract CID from various Fileverse URL formats:
    # - https://docs.fileverse.io/doc/QmHash...
    # - https://ipfs.io/ipfs/QmHash...
    # - https://gateway.pinata.cloud/ipfs/QmHash...
    cond do
      # Fileverse docs URL
      String.contains?(url, "docs.fileverse.io") ->
        extract_cid_from_path(url, "/doc/")

      # IPFS gateway URLs
      String.contains?(url, "/ipfs/") ->
        extract_cid_from_path(url, "/ipfs/")

      # Direct CID
      String.match?(url, ~r/^Qm[a-zA-Z0-9]{44}$/) ->
        {:ok, url}

      true ->
        {:error, :invalid_url}
    end
  end

  defp extract_cid_from_path(url, pattern) do
    case String.split(url, pattern) do
      [_, cid_part] ->
        # Extract just the CID, removing any trailing path or query params
        cid =
          cid_part
          |> String.split(["/", "?", "#"], parts: 2)
          |> List.first()

        {:ok, cid}

      _ ->
        {:error, :invalid_url}
    end
  end

  defp normalize_resume_data(data) do
    # Convert string keys to atoms if needed
    data
    |> ensure_atom_keys()
    |> ensure_struct_format()
  end

  defp ensure_atom_keys(data) when is_map(data) do
    data
    |> Enum.map(fn
      {k, v} when is_binary(k) -> {String.to_atom(k), ensure_atom_keys(v)}
      {k, v} -> {k, ensure_atom_keys(v)}
    end)
    |> Enum.into(%{})
  end

  defp ensure_atom_keys(data) when is_list(data) do
    Enum.map(data, &ensure_atom_keys/1)
  end

  defp ensure_atom_keys(data), do: data

  defp ensure_struct_format(data) do
    # Ensure the data matches the ResumeData struct format
    %{
      personal_info: Map.get(data, :personal_info, %{}),
      summary: Map.get(data, :summary, ""),
      availability: Map.get(data, :availability),
      focus_areas: Map.get(data, :focus_areas, []),
      experience: Map.get(data, :experience, []),
      education: Map.get(data, :education, []),
      defense_projects: Map.get(data, :defense_projects, []),
      portfolio: Map.get(data, :portfolio, %{}),
      certifications: Map.get(data, :certifications, []),
      contact: Map.get(data, :contact, %{})
    }
  end
end
