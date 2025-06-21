defmodule QlcDigital.MessageHandler do
  require Logger

  @whatsapp Application.compile_env(:qlc_digital, :whatsapp, [])

  def handle_message(%{"from" => from, "text" => %{"body" => body}, "id" => message_id}) do
    Logger.info("Received message [#{message_id}] from #{from}: #{body}")

    # Here we route the user's messages
    case String.downcase(String.trim(body)) do
      "hi" ->
        manage_next_step(from, body)

      _ ->
        nil
    end
  end

  def handle_message(message) do
    Logger.info("Received non-text message: #{inspect(message)}")
  end

  def manage_next_step(from, body, step \\ 0) do
    Logger.info("Current message #{body}")

    response = "Thanks for your message! Say 'hi' to start a conversation."
    send_message(from, response)
  end

  defp send_message(to, message) do
    body =
      Jason.encode!(%{
        messaging_product: "whatsapp",
        to: to,
        type: "text",
        text: %{body: message}
      })

    url = "https://graph.facebook.com/v23.0/#{@whatsapp[:phone_id]}/messages"

    headers = [
      {"Authorization", "Bearer #{@whatsapp[:token]}"},
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
end
