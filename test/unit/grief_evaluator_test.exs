defmodule QlcDigital.Unit.GriefEvaluatorTest do
  use ExUnit.Case

  alias QlcDigital.GriefEvaluator

  # PL-4 option indices: 3 = guilt, 4 = avoidance, 5 = functional impairment,
  # 8 = "None of these". PL-2 timing: "3" = it has been a while.

  describe "Route A - mild / integrated grief" do
    test "no indicators and loss a while ago" do
      assert %{route: "A", complicated: false} = GriefEvaluator.evaluate("8", "3")
    end

    test "one indicator and loss a while ago" do
      assert %{route: "A"} = GriefEvaluator.evaluate("2", "3")
    end

    test "'None of these' combined with one indicator still counts as one" do
      assert %{route: "A"} = GriefEvaluator.evaluate("2,8", "3")
    end
  end

  describe "Route B - acute / significant grief (escalation default)" do
    test "one indicator but the loss was recent" do
      assert %{route: "B"} = GriefEvaluator.evaluate("2", "1")
      assert %{route: "B"} = GriefEvaluator.evaluate("2", "2")
    end

    test "two to four indicators regardless of timing" do
      assert %{route: "B"} = GriefEvaluator.evaluate("1,2", "3")
      assert %{route: "B"} = GriefEvaluator.evaluate("1,2,3,4", "1")
    end

    test "missing timing escalates to B rather than A" do
      assert %{route: "B"} = GriefEvaluator.evaluate("8", nil)
    end

    test "functional impairment without guilt or avoidance is not route C" do
      assert %{route: "B", complicated: false} = GriefEvaluator.evaluate("1,5", "3")
    end
  end

  describe "Route C - complicated / prolonged grief" do
    test "five or more indicators" do
      assert %{route: "C", complicated: true} = GriefEvaluator.evaluate("1,2,3,4,6", "3")
    end

    test "functional impairment alongside guilt" do
      assert %{route: "C", complicated: true} = GriefEvaluator.evaluate("3,5", "3")
    end

    test "functional impairment alongside avoidance" do
      assert %{route: "C", complicated: true} = GriefEvaluator.evaluate("4,5", "1")
    end
  end
end
