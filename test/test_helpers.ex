defmodule QlcDigital.TestHelpers do
  @moduledoc """
  Test helper functions for QlcDigital testing.
  """

  import ExUnit.Assertions

  alias QlcDigital.Test.{MockWhatsappClient, MockRedis}
  alias QlcDigital.Question.{Conversation, ConversationManager}

  @doc """
  Clears all test state - sent messages, conversations, and resets questions.
  """
  def reset_test_state do
    MockWhatsappClient.clear_sent_messages()
    MockRedis.clear_all_data(:redix)
  end

  @doc """
  Creates a test conversation for a given session ID.
  """
  def create_test_conversation(session_id, current_question_id \\ "start", answers \\ %{}) do
    conversation = %Conversation{
      session_id: session_id,
      current_question_id: current_question_id,
      answers: answers,
      started_at: DateTime.utc_now()
    }

    ConversationManager.save_conversation(conversation)
    conversation
  end

  @doc """
  Simulates receiving a WhatsApp message.
  """
  def simulate_whatsapp_message(from, text, message_id \\ nil) do
    message_id = message_id || "test_msg_#{System.unique_integer([:positive])}"

    message = %{
      "from" => from,
      "text" => %{"body" => text},
      "id" => message_id
    }

    QlcDigital.MessageHandler.handle_message(message)
    message
  end

  @doc """
  Simulates a complete conversation flow.
  """
  def simulate_conversation_flow(session_id, responses) do
    results = []

    Enum.reduce(responses, results, fn response, acc ->
      result = simulate_whatsapp_message(session_id, response)
      [result | acc]
    end)
    |> Enum.reverse()
  end

  @doc """
  Gets all messages sent to a specific phone number.
  """
  def get_messages_for(phone_number) do
    MockWhatsappClient.get_sent_messages()
    |> Enum.filter(fn msg -> msg.to == phone_number end)
  end

  @doc """
  Gets the last message sent to a specific phone number.
  """
  def get_last_message_for(phone_number) do
    get_messages_for(phone_number)
    |> List.last()
  end

  @doc """
  Asserts that a message was sent to a phone number containing specific text.
  """
  def assert_message_sent(phone_number, expected_text) do
    messages = get_messages_for(phone_number)

    assert Enum.any?(messages, fn msg ->
             String.contains?(msg.message, expected_text)
           end),
           "Expected message containing '#{expected_text}' to be sent to #{phone_number}, but found: #{inspect(Enum.map(messages, & &1.message))}"
  end

  @doc """
  Asserts that exactly N messages were sent to a phone number.
  """
  def assert_message_count(phone_number, expected_count) do
    actual_count = get_messages_for(phone_number) |> length()

    assert actual_count == expected_count,
           "Expected #{expected_count} messages to #{phone_number}, but got #{actual_count}"
  end

  @doc """
  Sets custom test questions.
  """
  def set_test_questions(_questions) do
    # For now, we use the real question config file
    # Could be enhanced to support dynamic question loading
    :ok
  end

  @doc """
  Gets current conversation for a session.
  """
  def get_conversation(session_id) do
    case ConversationManager.load_conversation(session_id) do
      {:ok, conversation} -> conversation
      {:error, :not_found} -> nil
    end
  end

  @doc """
  Clears all conversations from Redis.
  """
  def clear_all_conversations do
    case ConversationManager.list_sessions() do
      {:ok, sessions} ->
        Enum.each(sessions, &ConversationManager.delete_conversation/1)

      _ ->
        :ok
    end
  end

  @doc """
  Waits for the application to be ready for testing.
  """
  def wait_for_application do
    # Simple wait to ensure all processes are started
    Process.sleep(100)
  end
end
