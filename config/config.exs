import Config

# You can set these environment variables or create a .env file
# WHATSAPP_TOKEN=your_whatsapp_business_api_token
# WHATSAPP_PHONE_ID=your_phone_number_id
# VERIFY_TOKEN=your_webhook_verify_token
# WEBHOOK_URL=https://your-domain.com/webhook

{port, ""} = System.get_env("PORT", "10000") |> Integer.parse()

config :qlc_digital,
  port: port,
  host: System.get_env("HOST", "0.0.0.0")

config :qlc_digital, :airtable,
  url: System.get_env("AIRTABLE_CLIENT_URL"),
  token: System.get_env("AIRTABLE_CLIENT_TOKEN")

config :qlc_digital, :redis,
  url: System.get_env("REDIS_URL"),
  ca_cert_file: System.get_env("REDIS_CA_CERT_FILE"),
  namespace: System.get_env("QLC_NAMESPACE", "qlc_digital")

config :qlc_digital, :whatsapp,
  token: System.get_env("WHATSAPP_TOKEN"),
  phone_id: System.get_env("WHATSAPP_PHONE_ID"),
  verify: System.get_env("VERIFY_TOKEN"),
  webhook_url: System.get_env("WEBHOOK_URL")

config :qlc_digital, :encryption, key: System.get_env("ENCRYPTION_KEY")

# Import environment specific config if it exists
if File.exists?("#{__DIR__}/#{config_env()}.exs") do
  import_config "#{config_env()}.exs"
end
