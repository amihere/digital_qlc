defmodule QlcDigital.Config do
  @moduledoc """
  Configuration module for WhatsApp Bot
  """

  def get_config do
    %{
      whatsapp_token: get_env("WHATSAPP_TOKEN"),
      whatsapp_phone_id: get_env("WHATSAPP_PHONE_ID"),
      verify_token: get_env("VERIFY_TOKEN"),
      webhook_url: get_env("WEBHOOK_URL")
    }
  end

  defp get_env(key, default \\ nil) do
    case System.get_env(key) do
      nil ->
        case default do
          nil -> raise "Environment variable #{key} is required"
          value -> value
        end

      value ->
        value
    end
  end
end
