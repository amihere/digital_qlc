defmodule QlcDigital.Integration.ConversationFlowTest do
  use ExUnit.Case

  alias QlcDigital.Test.{MockWhatsappClient, MockRedis}
  alias QlcDigital.Question.{ConversationManager, Conversation}

  # Define test helpers inline for now
  defp reset_test_state do
    MockWhatsappClient.clear_sent_messages()
    MockRedis.clear_all_data(:redix)
  end

  defp simulate_whatsapp_message(from, text, message_id \\ nil) do
    message_id = message_id || "test_msg_#{System.unique_integer([:positive])}"

    message = %{
      "from" => from,
      "text" => %{"body" => text},
      "id" => message_id
    }

    QlcDigital.MessageHandler.handle_message(message)
    message
  end

  defp get_messages_for(phone_number) do
    MockWhatsappClient.get_sent_messages()
    |> Enum.filter(fn msg -> msg.to == phone_number end)
  end

  defp assert_message_sent(phone_number, expected_text) do
    messages = get_messages_for(phone_number)

    assert Enum.any?(messages, fn msg ->
             String.contains?(msg.message, expected_text)
           end),
           "Expected message containing '#{expected_text}' to be sent to #{phone_number}, but found: #{inspect(Enum.map(messages, & &1.message))}"
  end

  defp assert_message_count(phone_number, expected_count) do
    actual_count = get_messages_for(phone_number) |> length()

    assert actual_count == expected_count,
           "Expected #{expected_count} messages to #{phone_number}, but got #{actual_count}"
  end

  defp get_conversation(session_id) do
    case ConversationManager.load_conversation(session_id) do
      {:ok, conversation} -> conversation
      {:error, :not_found} -> nil
    end
  end

  setup do
    reset_test_state()
    :ok
  end

  describe "complete conversation flow" do
    test "user can restart conversation" do
      session_id = "+1234567891"

      # Start and partially complete conversation
      simulate_whatsapp_message(session_id, "hello")
      simulate_whatsapp_message(session_id, "Bob")
      simulate_whatsapp_message(session_id, "90")
      simulate_whatsapp_message(session_id, "Kanda")
      simulate_whatsapp_message(session_id, "1")
      simulate_whatsapp_message(session_id, "1")
      simulate_whatsapp_message(session_id, "1")
      simulate_whatsapp_message(session_id, "3")
      simulate_whatsapp_message(session_id, "2")
      simulate_whatsapp_message(session_id, "What should I do?")
      simulate_whatsapp_message(session_id, "1")
      simulate_whatsapp_message(session_id, "+1234567891")
      simulate_whatsapp_message(session_id, "Thanks")
      simulate_whatsapp_message(session_id, "It is good")
      simulate_whatsapp_message(session_id, "Hi eli")
      simulate_whatsapp_message(session_id, "eli restart")

      # Verify we're on age question
      # assert_message_sent(session_id, "Nice to meet you, Bob! How old are you?")
      #
      # # Restart conversation
      # simulate_whatsapp_message(session_id, "eli restart")
      #
      # # Should go back to start
      # assert_message_sent(session_id, "Hello! What's your name?")

      conversation = get_conversation(session_id)
      IO.inspect(conversation, label: "Final conversation")
      assert conversation != nil, "Conversation should exist"

      assert conversation.current_question_id == "start"
    end

    # test "user can stop conversation" do
    #   session_id = "+1234567892"
    #
    #   # Start conversation
    #   simulate_whatsapp_message(session_id, "Hi")
    #   simulate_whatsapp_message(session_id, "Charlie")
    #
    #   # Stop conversation (goes to choice_test per the routing logic)
    #   simulate_whatsapp_message(session_id, "eli stop")
    #
    #   assert_message_sent(session_id, "Great! Which option do you prefer?")
    #
    #   conversation = get_conversation(session_id)
    #   assert conversation.current_question_id == "choice_test"
    # end
  end
end
