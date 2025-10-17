[
  tools: [
    {:compiler, "mix compile --warnings-as-errors"},
    {:formatter, "mix format --check-formatted"},
    {:credo, "mix credo --strict"},
    {:sobelow, "mix sobelow --config"},
    {:ex_unit, "mix test --warnings-as-errors"}
  ],
  parallel: true,
  skipped: false
]
