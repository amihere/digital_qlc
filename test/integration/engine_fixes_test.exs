defmodule QlcDigital.Integration.EngineFixesTest do
  use ExUnit.Case

  import QlcDigital.TestHelpers

  setup do
    reset_test_state()
    :ok
  end

  # Walks a fresh session through intake up to (and including) answering
  # nursing_mother_concerns option 1, landing on sad_disconnected_intro.
  defp walk_to_epds_intro(session_id) do
    simulate_whatsapp_message(session_id, "hello")
    simulate_whatsapp_message(session_id, "Bob")
    simulate_whatsapp_message(session_id, "30")
    simulate_whatsapp_message(session_id, "Kanda")
    # country -> Ghana
    simulate_whatsapp_message(session_id, "1")
    # mental_health_experience
    simulate_whatsapp_message(session_id, "1")
    # parenthood_stage -> nursing mother (option 4)
    simulate_whatsapp_message(session_id, "4")
    # nursing_mother_concerns -> sad/disconnected
    simulate_whatsapp_message(session_id, "1")
  end

  describe "choice answers typed as option text" do
    test "are stored as the option index and still route correctly" do
      session_id = "+1555000001"

      simulate_whatsapp_message(session_id, "hello")
      simulate_whatsapp_message(session_id, "Bob")
      simulate_whatsapp_message(session_id, "30")
      simulate_whatsapp_message(session_id, "Kanda")
      # Answer the country choice with the full option text instead of "1"
      simulate_whatsapp_message(session_id, "Ghana")

      conversation = get_conversation(session_id)
      assert conversation != nil

      assert conversation.current_question_id == "mental_health_experience",
             "typing the option text should route the same as typing its number"

      answer =
        Map.get(conversation.answers, :country) || Map.get(conversation.answers, "country")

      assert answer == "1"
    end
  end

  describe "EPDS completion routing" do
    test "a mid score resolves to epds_completion_mid at answer time and accepts all its options" do
      session_id = "+1555000002"

      walk_to_epds_intro(session_id)
      # sad_disconnected_intro -> yes, continue to EPDS
      simulate_whatsapp_message(session_id, "1")

      # q1..q9 all option 3 => 2+2+1+2+1+1+1+1+1 = 12 (mid tier)
      for _ <- 1..9, do: simulate_whatsapp_message(session_id, "3")
      # q10 -> Never (score 0, no safety protocol)
      simulate_whatsapp_message(session_id, "4")

      conversation = get_conversation(session_id)

      assert conversation.current_question_id == "epds_completion_mid",
             "the stored question id should be the score-resolved variant, not epds_completion"

      # Option 3 ("Just rest for now...") only exists on the mid variant;
      # answering it must validate and route to rest_choice.
      simulate_whatsapp_message(session_id, "3")

      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "rest_choice"
    end
  end

  describe "sos meta-command" do
    test "routes to a real crisis_checkin question that shows the helpline number" do
      session_id = "+1555000003"

      simulate_whatsapp_message(session_id, "hello")
      simulate_whatsapp_message(session_id, "Bob")
      simulate_whatsapp_message(session_id, "sos")

      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "crisis_checkin"

      assert_message_sent(session_id, "0800678678")

      # Confirming the number routes on to the terminal safety confirmation
      simulate_whatsapp_message(session_id, "1")
      conversation = get_conversation(session_id)
      assert conversation.current_question_id == "safety_confirmation"
    end
  end
end
