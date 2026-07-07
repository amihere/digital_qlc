defmodule QlcDigital.Integration.MiscFlowsTest do
  use ExUnit.Case

  import QlcDigital.TestHelpers

  setup do
    reset_test_state()
    :ok
  end

  defp walk_to_parenthood_stage(session_id) do
    simulate_whatsapp_message(session_id, "hello")
    simulate_whatsapp_message(session_id, "Ama")
    simulate_whatsapp_message(session_id, "28")
    simulate_whatsapp_message(session_id, "Accra")
    simulate_whatsapp_message(session_id, "1")
    simulate_whatsapp_message(session_id, "1")

    conversation = get_conversation(session_id)
    assert conversation.current_question_id == "parenthood_stage"
  end

  describe "deferred pathways (TTC / still pregnant)" do
    test "trying to conceive routes to the holding response and can reach checkout" do
      session_id = "+1555400001"
      walk_to_parenthood_stage(session_id)

      simulate_whatsapp_message(session_id, "1")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "pathway_coming_soon"
      assert_message_sent(session_id, "coming very soon")

      simulate_whatsapp_message(session_id, "1")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "checkout_point"
    end

    test "still pregnant routes to the holding response and can end gracefully" do
      session_id = "+1555400002"
      walk_to_parenthood_stage(session_id)

      simulate_whatsapp_message(session_id, "2")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "pathway_coming_soon"

      simulate_whatsapp_message(session_id, "2")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "end_gracefully"
    end
  end
end
