defmodule QlcDigital.EpdsScorer do
  @moduledoc """
  Handles EPDS (Edinburgh Postnatal Depression Scale) scoring
  """

  # EPDS scoring map - each question has different scoring based on its options
  @scoring_map %{
    "epds_q1" => %{
      "As much as I always could" => 0,
      "Not quite so much now" => 1,
      "Definitely not so much now" => 2,
      "Not at all" => 3
    },
    "epds_q2" => %{
      "As much as I ever did" => 0,
      "Rather less than I used to" => 1,
      "Definitely less than I used to" => 2,
      "Hardly at all" => 3
    },
    "epds_q3" => %{
      "No never" => 0,
      "Not very often" => 1,
      "Yes some of the time" => 2,
      "Yes most of the time" => 3
    },
    "epds_q4" => %{
      "No not at all" => 0,
      "Hardly ever" => 1,
      "Yes sometimes" => 2,
      "Yes very often" => 3
    },
    "epds_q5" => %{
      "No not at all" => 0,
      "No not much" => 1,
      "Yes sometimes" => 2,
      "Yes quite a lot" => 3
    },
    "epds_q6" => %{
      "No I have been coping as well as ever" => 0,
      "No most of the time I have coped quite well" => 1,
      "Yes sometimes I haven't been coping as well as usual" => 2,
      "Yes most of the time I haven't been able to cope at all" => 3
    },
    "epds_q7" => %{
      "No not at all" => 0,
      "Not very often" => 1,
      "Yes sometimes" => 2,
      "Yes most of the time" => 3
    },
    "epds_q8" => %{
      "No not at all" => 0,
      "Not very often" => 1,
      "Yes quite often" => 2,
      "Yes most of the time" => 3
    },
    "epds_q9" => %{
      "No never" => 0,
      "Only occasionally" => 1,
      "Yes quite often" => 2,
      "Yes most of the time" => 3
    },
    "epds_q10" => %{
      "Never" => 0,
      "Hardly ever" => 1,
      "Sometimes" => 2,
      "Yes quite often" => 3
    }
  }

  alias QlcDigital.Question.{Conversation, QuestionConfig}

  def calculate_epds_score(%Conversation{} = conversation) do
    answers = conversation.answers || %{}

    epds_questions = [
      "epds_q1",
      "epds_q2",
      "epds_q3",
      "epds_q4",
      "epds_q5",
      "epds_q6",
      "epds_q7",
      "epds_q8",
      "epds_q9",
      "epds_q10"
    ]

    total_score =
      epds_questions
      |> Enum.map(fn question_id ->
        score_question(question_id, answers[question_id])
      end)
      |> Enum.sum()

    # Special condition: if epds_q10 is answered with option 1 or 2 (index-based), upgrade to highest score
    final_score = check_q10_special_condition(answers["epds_q10"], total_score)

    %{
      total_score: final_score,
      max_score: 30,
      interpretation: interpret_score(final_score)
    }
  end

  def format_epds_summary(%Conversation{} = conversation) do
    score_data = calculate_epds_score(conversation)

    "Your EPDS assessment score: #{score_data.total_score}/#{score_data.max_score}. #{score_data.interpretation}"
  end

  defp score_question(question_id, answer) when is_binary(answer) do
    # Convert numeric answer to text if needed
    text_answer = convert_numeric_to_text(question_id, answer)

    scoring = Map.get(@scoring_map, question_id, %{})
    Map.get(scoring, text_answer, 0)
  end

  defp score_question(_question_id, _answer), do: 0

  defp convert_numeric_to_text(question_id, answer) do
    case Integer.parse(answer) do
      {index, ""} when index >= 1 ->
        question = QuestionConfig.get_question(question_id)

        if question && question.options do
          Enum.at(question.options, index - 1) || answer
        else
          answer
        end

      _ ->
        answer
    end
  end

  defp check_q10_special_condition(q10_answer, current_score) when is_binary(q10_answer) do
    case Integer.parse(q10_answer) do
      # Option 1 selected (Yes quite often) - upgrade to highest score
      {1, ""} ->
        30

      # Option 2 selected (Sometimes) - upgrade to highest score
      {2, ""} ->
        30

      _ ->
        # Check if text answer matches options 1 or 2
        case q10_answer do
          # Option 1 text
          "Yes quite often" -> 30
          # Option 2 text
          "Sometimes" -> 30
          _ -> current_score
        end
    end
  end

  defp check_q10_special_condition(_q10_answer, current_score), do: current_score

  defp interpret_score(score) when score >= 13,
    do: "Likely depression - recommend professional support"

  defp interpret_score(score) when score >= 10,
    do: "Possible depression - consider professional consultation"

  defp interpret_score(score) when score >= 6, do: "Mild symptoms - monitor and self-care"
  defp interpret_score(_score), do: "Minimal symptoms"
end

