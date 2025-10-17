# Deployment Guide

This guide summarizes how to build and deploy the `droo.foo` application.

## Prerequisites

- Elixir/Erlang compatible with Elixir ~> 1.17
- Node.js for assets build
- Production secrets configured via environment variables

## Commands

```bash
mix deps.get
MIX_ENV=prod mix assets.deploy
MIX_ENV=prod mix release
```

## Runtime

- Server: Bandit
- Environment variables for credentials and API keys
- Phoenix endpoint configured in `config/prod.exs`

## Monitoring

- Telemetry metrics and poller
- Optional Prometheus exporters if enabled
