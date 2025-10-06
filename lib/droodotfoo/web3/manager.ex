defmodule Droodotfoo.Web3.Manager do
  @moduledoc """
  GenServer managing Web3 wallet sessions and state.

  Responsibilities:
  - Track active wallet sessions
  - Cache ENS resolutions
  - Manage nonce lifecycle
  - Clean up expired sessions
  """

  use GenServer
  require Logger

  @type address :: String.t()

  @type session :: %{
          address: address(),
          connected_at: DateTime.t(),
          last_activity: DateTime.t(),
          chain_id: integer()
        }

  @type nonce_entry :: %{
          nonce: String.t(),
          address: address(),
          created_at: DateTime.t(),
          used: boolean()
        }

  @type ens_cache_entry :: %{
          name: String.t(),
          cached_at: DateTime.t()
        }

  @type state :: %{
          sessions: %{address() => session()},
          nonces: %{String.t() => nonce_entry()},
          ens_cache: %{address() => ens_cache_entry()},
          chain_id: integer()
        }

  # Session expires after 24 hours of inactivity
  @session_ttl_hours 24

  # Nonce expires after 5 minutes
  @nonce_ttl_minutes 5

  # ENS cache expires after 1 hour
  @ens_ttl_hours 1

  # Cleanup interval: 1 hour
  @cleanup_interval_ms 60 * 60 * 1000

  ## Client API

  @doc """
  Start the Web3 Manager GenServer.
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Generate and store a new nonce for wallet authentication.

  ## Examples

      iex> {:ok, nonce} = Droodotfoo.Web3.Manager.generate_nonce("0x1234...")
      iex> String.length(nonce)
      32

  """
  @spec generate_nonce(address()) :: {:ok, String.t()}
  def generate_nonce(address) do
    GenServer.call(__MODULE__, {:generate_nonce, address})
  end

  @doc """
  Verify and consume a nonce.

  Returns `{:ok, nonce_entry}` if nonce is valid and not used.
  Returns `{:error, reason}` if nonce is invalid, expired, or already used.
  """
  @spec verify_nonce(String.t(), address()) :: {:ok, nonce_entry()} | {:error, atom()}
  def verify_nonce(nonce, address) do
    GenServer.call(__MODULE__, {:verify_nonce, nonce, address})
  end

  @doc """
  Start a new wallet session.

  ## Parameters

  - `address`: Ethereum wallet address (0x-prefixed)
  - `chain_id`: Blockchain network ID (1 for mainnet, 5 for Goerli, etc.)

  ## Examples

      iex> Droodotfoo.Web3.Manager.start_session("0x1234...", 1)
      {:ok, %{address: "0x1234...", connected_at: ~U[2025-10-06 ...]}}

  """
  @spec start_session(address(), integer()) :: {:ok, session()}
  def start_session(address, chain_id) do
    GenServer.call(__MODULE__, {:start_session, address, chain_id})
  end

  @doc """
  Update session activity timestamp.
  """
  @spec touch_session(address()) :: :ok | {:error, :not_found}
  def touch_session(address) do
    GenServer.call(__MODULE__, {:touch_session, address})
  end

  @doc """
  Get an active session by wallet address.

  Returns `{:ok, session}` if found and not expired.
  Returns `{:error, :not_found}` if not found.
  Returns `{:error, :expired}` if session has expired.
  """
  @spec get_session(address()) :: {:ok, session()} | {:error, atom()}
  def get_session(address) do
    GenServer.call(__MODULE__, {:get_session, address})
  end

  @doc """
  End a wallet session.
  """
  @spec end_session(address()) :: :ok
  def end_session(address) do
    GenServer.call(__MODULE__, {:end_session, address})
  end

  @doc """
  Get all active sessions.
  """
  @spec list_sessions() :: [session()]
  def list_sessions do
    GenServer.call(__MODULE__, :list_sessions)
  end

  @doc """
  Reverse resolve an address to its ENS name (if any).
  Returns cached result if available and not expired.
  """
  @spec resolve_ens(address()) :: {:ok, String.t()} | {:error, atom()}
  def resolve_ens(address) do
    GenServer.call(__MODULE__, {:resolve_ens, address})
  end

  @doc """
  Resolve an ENS name to an address.
  """
  @spec lookup_ens(String.t()) :: {:ok, address()} | {:error, atom()}
  def lookup_ens(ens_name) do
    GenServer.call(__MODULE__, {:lookup_ens, ens_name})
  end

  ## Server Callbacks

  @impl true
  def init(opts) do
    # Schedule periodic cleanup
    schedule_cleanup()

    state = %{
      sessions: %{},
      nonces: %{},
      ens_cache: %{},
      chain_id: Keyword.get(opts, :default_chain_id, 1)
    }

    Logger.info("Web3.Manager started with default chain_id: #{state.chain_id}")
    {:ok, state}
  end

  @impl true
  def handle_call({:generate_nonce, address}, _from, state) do
    nonce = Droodotfoo.Web3.Auth.generate_nonce()

    nonce_entry = %{
      nonce: nonce,
      address: address,
      created_at: DateTime.utc_now(),
      used: false
    }

    state = put_in(state.nonces[nonce], nonce_entry)
    Logger.debug("Generated nonce for #{address}: #{nonce}")

    {:reply, {:ok, nonce}, state}
  end

  @impl true
  def handle_call({:verify_nonce, nonce, address}, _from, state) do
    case Map.get(state.nonces, nonce) do
      nil ->
        {:reply, {:error, :invalid_nonce}, state}

      nonce_entry ->
        cond do
          nonce_entry.used ->
            {:reply, {:error, :nonce_already_used}, state}

          nonce_entry.address != address ->
            {:reply, {:error, :address_mismatch}, state}

          nonce_expired?(nonce_entry) ->
            # Clean up expired nonce
            state = update_in(state.nonces, &Map.delete(&1, nonce))
            {:reply, {:error, :nonce_expired}, state}

          true ->
            # Mark nonce as used
            state = put_in(state.nonces[nonce].used, true)
            {:reply, {:ok, nonce_entry}, state}
        end
    end
  end

  @impl true
  def handle_call({:start_session, address, chain_id}, _from, state) do
    session = %{
      address: address,
      connected_at: DateTime.utc_now(),
      last_activity: DateTime.utc_now(),
      chain_id: chain_id
    }

    state = put_in(state.sessions[address], session)
    Logger.info("Web3 session started for #{address} on chain #{chain_id}")

    {:reply, {:ok, session}, state}
  end

  @impl true
  def handle_call({:touch_session, address}, _from, state) do
    case Map.get(state.sessions, address) do
      nil ->
        {:reply, {:error, :not_found}, state}

      _session ->
        state = put_in(state.sessions[address].last_activity, DateTime.utc_now())
        {:reply, :ok, state}
    end
  end

  @impl true
  def handle_call({:get_session, address}, _from, state) do
    case Map.get(state.sessions, address) do
      nil ->
        {:reply, {:error, :not_found}, state}

      session ->
        if session_expired?(session) do
          # Clean up expired session
          state = update_in(state.sessions, &Map.delete(&1, address))
          {:reply, {:error, :expired}, state}
        else
          {:reply, {:ok, session}, state}
        end
    end
  end

  @impl true
  def handle_call({:end_session, address}, _from, state) do
    state = update_in(state.sessions, &Map.delete(&1, address))
    Logger.info("Web3 session ended for #{address}")
    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:list_sessions, _from, state) do
    # Filter out expired sessions
    active_sessions =
      state.sessions
      |> Enum.reject(fn {_addr, session} -> session_expired?(session) end)
      |> Enum.map(fn {_addr, session} -> session end)

    {:reply, active_sessions, state}
  end

  @impl true
  def handle_call({:resolve_ens, address}, _from, state) do
    # Check cache first
    case Map.get(state.ens_cache, address) do
      %{name: name} = entry ->
        if ens_cache_expired?(entry) do
          # Expired, resolve again
          resolve_and_cache_ens(address, state)
        else
          Logger.debug("ENS cache hit for #{address}: #{name}")
          {:reply, {:ok, name}, state}
        end

      nil ->
        # Not in cache, resolve and cache
        resolve_and_cache_ens(address, state)
    end
  end

  @impl true
  def handle_call({:lookup_ens, ens_name}, _from, state) do
    # ENS name -> address lookup
    case Droodotfoo.Web3.ENS.resolve_name(ens_name, state.chain_id) do
      {:ok, address} ->
        Logger.info("Resolved ENS #{ens_name} -> #{address}")
        {:reply, {:ok, address}, state}

      {:error, reason} = error ->
        Logger.debug("Failed to resolve ENS #{ens_name}: #{reason}")
        {:reply, error, state}
    end
  end

  @impl true
  def handle_info(:cleanup, state) do
    # Clean up expired sessions
    expired_sessions =
      state.sessions
      |> Enum.filter(fn {_addr, session} -> session_expired?(session) end)
      |> Enum.map(fn {addr, _session} -> addr end)

    state = update_in(state.sessions, fn sessions ->
      Enum.reduce(expired_sessions, sessions, fn addr, acc ->
        Map.delete(acc, addr)
      end)
    end)

    if length(expired_sessions) > 0 do
      Logger.info("Cleaned up #{length(expired_sessions)} expired sessions")
    end

    # Clean up expired nonces
    expired_nonces =
      state.nonces
      |> Enum.filter(fn {_nonce, entry} -> nonce_expired?(entry) end)
      |> Enum.map(fn {nonce, _entry} -> nonce end)

    state = update_in(state.nonces, fn nonces ->
      Enum.reduce(expired_nonces, nonces, fn nonce, acc ->
        Map.delete(acc, nonce)
      end)
    end)

    if length(expired_nonces) > 0 do
      Logger.debug("Cleaned up #{length(expired_nonces)} expired nonces")
    end

    # Clean up expired ENS cache entries
    expired_ens =
      state.ens_cache
      |> Enum.filter(fn {_addr, entry} -> ens_cache_expired?(entry) end)
      |> Enum.map(fn {addr, _entry} -> addr end)

    state = update_in(state.ens_cache, fn cache ->
      Enum.reduce(expired_ens, cache, fn addr, acc ->
        Map.delete(acc, addr)
      end)
    end)

    if length(expired_ens) > 0 do
      Logger.debug("Cleaned up #{length(expired_ens)} expired ENS cache entries")
    end

    # Schedule next cleanup
    schedule_cleanup()

    {:noreply, state}
  end

  ## Private Functions

  defp session_expired?(session) do
    expiry_time = DateTime.add(session.last_activity, @session_ttl_hours, :hour)
    DateTime.compare(DateTime.utc_now(), expiry_time) == :gt
  end

  defp nonce_expired?(nonce_entry) do
    expiry_time = DateTime.add(nonce_entry.created_at, @nonce_ttl_minutes, :minute)
    DateTime.compare(DateTime.utc_now(), expiry_time) == :gt
  end

  defp ens_cache_expired?(cache_entry) do
    expiry_time = DateTime.add(cache_entry.cached_at, @ens_ttl_hours, :hour)
    DateTime.compare(DateTime.utc_now(), expiry_time) == :gt
  end

  defp resolve_and_cache_ens(address, state) do
    case Droodotfoo.Web3.ENS.reverse_resolve(address, state.chain_id) do
      {:ok, name} ->
        # Cache the result
        cache_entry = %{
          name: name,
          cached_at: DateTime.utc_now()
        }

        state = put_in(state.ens_cache[address], cache_entry)
        Logger.info("Resolved and cached ENS for #{address}: #{name}")
        {:reply, {:ok, name}, state}

      {:error, _reason} ->
        # Return the address itself if ENS resolution fails
        {:reply, {:ok, address}, state}
    end
  end

  defp schedule_cleanup do
    Process.send_after(self(), :cleanup, @cleanup_interval_ms)
  end
end
