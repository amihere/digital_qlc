defmodule QlcDigital.ResponseSaver do
  @moduledoc """
  Saves complete conversation responses to Airtable with meaningful answers
  """

  alias QlcDigital.{AirtableClient}
  alias QlcDigital.Question.{Conversation, QuestionConfig}

  @responses_table "Responses"

  def save_complete_response(%Conversation{} = conversation) do
    response_data = build_response_data(conversation)
    client = AirtableClient.new(@responses_table)

    AirtableClient.upsert_record(client, conversation.session_id, response_data)
  end

  defp build_response_data(%Conversation{} = conversation) do
    answers = conversation.answers || %{}

    age =
      case map_correct_value(answers, :privacy_intro) |> Integer.parse() do
        {age, _} -> age
        :error -> nil
      end

    %{
      phone_number: conversation.session_id,
      name: map_correct_value(answers, :start),
      age: age,
      location: map_correct_value(answers, :location),
      country: get_country_value(answers),
      mental_health_experience:
        convert_choice_to_text(
          "mental_health_experience",
          map_correct_value(answers, :mental_health_experience)
        ),
      parenthood_stage:
        convert_choice_to_text("parenthood_stage", map_correct_value(answers, :parenthood_stage)),
      nursing_concerns:
        convert_choice_to_text(
          "nursing_mother_concerns",
          map_correct_value(answers, :nursing_mother_concerns)
        ),
      epds_score: map_correct_value(answers, :epds_score),
      epds_q1: convert_choice_to_text("epds_q1", map_correct_value(answers, :epds_q1)),
      epds_q2: convert_choice_to_text("epds_q2", map_correct_value(answers, :epds_q2)),
      epds_q3: convert_choice_to_text("epds_q3", map_correct_value(answers, :epds_q3)),
      epds_q4: convert_choice_to_text("epds_q4", map_correct_value(answers, :epds_q4)),
      epds_q5: convert_choice_to_text("epds_q5", map_correct_value(answers, :epds_q5)),
      epds_q6: convert_choice_to_text("epds_q6", map_correct_value(answers, :epds_q6)),
      epds_q7: convert_choice_to_text("epds_q7", map_correct_value(answers, :epds_q7)),
      epds_q8: convert_choice_to_text("epds_q8", map_correct_value(answers, :epds_q8)),
      epds_q9: convert_choice_to_text("epds_q9", map_correct_value(answers, :epds_q9)),
      epds_q10: convert_choice_to_text("epds_q10", map_correct_value(answers, :epds_q10)),
      feedback: map_correct_value(answers, :feedback_request),
      checkout_choice:
        convert_choice_to_text("checkout_point", map_correct_value(answers, :checkout_point)),
      notes: "From the Whatsapp Bot"
    }
    |> Enum.filter(fn {_key, value} -> value != nil end)
    |> Enum.into(%{})
  end

  defp get_country_value(answers) do
    country_choice = convert_choice_to_text("country", map_correct_value(answers, :country))

    if country_choice == "Other (please type)" do
      map_correct_value(answers, :country_other)
    else
      country_choice
    end
  end

  defp convert_choice_to_text(question_id, answer) when is_binary(answer) do
    question = QuestionConfig.get_question(question_id)

    if question && question.type == :choice do
      case Integer.parse(answer) do
        {index, ""} when index >= 1 and index <= length(question.options) ->
          Enum.at(question.options, index - 1)

        _ ->
          answer
      end
    else
      answer
    end
  end

  defp convert_choice_to_text(_question_id, answer), do: answer

  defp map_correct_value(map, key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end
end
