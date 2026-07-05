defmodule QlcDigital.Unit.MultiChoiceTest do
  use ExUnit.Case

  alias QlcDigital.Question.Session

  @options ["Accept", "Numb", "Guilt", "Avoidance", "Functioning", "Missing", "Waves", "None"]

  describe "parse_multi_choice/2" do
    test "accepts comma-separated indices and keeps them sorted" do
      assert {:ok, "1,3,5"} = Session.parse_multi_choice("1,3,5", length(@options))
      assert {:ok, "1,3"} = Session.parse_multi_choice("3, 1", length(@options))
    end

    test "accepts space-separated indices" do
      assert {:ok, "1,3,5"} = Session.parse_multi_choice("1 3 5", length(@options))
    end

    test "accepts a single index and deduplicates repeats" do
      assert {:ok, "5"} = Session.parse_multi_choice("5", length(@options))
      assert {:ok, "5"} = Session.parse_multi_choice("5,5", length(@options))
    end

    test "rejects out-of-range, non-numeric, and empty input" do
      assert :error = Session.parse_multi_choice("0,2", length(@options))
      assert :error = Session.parse_multi_choice("9", length(@options))
      assert :error = Session.parse_multi_choice("abc", length(@options))
      assert :error = Session.parse_multi_choice("1,abc", length(@options))
      assert :error = Session.parse_multi_choice("", length(@options))
    end
  end

  describe "display_question/2 for multi_choice" do
    test "lists every option and explains multi-select input" do
      question = %{
        id: "pl_grief_indicators",
        type: :multi_choice,
        text: "Which feels most true for you right now?",
        options: @options,
        next: "pl_safety_screen"
      }

      rendered = Session.display_question(question, %{"start" => "Ama"})

      for {option, index} <- Enum.with_index(@options, 1) do
        assert String.contains?(rendered, "#{index} #{option}")
      end

      assert String.contains?(rendered, "more than one")
      assert String.contains?(rendered, "1,3")
    end
  end
end
