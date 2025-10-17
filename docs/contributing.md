# Contributing

Thanks for your interest in contributing. Please follow these guidelines.

## Development Setup

- Install dependencies: `mix deps.get`
- Run the app: `./bin/dev` or `mix phx.server`
- Run tests: `mix test`
- Full checks: `mix precommit`

## Code Quality & Linting

We use comprehensive linting tools to maintain code quality:

- **Quick checks**: `mix check.quick` - Compile, format, and credo checks
- **Full checks**: `mix check` - All tools including security scanning
- **Pre-commit**: `mix precommit` - Complete validation before commits

### Linting Tools

- **Credo**: Code analysis and style enforcement
- **Sobelow**: Security vulnerability scanning
- **Formatter**: Code formatting validation
- **Compiler**: Warning-as-errors compilation
- **ExUnit**: Test suite with warnings-as-errors

## Code Style

- Elixir conventions; functional, explicit, clear naming
- Write typespecs and module docs
- Keep functions small and focused
- Follow Phoenix v1.8 guidelines
- Use Tailwind CSS for styling

## Pull Requests

- One logical change per PR
- Include tests for new behavior
- Use clear commit messages (conventional format preferred)
