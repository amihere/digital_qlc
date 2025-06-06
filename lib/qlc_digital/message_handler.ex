defmodule QlcDigital.MessageHandler do
  require Logger

  def handle_message(%{"from" => from, "text" => %{"body" => body}, "id" => message_id}) do
    Logger.info("Received message from #{from}: #{body}")

    case String.downcase(String.trim(body)) do
      "hi" ->
        response = "Hello! What is your name?"
        send_message(from, response)
        Logger.info("Responded to 'hi' from #{from}")

      name when name != "" ->
        # Check if this might be a name response (simple heuristic)
        if String.contains?(name, ["my name is", "i am", "i'm"]) or
             (String.length(name) > 1 and String.length(name) < 50 and
                not String.contains?(name, " ")) do
          Logger.info("User #{from} provided name: #{name}")
          response = "Nice to meet you, #{extract_name(name)}! How can I help you today?"
          send_message(from, response)
        else
          # Generic response for other messages
          response =
            "Thanks for your message! I'm a simple bot. Say 'hi' to start a conversation."

          send_message(from, response)
        end

      _ ->
        response = "Thanks for your message! I'm a simple bot. Say 'hi' to start a conversation."
        send_message(from, response)
    end
  end

  def handle_message(message) do
    Logger.info("Received non-text message: #{inspect(message)}")
  end

  defp extract_name(text) do
    text
    |> String.downcase()
    |> String.replace(~r/my name is |i am |i'm /, "")
    |> String.trim()
    |> String.split()
    |> List.first()
    |> case do
      nil -> "friend"
      name -> String.capitalize(name)
    end
  end

  defp send_message(to, message) do
    config = QlcDigital.Config.get_config()

    url = "https://graph.facebook.com/v18.0/#{config.whatsapp_phone_id}/messages"

    headers = [
      {"Authorization", "Bearer #{config.whatsapp_token}"},
      {"Content-Type", "application/json"}
    ]

    body =
      Jason.encode!(%{
        messaging_product: "whatsapp",
        to: to,
        type: "text",
        text: %{body: message}
      })

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
