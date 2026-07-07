defmodule QlcDigital.Unit.BpEvaluatorTest do
  use ExUnit.Case

  alias QlcDigital.BpEvaluator

  describe "evaluate_reading/2 thresholds" do
    test "normal below 140/90" do
      assert BpEvaluator.evaluate_reading("139", "89") == :normal
      assert BpEvaluator.evaluate_reading("120", "80") == :normal
    end

    test "concern at 140-159 systolic or 90-109 diastolic" do
      assert BpEvaluator.evaluate_reading("140", "80") == :concern
      assert BpEvaluator.evaluate_reading("120", "90") == :concern
      assert BpEvaluator.evaluate_reading("159", "109") == :concern
    end

    test "emergency at >=160 systolic or >=110 diastolic" do
      assert BpEvaluator.evaluate_reading("160", "80") == :emergency
      assert BpEvaluator.evaluate_reading("120", "110") == :emergency
      assert BpEvaluator.evaluate_reading("200", "120") == :emergency
    end

    test "unparseable or skipped values escalate to concern, never normal or emergency" do
      # number questions store "" when the user types skip
      assert BpEvaluator.evaluate_reading("", "80") == :concern
      assert BpEvaluator.evaluate_reading("120", "") == :concern
      assert BpEvaluator.evaluate_reading("abc", "def") == :concern
      assert BpEvaluator.evaluate_reading(nil, nil) == :concern
    end
  end

  describe "evaluate_proxy/1 symptom counting" do
    test "no symptoms is normal" do
      assert BpEvaluator.evaluate_proxy(["2", "2", "2", "2", "2"]) == {0, :normal}
    end

    test "exactly one symptom is a mild flag" do
      assert BpEvaluator.evaluate_proxy(["2", "1", "2", "2", "2"]) == {1, :flag}
    end

    test "two or more symptoms is an emergency" do
      assert BpEvaluator.evaluate_proxy(["1", "1", "2", "2", "2"]) == {2, :emergency}
      assert BpEvaluator.evaluate_proxy(["1", "1", "1", "1", "1"]) == {5, :emergency}
    end

    test "missing answers count as no" do
      assert BpEvaluator.evaluate_proxy(["1", nil, "2", nil, "2"]) == {1, :flag}
    end
  end
end
