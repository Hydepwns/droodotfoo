[
  ## All available options with default values (see `mix check` docs for description)
  # parallel: true,
  # skipped: true,
  # exit_status: true,

  ## List of tools to run in the specified order.
  ## All available tools: https://github.com/karolsluszniak/ex_check#tools
  tools: [
    ## Compilation
    {:compiler, "mix compile --warnings-as-errors", order: 1},
    {:deps_unlock, "mix deps.unlock --check-unused", order: 1},

    ## Code Analysis
    {:formatter, "mix format --check-formatted", order: 2},
    {:credo, "mix credo --strict", order: 3},

    ## Documentation
    # {:docs, "mix docs", order: 4},

    ## Tests
    {:test, "mix test", order: 5},
    {:test_coverage, "mix test --cover", order: 6, retry: "mix test --failed"}

    ## Custom Checks
    # {:dialyzer, "mix dialyzer", order: 7},
    # {:sobelow, "mix sobelow --config", order: 8}
  ],

  ## Configure retries
  retry: [
    enabled: true,
    retry_on: [:test_coverage]
  ]
]
