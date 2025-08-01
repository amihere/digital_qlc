import Config

# Test environment configuration
config :qlc_digital,
  port: 4001,
  host: "127.0.0.1",
  test_port: 4001,
  whatsapp_client_module: QlcDigital.Test.MockWhatsappClient

config :qlc_digital, :airtable,
  url: "http://localhost:4001/mock/airtable",
  token: "test_airtable_token"

config :qlc_digital, :redis,
  # Redis not used in test - using in-memory mock
  url: nil,
  namespace: "qlc_digital_test"

config :qlc_digital, :whatsapp,
  token: "test_whatsapp_token",
  phone_id: "test_phone_id",
  verify: "test_verify_token",
  webhook_url: "http://localhost:4001/webhook"

# Configure logger for test environment
config :logger, level: :warning

# Disable SSL certificate verification for test HTTP requests
config :httpoison, timeout: 5000, recv_timeout: 5000