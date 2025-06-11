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
  url: System.get_env("UPSTASH_REDIS_REST_URL"),
  token: System.get_env("UPSTASH_REDIS_REST_TOKEN"),
  namespace: System.get_env("QLC_NAMESPACE", "qlc_digital")
