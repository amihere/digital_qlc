defmodule QlcDigital.Integration.ConversationFlowTest do
  use ExUnit.Case

  import QlcDigital.TestHelpers

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
