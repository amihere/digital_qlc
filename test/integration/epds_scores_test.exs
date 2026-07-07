defmodule QlcDigital.Integration.EpdsScoresTest do
  use ExUnit.Case

  import QlcDigital.TestHelpers

  setup do
    reset_test_state()
    :ok
  end

  defp answer(conversation, key) do
    Map.get(conversation.answers, key) || Map.get(conversation.answers, String.to_atom(key))
  end

  defp walk_to_epds_q1(session_id) do
    simulate_whatsapp_message(session_id, "hello")
    simulate_whatsapp_message(session_id, "Ama")
    simulate_whatsapp_message(session_id, "28")
    simulate_whatsapp_message(session_id, "Accra")
    simulate_whatsapp_message(session_id, "1")
    simulate_whatsapp_message(session_id, "1")
    # parenthood_stage -> nursing mother (option 4)
    simulate_whatsapp_message(session_id, "4")
    simulate_whatsapp_message(session_id, "1")
    # sad_disconnected_intro -> continue to EPDS
    simulate_whatsapp_message(session_id, "1")
  end

  test "completing the EPDS stores total, raw, and anxiety scores" do
    session_id = "+1555100001"
    walk_to_epds_q1(session_id)

    # q1..q9 all option 1: 0+0+3+0+3+3+3+3+3 = 18; q10 Never = 0
    for _ <- 1..9, do: simulate_whatsapp_message(session_id, "1")
    simulate_whatsapp_message(session_id, "4")

    conversation = get_conversation(session_id)

    assert conversation.current_question_id == "epds_completion_mid"
    assert answer(conversation, "epds_score") == "18/30"
    assert answer(conversation, "epds_raw_score") == "18"
    # anxiety: q3 opt1 = 3, q4 opt1 = 0, q5 opt1 = 3 -> 6
    assert answer(conversation, "epds_anxiety_score") == "6"
  end

  test "the safety branch also stores the scores before ending the flow" do
    session_id = "+1555100002"
    walk_to_epds_q1(session_id)

    for _ <- 1..9, do: simulate_whatsapp_message(session_id, "1")
    # q10 -> "Yes quite often": safety protocol branch
    simulate_whatsapp_message(session_id, "1")

    conversation = get_conversation(session_id)

    assert conversation.current_question_id == "safety_protocol"
    # raw sum: 18 + q10(3) = 21; routing score inflated to 30 by the override
    assert answer(conversation, "epds_score") == "30/30"
    assert answer(conversation, "epds_raw_score") == "21"
    assert answer(conversation, "epds_anxiety_score") == "6"
  end
end
