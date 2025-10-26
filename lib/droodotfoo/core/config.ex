defmodule Droodotfoo.Core.Config do
  @moduledoc """
  Centralized configuration management for the application.
  Provides a single source of truth for all configuration values.
  """

  @doc """
  Gets the application name.
  """
  def app_name, do: Application.get_env(:droodotfoo, :app_name, "droo.foo")

  @doc """
  Gets the application version.
  """
  def app_version, do: Application.get_env(:droodotfoo, :app_version, "1.0.0")

  @doc """
  Gets the environment (dev, test, prod).
  Falls back to :prod if not configured (safe default for releases).
  """
  def environment, do: Application.get_env(:droodotfoo, :environment, :prod)

  @doc """
  Checks if running in development mode.
  """
  def dev?, do: environment() == :dev

  @doc """
  Checks if running in test mode.
  """
  def test?, do: environment() == :test

  @doc """
  Checks if running in production mode.
  """
  def prod?, do: environment() == :prod

  # HTTP Client Configuration

  @doc """
  Gets the default HTTP timeout in milliseconds.
  """
  def http_timeout, do: Application.get_env(:droodotfoo, :http_timeout, 10_000)

  @doc """
  Gets the default HTTP retry count.
  """
  def http_retries, do: Application.get_env(:droodotfoo, :http_retries, 2)

  @doc """
  Gets the default HTTP retry delay in milliseconds.
  """
  def http_retry_delay, do: Application.get_env(:droodotfoo, :http_retry_delay, 1_000)

  # API Configuration

  @doc """
  Gets the GitHub API token.
  """
  def github_token, do: System.get_env("GITHUB_TOKEN")

  @doc """
  Gets the Spotify client ID.
  """
  def spotify_client_id, do: System.get_env("SPOTIFY_CLIENT_ID")

  @doc """
  Gets the Spotify client secret.
  """
  def spotify_client_secret, do: System.get_env("SPOTIFY_CLIENT_SECRET")

  @doc """
  Gets the Spotify redirect URI.
  """
  def spotify_redirect_uri,
    do: System.get_env("SPOTIFY_REDIRECT_URI", "http://localhost:4000/auth/spotify/callback")

  @doc """
  Gets the Web3 RPC URL.
  """
  def web3_rpc_url,
    do: System.get_env("WEB3_RPC_URL", "https://eth-mainnet.alchemyapi.io/v2/demo")

  @doc """
  Gets the Web3 chain ID.
  """
  def web3_chain_id, do: System.get_env("WEB3_CHAIN_ID", "1") |> String.to_integer()

  # Cache Configuration

  @doc """
  Gets the default cache TTL in milliseconds.
  """
  def cache_ttl, do: Application.get_env(:droodotfoo, :cache_ttl, 300_000)

  @doc """
  Gets the cache size limit.
  """
  def cache_size_limit, do: Application.get_env(:droodotfoo, :cache_size_limit, 1000)

  # Rate Limiting Configuration

  @doc """
  Gets the default rate limit per minute.
  """
  def rate_limit_per_minute, do: Application.get_env(:droodotfoo, :rate_limit_per_minute, 60)

  @doc """
  Gets the default rate limit per hour.
  """
  def rate_limit_per_hour, do: Application.get_env(:droodotfoo, :rate_limit_per_hour, 1000)

  # File Upload Configuration

  @doc """
  Gets the maximum file upload size in bytes.
  """
  # 10MB
  def max_upload_size, do: Application.get_env(:droodotfoo, :max_upload_size, 10_485_760)

  @doc """
  Gets the allowed file upload types.
  """
  def allowed_upload_types,
    do:
      Application.get_env(:droodotfoo, :allowed_upload_types, [
        "image/jpeg",
        "image/png",
        "image/gif",
        "text/plain",
        "application/pdf"
      ])

  # Terminal Configuration

  @doc """
  Gets the terminal refresh rate in milliseconds.
  """
  def terminal_refresh_rate, do: Application.get_env(:droodotfoo, :terminal_refresh_rate, 100)

  @doc """
  Gets the terminal buffer size.
  """
  def terminal_buffer_size, do: Application.get_env(:droodotfoo, :terminal_buffer_size, 1000)

  @doc """
  Gets the terminal history size.
  """
  def terminal_history_size, do: Application.get_env(:droodotfoo, :terminal_history_size, 100)

  # Game Configuration

  @doc """
  Gets the default game grid size.
  """
  def game_grid_size, do: Application.get_env(:droodotfoo, :game_grid_size, {40, 20})

  @doc """
  Gets the default game speed in milliseconds.
  """
  def game_speed, do: Application.get_env(:droodotfoo, :game_speed, 500)

  @doc """
  Gets the maximum game score.
  """
  def max_game_score, do: Application.get_env(:droodotfoo, :max_game_score, 999_999)

  # Email Configuration

  @doc """
  Gets the admin email address.
  """
  def admin_email, do: Application.get_env(:droodotfoo, :admin_email, "admin@droo.foo")

  @doc """
  Gets the contact form email address.
  """
  def contact_email, do: Application.get_env(:droodotfoo, :contact_email, "contact@droo.foo")

  @doc """
  Gets the SMTP configuration.
  """
  def smtp_config do
    %{
      relay: System.get_env("SMTP_RELAY", "localhost"),
      port: System.get_env("SMTP_PORT", "587") |> String.to_integer(),
      username: System.get_env("SMTP_USERNAME"),
      password: System.get_env("SMTP_PASSWORD"),
      ssl: System.get_env("SMTP_SSL", "true") |> String.to_existing_atom(),
      tls: System.get_env("SMTP_TLS", "true") |> String.to_existing_atom()
    }
  end

  # Database Configuration

  @doc """
  Gets the database URL.
  """
  def database_url, do: System.get_env("DATABASE_URL")

  @doc """
  Gets the database pool size.
  """
  def database_pool_size, do: Application.get_env(:droodotfoo, :database_pool_size, 10)

  # Security Configuration

  @doc """
  Gets the secret key base.
  """
  def secret_key_base, do: System.get_env("SECRET_KEY_BASE")

  @doc """
  Gets the signing salt.
  """
  def signing_salt, do: System.get_env("SIGNING_SALT", "droodotfoo")

  @doc """
  Gets the encryption salt.
  """
  def encryption_salt, do: System.get_env("ENCRYPTION_SALT", "droodotfoo")

  # Feature Flags

  @doc """
  Checks if a feature is enabled.
  """
  def feature_enabled?(feature) when is_atom(feature) do
    Application.get_env(:droodotfoo, :features, %{})
    |> Map.get(feature, false)
  end

  @doc """
  Gets all enabled features.
  """
  def enabled_features do
    Application.get_env(:droodotfoo, :features, %{})
    |> Enum.filter(fn {_key, value} -> value end)
    |> Enum.map(fn {key, _value} -> key end)
  end

  # Logging Configuration

  @doc """
  Gets the log level.
  """
  def log_level, do: Application.get_env(:droodotfoo, :log_level, :info)

  @doc """
  Checks if debug logging is enabled.
  """
  def debug_logging?, do: Application.get_env(:droodotfoo, :debug_logging, false)

  # Performance Configuration

  @doc """
  Gets the performance monitoring interval in milliseconds.
  """
  def performance_monitor_interval,
    do: Application.get_env(:droodotfoo, :performance_monitor_interval, 5_000)

  @doc """
  Gets the performance threshold in milliseconds.
  """
  def performance_threshold, do: Application.get_env(:droodotfoo, :performance_threshold, 100)

  # Development Configuration

  @doc """
  Checks if hot reloading is enabled.
  """
  def hot_reload?, do: Application.get_env(:droodotfoo, :hot_reload, dev?())

  @doc """
  Checks if live reloading is enabled.
  """
  def live_reload?, do: Application.get_env(:droodotfoo, :live_reload, dev?())

  @doc """
  Gets the development server port.
  """
  def dev_port, do: Application.get_env(:droodotfoo, :dev_port, 4000)

  @doc """
  Gets the development server host.
  """
  def dev_host, do: Application.get_env(:droodotfoo, :dev_host, "localhost")
end
