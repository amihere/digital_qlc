defmodule QlcDigital.SignupHandler do
  @moduledoc """
  Handles creating and updating user signups in Airtable with bio information
  """

  alias QlcDigital.{AirtableClient}
  alias QlcDigital.Question.{Conversation, QuestionConfig}

  @signups_table "Signups"

  def upsert_bio_info(%Conversation{} = conversation) do
    IO.inspect(conversation.answers, label: "all answers")
    bio_data = extract_bio_info(conversation)
    client = AirtableClient.new(@signups_table)

    AirtableClient.upsert_record(client, conversation.session_id, bio_data)
  end

  defp extract_bio_info(%Conversation{} = conversation) do
    answers = conversation.answers || %{}

    mental_health_experience = Map.get(answers, :mental_health_experience)

    # mental_health_experience = answers["mental_health_experience"] || Map.get(answers, :mental_health_experience)

    %{
      name: Map.get(answers, :start),
      phone_number: conversation.session_id,
      age: Map.get(answers, :privacy_intro),
      location: Map.get(answers, :location),
      country: convert_choice_to_text("country", Map.get(answers, :country)),
      mental_health_experience:
        convert_choice_to_text("mental_health_experience", mental_health_experience),
      notes: "From Whatsapp Bot"
    }
    |> Enum.filter(fn {_key, value} -> value != nil end)
    |> Enum.into(%{})
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
