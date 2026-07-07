defmodule QlcDigital.Unit.EpdsScorerTest do
  use ExUnit.Case

  alias QlcDigital.EpdsScorer
  alias QlcDigital.Question.Conversation

  defp conversation(answers) do
    %Conversation{session_id: "+1000000000", answers: answers}
  end

  describe "calculate_anxiety_subscore/1 (EPDS Q3+Q4+Q5)" do
    test "scores the reversed items correctly at the maximum" do
      # q3 option 1 = "Yes most of the time" = 3
      # q4 option 4 = "Yes very often" = 3
      # q5 option 1 = "Yes quite a lot" = 3
      result =
        conversation(%{"epds_q3" => "1", "epds_q4" => "4", "epds_q5" => "1"})
        |> EpdsScorer.calculate_anxiety_subscore()

      assert result.score == 9
      assert result.flagged == true
    end

    test "scores the minimum as zero and does not flag" do
      result =
        conversation(%{"epds_q3" => "4", "epds_q4" => "1", "epds_q5" => "4"})
        |> EpdsScorer.calculate_anxiety_subscore()

      assert result.score == 0
      assert result.flagged == false
    end

    test "flags exactly at the threshold of 6" do
      # 3 + 2 + 1
      result =
        conversation(%{"epds_q3" => "1", "epds_q4" => "3", "epds_q5" => "3"})
        |> EpdsScorer.calculate_anxiety_subscore()

      assert result.score == 6
      assert result.flagged == true
    end

    test "does not flag at 5" do
      # 2 + 2 + 1
      result =
        conversation(%{"epds_q3" => "2", "epds_q4" => "3", "epds_q5" => "3"})
        |> EpdsScorer.calculate_anxiety_subscore()

      assert result.score == 5
      assert result.flagged == false
    end

    test "works with atom answer keys (post-Redis-reload shape)" do
      result =
        conversation(%{epds_q3: "1", epds_q4: "4", epds_q5: "1"})
        |> EpdsScorer.calculate_anxiety_subscore()

      assert result.score == 9
    end
  end

  describe "calculate_epds_score/1 raw_total" do
    test "raw_total is the uninflated sum even when the Q10 override applies" do
      # All option 1: q1=0 q2=0 q3=3 q4=0 q5=3 q6=3 q7=3 q8=3 q9=3 q10=3 -> 21
      answers = Map.new(1..10, fn i -> {"epds_q#{i}", "1"} end)

      result = EpdsScorer.calculate_epds_score(conversation(answers))

      # Q10 option 1 forces the routing score to 30
      assert result.total_score == 30
      assert result.raw_total == 21
    end

    test "raw_total equals total_score when Q10 is Never" do
      # q1..q9 option 3 = 2+2+1+2+1+1+1+1+1 = 12, q10 option 4 (Never) = 0
      answers =
        Map.new(1..9, fn i -> {"epds_q#{i}", "3"} end)
        |> Map.put("epds_q10", "4")

      result = EpdsScorer.calculate_epds_score(conversation(answers))

      assert result.total_score == 12
      assert result.raw_total == 12
    end
  end
end
