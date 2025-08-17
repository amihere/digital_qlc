defmodule QlcDigital.SignupHandler do
  @moduledoc """
  Handles creating and updating user signups in Airtable with bio information
  """

  alias QlcDigital.{AirtableClient}
  alias QlcDigital.Question.{Conversation, QuestionConfig}

  @signups_table "Signups"

  def upsert_bio_info(%Conversation{} = conversation) do
    IO.inspect(conversation.answers)
    bio_data = extract_bio_info(conversation)
    client = AirtableClient.new(@signups_table)
    IO.inspect(bio_data)

    AirtableClient.upsert_record(client, conversation.session_id, bio_data)
  end

  defp extract_bio_info(%Conversation{} = conversation) do
    answers = conversation.answers || %{}

    %{
      name: map_correct_value(answers, :start),
      phone_number: conversation.session_id,
      age: map_correct_value(answers, :privacy_intro),
      location: map_correct_value(answers, :location),
      country: get_country_value(answers),
      mental_health_experience:
        convert_choice_to_text(
          "mental_health_experience",
          map_correct_value(answers, :mental_health_experience)
        ),
      notes: "From the Whatsapp Bot"
    }
    |> Enum.filter(fn {_key, value} -> value != nil end)
    |> Enum.into(%{})
  end

  defp map_correct_value(map, key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end

  defp get_country_value(answers) do
    country_choice = convert_choice_to_text("country", map_correct_value(answers, :country))

    if country_choice == "Other (please type)" do
      map_correct_value(answers, :country_other)
    else
      country_choice
    end
  end

  defp convert_choice_to_text(_question_id, nil), do: nil

  defp convert_choice_to_text(question_id, answer) when is_binary(answer) do
    question = QuestionConfig.get_question(question_id)

    if question && question.type == :choice do
      case Integer.parse(answer) do
        {index, ""} when index >= 1 and index <= length(question.options) ->
          Enum.at(question.options, index - 1)

        _ ->
          # Answer is already text or invalid number
          answer
      end
    else
      answer
    end
  end
end
