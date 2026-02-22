# Wiki app Dockerfile for mini-axol deployment
#
# Build:  docker build -t wiki:latest .
# Run:    docker run -p 4040:4040 --env-file .env wiki:latest

ARG ELIXIR_VERSION=1.17.3
ARG OTP_VERSION=26.2.4
ARG DEBIAN_VERSION=bookworm-20251020-slim

ARG BUILDER_IMAGE="docker.io/hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="docker.io/debian:${DEBIAN_VERSION}"

# =============================================================================
# Build stage
# =============================================================================

FROM ${BUILDER_IMAGE} AS builder

RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential git curl \
  && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
  && apt-get install -y nodejs \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

ENV MIX_ENV="prod"

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV

# Copy compile-time config
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mkdir -p config
RUN mix deps.compile

# Install npm dependencies
COPY assets/package.json assets/package-lock.json ./assets/
RUN npm ci --prefix assets

# Copy rest of assets
COPY assets ./assets

# Copy priv and lib
COPY priv priv
COPY lib lib

# Compile
RUN mix compile

# Build assets
RUN mix assets.deploy

# Copy runtime config
COPY config/runtime.exs config/

# Build release
COPY rel rel
RUN mix release

# =============================================================================
# Runtime stage
# =============================================================================

FROM ${RUNNER_IMAGE} AS final

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    libstdc++6 openssl libncurses5 locales ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Set locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV MIX_ENV="prod"

WORKDIR /app

# Create non-root user
RUN useradd --create-home --shell /bin/bash wiki
RUN chown -R wiki:wiki /app
USER wiki

# Copy release from builder
COPY --from=builder --chown=wiki:wiki /app/_build/prod/rel/wiki ./

# Default port
EXPOSE 4040

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD curl -f http://localhost:4040/api/health || exit 1

# Start the app
CMD ["bin/wiki", "start"]
