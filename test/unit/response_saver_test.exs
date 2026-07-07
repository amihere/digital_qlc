defmodule QlcDigital.Unit.ResponseSaverTest do
  use ExUnit.Case

  alias QlcDigital.ResponseSaver
  alias QlcDigital.Question.Conversation

  defp conversation(answers) do
    %Conversation{
      session_id: "+1999000000",
      answers: answers,
      started_at: ~U[2026-07-04 10:00:00Z]
    }
  end

  describe "build_structured_fields/1" do
    test "intake-only conversation has identity fields and no flags" do
      fields =
        conversation(%{
          "start" => "Ama",
          "parenthood_stage" => "4",
          "nursing_mother_concerns" => "3"
        })
        |> ResponseSaver.build_structured_fields()

      assert fields[:phone_number] == "+1999000000"
      assert fields[:name] == "Ama"
      assert fields[:session_date] =~ "2026-07-04"
      assert fields[:pathways] =~ "nursing mother"
      assert fields[:pathways] =~ "stressed and anxious"

      refute Map.has_key?(fields, :epds_score)
      refute Map.has_key?(fields, :epds_depression_flag)
      refute Map.has_key?(fields, :action_required)
    end

    test "EPDS at the depression cutoff sets both score fields and flags" do
      fields =
        conversation(%{
          "start" => "Ama",
          "epds_raw_score" => "13",
          "epds_anxiety_score" => "6",
          "epds_q10" => "4"
        })
        |> ResponseSaver.build_structured_fields()

      assert fields[:epds_score] == 13
      assert fields[:epds_depression_flag] == "Probable Depression - nurse call required"
      assert fields[:epds_anxiety_score] == 6
      assert fields[:epds_anxiety_flag] == "Elevated Anxiety - nurse review required"
      refute Map.has_key?(fields, :q10_safety_flag)

      assert fields[:action_required] =~ "Probable Depression"
      assert fields[:action_required] =~ "Elevated Anxiety"
    end

    test "below both thresholds no flags are set" do
      fields =
        conversation(%{
          "start" => "Ama",
          "epds_raw_score" => "12",
          "epds_anxiety_score" => "5",
          "epds_q10" => "4"
        })
        |> ResponseSaver.build_structured_fields()

      assert fields[:epds_score] == 12
      refute Map.has_key?(fields, :epds_depression_flag)
      refute Map.has_key?(fields, :epds_anxiety_flag)
      refute Map.has_key?(fields, :action_required)
    end

    test "any Q10 answer other than Never sets the safety flag first in action_required" do
      fields =
        conversation(%{
          "start" => "Ama",
          "epds_raw_score" => "13",
          "epds_anxiety_score" => "2",
          "epds_q10" => "3"
        })
        |> ResponseSaver.build_structured_fields()

      assert fields[:q10_safety_flag] =~ "SAFETY - IMMEDIATE ACTION REQUIRED"
      assert String.starts_with?(fields[:action_required], "SAFETY - IMMEDIATE ACTION REQUIRED")
    end

    test "a PL-5 safety answer sets the same safety flag" do
      fields =
        conversation(%{"start" => "Ama", "pl_safety_screen" => "2"})
        |> ResponseSaver.build_structured_fields()

      assert fields[:q10_safety_flag] =~ "SAFETY - IMMEDIATE ACTION REQUIRED"
    end

    test "BP emergency values land in the fields and action_required" do
      fields =
        conversation(%{
          "start" => "Ama",
          "bp_systolic" => "165",
          "bp_diastolic" => "95",
          "bp_flag" => "BP_EMERGENCY"
        })
        |> ResponseSaver.build_structured_fields()

      assert fields[:bp_systolic] == 165
      assert fields[:bp_diastolic] == 95
      assert fields[:bp_flag] == "BP_EMERGENCY"
      assert fields[:action_required] =~ "BP_EMERGENCY"
    end

    test "grief route C carries priority, complicated grief and isolation flags" do
      fields =
        conversation(%{
          "start" => "Ama",
          "grief_route" => "C",
          "complicated_grief" => "true",
          "social_isolation" => "true",
          "bp_proxy_count" => "1",
          "bp_flag" => "BP_PROXY_MILD"
        })
        |> ResponseSaver.build_structured_fields()

      assert fields[:grief_route] == "C"
      assert fields[:bp_proxy_count] == 1
      assert fields[:action_required] =~ "GRIEF - PRIORITY NURSE CALL (Route C)"
      assert fields[:action_required] =~ "COMPLICATED_GRIEF"
      assert fields[:action_required] =~ "SOCIAL_ISOLATION"
      assert fields[:action_required] =~ "BP_PROXY_MILD"
    end

    test "grief route B distinguishes requested vs declined contact" do
      requested =
        conversation(%{"grief_route" => "B", "pl_route_b" => "1"})
        |> ResponseSaver.build_structured_fields()

      declined =
        conversation(%{"grief_route" => "B", "pl_route_b" => "2"})
        |> ResponseSaver.build_structured_fields()

      assert requested[:action_required] =~ "GRIEF - NURSE CALL REQUESTED (Route B)"
      assert declined[:action_required] =~ "GRIEF - DECLINED CONTACT (Route B)"
    end

    test "an sos trigger appears in action_required" do
      fields =
        conversation(%{"start" => "Ama", "sos_flag" => "triggered"})
        |> ResponseSaver.build_structured_fields()

      assert fields[:action_required] =~ "SOS"
    end

    test "works with atom answer keys (post-Redis-reload shape)" do
      fields =
        conversation(%{start: "Ama", epds_raw_score: "14", epds_anxiety_score: "7"})
        |> ResponseSaver.build_structured_fields()

      assert fields[:name] == "Ama"
      assert fields[:epds_score] == 14
      assert fields[:epds_depression_flag] =~ "Probable Depression"
      assert fields[:epds_anxiety_flag] =~ "Elevated Anxiety"
    end
  end
end
