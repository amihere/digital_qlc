defmodule QlcDigital.SignupHandler do
  @moduledoc """
  Handles creating and updating user signups in Airtable with bio information
  """

  alias QlcDigital.{AirtableClient, Signup}
  alias QlcDigital.Question.{Conversation, QuestionConfig}

  @signups_table "Signups"

  def upsert_bio_info(%Conversation{} = conversation) do
    bio_data = extract_bio_info(conversation)
    client = AirtableClient.new(@signups_table)

    AirtableClient.upsert_record(client, conversation.session_id, bio_data)
  end

  def upsert_bio_info(phone_number, name, location, country) do
    bio_data =
      %{
        name: name,
        phone_number: phone_number,
        location: location,
        country: country
      }
      |> Enum.filter(fn {_key, value} -> value != nil end)
      |> Enum.into(%{})

    client = AirtableClient.new(@signups_table)
    AirtableClient.upsert_record(client, phone_number, bio_data)
  end

  defp extract_bio_info(%Conversation{} = conversation) do
    answers = conversation.answers || %{}

    %{
      name: answers["start"],
      phone_number: conversation.session_id,
      age: answers["privacy_intro"],
      location: answers["location"],
      country: convert_choice_to_text("country", answers["country"]),
      mental_health_experience:
        convert_choice_to_text("mental_health_experience", answers["mental_health_experience"])
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

