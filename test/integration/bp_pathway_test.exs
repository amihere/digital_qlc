defmodule QlcDigital.Integration.BpPathwayTest do
  use ExUnit.Case

  import QlcDigital.TestHelpers

  setup do
    reset_test_state()
    :ok
  end

  defp answer(conversation, key) do
    Map.get(conversation.answers, key) || Map.get(conversation.answers, String.to_atom(key))
  end

  # Intake up to nursing_mother_concerns, then option 4 (BP / physical concern)
  defp walk_to_bp_intro(session_id) do
    simulate_whatsapp_message(session_id, "hello")
    simulate_whatsapp_message(session_id, "Ama")
    simulate_whatsapp_message(session_id, "28")
    simulate_whatsapp_message(session_id, "Accra")
    simulate_whatsapp_message(session_id, "1")
    simulate_whatsapp_message(session_id, "1")
    # parenthood_stage -> nursing mother (option 4)
    simulate_whatsapp_message(session_id, "4")
    # nursing_mother_concerns -> BP / physical concern (option 4)
    simulate_whatsapp_message(session_id, "4")

    conversation = get_conversation(session_id)
    assert conversation.current_question_id == "bp_intro"
  end

  describe "BP-A: device readings" do
    test "emergency reading ends the session without emotional screening" do
      session_id = "+1555200001"
      walk_to_bp_intro(session_id)

      simulate_whatsapp_message(session_id, "1")
      simulate_whatsapp_message(session_id, "165")
      simulate_whatsapp_message(session_id, "95")

      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "bp_emergency"
      assert answer(conversation, "bp_flag") == "BP_EMERGENCY"
      assert_message_sent(session_id, "immediate medical attention")

      # "Yes I'm going now" -> terminal summary, session over
      simulate_whatsapp_message(session_id, "1")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "bp_emergency_going"
      assert_message_sent(session_id, "Please go immediately")

      simulate_whatsapp_message(session_id, "ok")
      conversation = get_conversation(session_id)
      assert conversation.completed == true
    end

    test "concern reading flags and continues to emotional screening" do
      session_id = "+1555200002"
      walk_to_bp_intro(session_id)

      simulate_whatsapp_message(session_id, "1")
      simulate_whatsapp_message(session_id, "145")
      simulate_whatsapp_message(session_id, "95")

      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "bp_concern"
      assert answer(conversation, "bp_flag") == "BP_CONCERN"

      # continue -> emotional options -> stressed/anxious path
      simulate_whatsapp_message(session_id, "1")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "bp_emotional_options"

      simulate_whatsapp_message(session_id, "3")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "stress_anxiety_intro"
    end

    test "normal reading offers emotional check-in and declining goes to checkout" do
      session_id = "+1555200003"
      walk_to_bp_intro(session_id)

      simulate_whatsapp_message(session_id, "1")
      simulate_whatsapp_message(session_id, "120")
      simulate_whatsapp_message(session_id, "80")

      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "bp_normal"
      assert answer(conversation, "bp_flag") == "BP_NORMAL"

      simulate_whatsapp_message(session_id, "2")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "checkout_point"
    end

    test "skipping a reading escalates to concern, not normal" do
      session_id = "+1555200004"
      walk_to_bp_intro(session_id)

      simulate_whatsapp_message(session_id, "1")
      simulate_whatsapp_message(session_id, "skip")
      simulate_whatsapp_message(session_id, "80")

      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "bp_concern"
      assert answer(conversation, "bp_flag") == "BP_CONCERN"
    end
  end

  describe "BP-B: proxy symptom questions" do
    defp walk_to_proxy_q1(session_id) do
      walk_to_bp_intro(session_id)
      simulate_whatsapp_message(session_id, "2")

      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "bp_proxy_q1"
    end

    test "no symptoms is normal and can continue to emotional screening" do
      session_id = "+1555200005"
      walk_to_proxy_q1(session_id)

      for _ <- 1..5, do: simulate_whatsapp_message(session_id, "2")

      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "bp_proxy_normal"
      assert answer(conversation, "bp_proxy_count") == "0"
      assert answer(conversation, "bp_flag") == "BP_PROXY_NORMAL"

      simulate_whatsapp_message(session_id, "1")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "bp_emotional_options"
    end

    test "one symptom is a mild flag" do
      session_id = "+1555200006"
      walk_to_proxy_q1(session_id)

      simulate_whatsapp_message(session_id, "1")
      for _ <- 1..4, do: simulate_whatsapp_message(session_id, "2")

      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "bp_proxy_flag"
      assert answer(conversation, "bp_proxy_count") == "1"
      assert answer(conversation, "bp_flag") == "BP_PROXY_MILD"
    end

    test "two symptoms is an emergency that ends the session" do
      session_id = "+1555200007"
      walk_to_proxy_q1(session_id)

      simulate_whatsapp_message(session_id, "1")
      simulate_whatsapp_message(session_id, "1")
      for _ <- 1..3, do: simulate_whatsapp_message(session_id, "2")

      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "bp_proxy_emergency"
      assert answer(conversation, "bp_proxy_count") == "2"
      assert answer(conversation, "bp_flag") == "BP_PROXY_EMERGENCY"
      assert_message_sent(session_id, "urgent medical attention")
    end
  end
end
