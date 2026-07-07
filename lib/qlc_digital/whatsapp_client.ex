defmodule QlcDigital.WhatsappClient do
  @moduledoc """
  WhatsApp client agent for sending messages via WhatsApp Business API.
  Centralizes all WhatsApp API interactions and configuration.
  """

  use Agent
  require Logger

  @agent_name __MODULE__

  def start_link(opts) do
    config = Keyword.get(opts, :config, %{})

    initial_state = %{
      token: config[:token],
      phone_id: config[:phone_id],
      verify_token: config[:verify_token],
      webhook_url: config[:webhook_url]
    }

    Agent.start_link(fn -> initial_state end, name: @agent_name)
  end

  def get_config do
    Agent.get(@agent_name, & &1)
  end

  def get_verify_token do
    Agent.get(@agent_name, fn state -> state.verify_token end)
  end

  def send_message(to, message) do
    config = get_config()

    body =
      Jason.encode!(%{
        messaging_product: "whatsapp",
        to: to,
        type: "text",
        text: %{body: message}
      })

    url = "https://graph.facebook.com/v23.0/#{config.phone_id}/messages"

    headers = [
      {"Authorization", "Bearer #{config.token}"},
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        Logger.info("Message sent successfully to #{to}")
        :ok

      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} ->
        Logger.error("Failed to send message. Status: #{status_code}, Body: #{response_body}")
        :error

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP request failed: #{reason}")
        :error
    end
  end

  def update_config(new_config) do
    Agent.update(@agent_name, fn state ->
      Map.merge(state, new_config)
    end)
  end
end
