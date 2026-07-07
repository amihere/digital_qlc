ExUnit.start(capture_log: true)

# Shared helpers (test/ is not in elixirc_paths, so load explicitly)
Code.require_file("test_helpers.ex", __DIR__)

# Start the application in test mode
{:ok, _} = Application.ensure_all_started(:qlc_digital)

# Wait for application to be ready
Process.sleep(100)

# Configure ExUnit to reset state before each test
ExUnit.configure(
  exclude: [:skip],
  formatters: [ExUnit.CLIFormatter]
)
