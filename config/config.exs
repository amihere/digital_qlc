import Config

config :qlc_digital, QlcDigital.Repo,
  database: System.get_env("DATABASE_PATH") || "./qlc_digital.db",
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5"),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true

# Configure Ecto repositories
config :qlc_digital, ecto_repos: [QlcDigital.Repo]

config :qlc_digital,
  port: 10000,
  host: "0.0.0.0"

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
