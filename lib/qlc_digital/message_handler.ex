defmodule QlcDigital.MessageHandler do
  require Logger

  alias QlcDigital.Question.Session

  @whatsapp Application.compile_env(:qlc_digital, :whatsapp, [])

  def handle_message(%{"from" => from, "text" => %{"body" => body}, "id" => message_id}) do
    Logger.info("Received message [#{message_id}] from #{from}: #{body}")

    start_or_resume(from, body)
  end

  def handle_message(message) do
    Logger.info("Received non-text message: #{inspect(message)}")
  end

  def start_or_resume(from, body) do
    Logger.info("Current message #{body}")

    # use phone as session id
    case Session.start_session(from) do
      {:ok, :new, conversation} ->
        send_message(:parse_question, from, conversation)

      {:ok, :resumed, conversation} ->
        answer = body
        Session.answer_question(conversation, answer)
        send_message(:parse_question, from, conversation)

      {:error, reason} ->
        Logger.error(reason)
        default_message = "Say hi, and try again"
        send_message(from, default_message)
    end
  end

  # unwrangle message
  defp send_message(:parse_question, to, conversation) do
    response =
      case Session.get_current_question(conversation) do
        nil ->
          Session.get_summary(conversation)

        %{type: :summary} = summary ->
          summary.text

        question ->
          Session.display_question(question)
      end

    Logger.info(response)
    send_message(to, response)
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
