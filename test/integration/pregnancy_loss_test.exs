defmodule QlcDigital.Integration.PregnancyLossTest do
  use ExUnit.Case

  import QlcDigital.TestHelpers

  setup do
    reset_test_state()
    :ok
  end

  defp answer(conversation, key) do
    Map.get(conversation.answers, key) || Map.get(conversation.answers, String.to_atom(key))
  end

  # Intake, then parenthood_stage option 3 (I've lost a pregnancy / baby)
  defp walk_to_pl_opening(session_id) do
    simulate_whatsapp_message(session_id, "hello")
    simulate_whatsapp_message(session_id, "Ama")
    simulate_whatsapp_message(session_id, "28")
    simulate_whatsapp_message(session_id, "Accra")
    simulate_whatsapp_message(session_id, "1")
    simulate_whatsapp_message(session_id, "1")
    simulate_whatsapp_message(session_id, "3")

    conversation = get_conversation(session_id)
    assert conversation.current_question_id == "pl_opening"
  end

  # Continue -> timing -> physical check -> grief indicators
  defp walk_to_grief_indicators(session_id, timing, physical) do
    walk_to_pl_opening(session_id)
    simulate_whatsapp_message(session_id, "1")
    simulate_whatsapp_message(session_id, timing)
    simulate_whatsapp_message(session_id, physical)

    conversation = get_conversation(session_id)
    assert conversation.current_question_id == "pl_grief_indicators"
  end

  describe "PL-1 declining the conversation" do
    test "nurse offer accepted ends with a bereavement callback flag" do
      session_id = "+1555300001"
      walk_to_pl_opening(session_id)

      simulate_whatsapp_message(session_id, "2")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "pl_nurse_offer"

      simulate_whatsapp_message(session_id, "1")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "pl_nurse_confirmed"
      assert answer(conversation, "pl_nurse_offer") == "1"
      assert_message_sent(session_id, "in touch with you very soon")
    end

    test "nurse offer declined shows the crisis line and ends" do
      session_id = "+1555300002"
      walk_to_pl_opening(session_id)

      simulate_whatsapp_message(session_id, "2")
      simulate_whatsapp_message(session_id, "2")

      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "pl_crisis_number"
      assert_message_sent(session_id, "0800678678")
    end
  end

  describe "grief routing" do
    test "route A: one indicator, loss a while ago, exercise offered then EPDS transition" do
      session_id = "+1555300003"
      walk_to_grief_indicators(session_id, "3", "1")

      simulate_whatsapp_message(session_id, "2")
      # PL-5 safety screen: Never
      simulate_whatsapp_message(session_id, "4")

      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "pl_route_a"
      assert answer(conversation, "grief_route") == "A"

      # accept the exercise, then continue to the EPDS transition
      simulate_whatsapp_message(session_id, "1")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "pl_route_a_exercise"

      simulate_whatsapp_message(session_id, "okay")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "pl_epds_transition"

      simulate_whatsapp_message(session_id, "1")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "epds_q1"
    end

    test "route B: recent loss with one indicator, declining contact still continues" do
      session_id = "+1555300004"
      walk_to_grief_indicators(session_id, "1", "1")

      simulate_whatsapp_message(session_id, "2")
      simulate_whatsapp_message(session_id, "4")

      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "pl_route_b"
      assert answer(conversation, "grief_route") == "B"

      simulate_whatsapp_message(session_id, "2")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "pl_route_b_declined"

      simulate_whatsapp_message(session_id, "okay")
      # decline EPDS -> checkout (no physical concern flagged)
      simulate_whatsapp_message(session_id, "2")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "checkout_point"
    end

    test "route C: guilt plus functional impairment marks complicated grief and isolation" do
      session_id = "+1555300005"
      walk_to_grief_indicators(session_id, "2", "1")

      simulate_whatsapp_message(session_id, "3,5")
      simulate_whatsapp_message(session_id, "4")

      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "pl_route_c"
      assert answer(conversation, "grief_route") == "C"
      assert answer(conversation, "complicated_grief") == "true"

      # "Not really - carrying this alone"
      simulate_whatsapp_message(session_id, "2")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "pl_route_c_alone"
      assert answer(conversation, "social_isolation") == "true"
    end
  end

  describe "PL-5 safety screen" do
    test "'Hardly ever' escalates to the safety protocol (unlike EPDS Q10)" do
      session_id = "+1555300006"
      walk_to_grief_indicators(session_id, "3", "1")

      simulate_whatsapp_message(session_id, "8")
      simulate_whatsapp_message(session_id, "3")

      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "safety_protocol"
    end
  end

  describe "multi-select grief indicators" do
    test "invalid input re-prompts, valid input is stored normalized" do
      session_id = "+1555300007"
      walk_to_grief_indicators(session_id, "3", "1")

      simulate_whatsapp_message(session_id, "abc")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "pl_grief_indicators"
      assert_message_sent(session_id, "separated by commas")

      simulate_whatsapp_message(session_id, "3, 1")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "pl_safety_screen"
      assert answer(conversation, "pl_grief_indicators") == "1,3"
    end
  end

  describe "physical concern flagged at PL-3" do
    test "EPDS completion diverts through proxy questions and returns to the score route" do
      session_id = "+1555300008"
      walk_to_grief_indicators(session_id, "3", "2")

      simulate_whatsapp_message(session_id, "2")
      simulate_whatsapp_message(session_id, "4")
      # route A -> skip exercise -> transition -> accept EPDS
      simulate_whatsapp_message(session_id, "2")
      simulate_whatsapp_message(session_id, "okay")
      simulate_whatsapp_message(session_id, "1")

      # EPDS q1..q9 option 3 (score 12, mid tier), q10 Never
      for _ <- 1..9, do: simulate_whatsapp_message(session_id, "3")
      simulate_whatsapp_message(session_id, "4")

      conversation = get_conversation(session_id)

      assert conversation.current_question_id == "bp_proxy_q1",
             "physical concern should divert to proxy questions before the completion options"

      for _ <- 1..5, do: simulate_whatsapp_message(session_id, "2")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "bp_proxy_normal_pl"

      simulate_whatsapp_message(session_id, "okay")
      conversation = get_conversation(session_id)

      assert conversation.current_question_id == "epds_completion_mid",
             "after the proxy tail the user should see the score-resolved completion options"
    end

    test "declining the EPDS still routes through the proxy questions to checkout" do
      session_id = "+1555300009"
      walk_to_grief_indicators(session_id, "3", "2")

      simulate_whatsapp_message(session_id, "8")
      simulate_whatsapp_message(session_id, "4")
      simulate_whatsapp_message(session_id, "2")
      simulate_whatsapp_message(session_id, "okay")
      # decline EPDS at the transition
      simulate_whatsapp_message(session_id, "2")

      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "bp_proxy_q1"

      for _ <- 1..5, do: simulate_whatsapp_message(session_id, "2")
      simulate_whatsapp_message(session_id, "okay")

      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "checkout_point"
    end
  end
end
