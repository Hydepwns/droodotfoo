# Coveralls configuration for droo.foo
[
  # Coverage threshold - fail build if below this percentage
  coverage_options: [
    minimum_coverage: 85,
    treat_no_relevant_lines_as_covered: true
  ],

  # Skip files/patterns from coverage reporting
  skip_files: [
    # Test support files
    ~r/test\/support/,

    # Phoenix/LiveView generated files
    ~r/lib\/droodotfoo_web\/endpoint.ex/,
    ~r/lib\/droodotfoo_web\/telemetry.ex/,
    ~r/lib\/droodotfoo_web\/gettext.ex/,
    ~r/lib\/droodotfoo_web\/components\/core_components.ex/,
    ~r/lib\/droodotfoo_web\/components\/layouts.ex/,

    # Application startup (hard to test in isolation)
    ~r/lib\/droodotfoo\/application.ex/,

    # Mix tasks
    ~r/lib\/mix/,

    # Stub implementations awaiting Fileverse SDK
    ~r/lib\/droodotfoo\/fileverse\/ddocs_stub.ex/,
    ~r/lib\/droodotfoo\/fileverse\/storage_stub.ex/,

    # Performance monitoring (covered by integration tests)
    ~r/lib\/droodotfoo\/performance_monitor.ex/
  ],

  # Terminal output formatting
  terminal_options: [
    file_column_width: 40
  ]
]
