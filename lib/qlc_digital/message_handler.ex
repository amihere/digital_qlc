defmodule QlcDigital.MessageHandler do
  require Logger

  alias QlcDigital.Question.Session

  defp whatsapp_client_module do
    Application.get_env(:qlc_digital, :whatsapp_client_module, QlcDigital.WhatsappClient)
  end

  def handle_message(%{"from" => from, "text" => %{"body" => body}, "id" => message_id}) do
    Logger.info("Received message [#{message_id}] from #{from}: #{body}")

    start_or_resume(from, body)
  end

  def handle_message(message) do
    Logger.info("Received non-text message: #{inspect(message)}")
  end

  def start_or_resume(from, body) do
    # use phone as session id
    case Session.start_session(from, body) do
      {:ok, :new, [initial: welcome, q: conversation]} ->
        Logger.debug("#{from} starting new conversation")
        send_message(:parse_question, from, welcome)
        send_message(:parse_question, from, conversation)

      {:ok, :resumed, conversation} ->
        Logger.debug("#{from} resumes their conversation")
        answer = body

        # This handles the response from answering
        case answer_question(conversation, answer) do
          {:ok, update} ->
            send_message(:parse_question, from, update)

          {:error, response} ->
            # validation error message
            send_message(:meta, from, response)
            send_message(:parse_question, from, conversation)
        end

      {:error, reason} ->
        Logger.error("#{from} could not continue for this reason: #{reason}")
        send_message(:meta, from, "A small hiccup.. let us try again.")
    end
  end

  defp answer_question(conversation, answer) do
    case Session.answer_question(conversation, answer) do
      {:ok, conversation_update} ->
        {:ok, conversation_update}

      {:error, :invalid_question} ->
        {:error, "Kindly restart by saying `eli stop`."}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # unwrangle message
  defp send_message(:parse_question, to, conversation) do
    response =
      case Session.get_current_question(conversation) do
        nil ->
          nil

        %{type: :summary} = summary ->
          summary.text |> String.replace("\\n", "\n")

        question ->
          Session.display_question(question, conversation.answers)
      end

    send_message(:meta, to, response)
  end

  defp send_message(:meta, _to, message) when is_nil(message) do
    Logger.info("Message was nil")
  end

  defp send_message(:meta, to, message) do
    Logger.info(message)

    client_module = whatsapp_client_module()
    client_module.send_message(to, message)
  end
end
