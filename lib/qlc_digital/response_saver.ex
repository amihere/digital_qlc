defmodule QlcDigital.ResponseSaver do
  @moduledoc """
  Saves complete conversation responses to Airtable with meaningful answers
  """

  require Logger
  alias QlcDigital.{AirtableClient}
  alias QlcDigital.Question.{Conversation, QuestionConfig}

  @responses_table "Responses"

  @depression_flag_threshold 13
  @anxiety_flag_threshold 6

  def save_complete_response(%Conversation{} = conversation) do
    response_data =
      build_structured_fields(conversation)
      |> Map.merge(build_response_data(conversation))

    client = AirtableClient.new(@responses_table)

    Logger.debug("saving response")
    res = AirtableClient.upsert_record(client, conversation.session_id, response_data)
    Logger.debug(inspect(res))
  end

  @doc """
  Writes the current structured flag fields to the Responses record without
  waiting for the conversation to finish. Used for emergency/safety triggers
  so the nurse dashboard updates mid-session.
  """
  def save_flag_snapshot(%Conversation{} = conversation) do
    fields = build_structured_fields(conversation)
    client = AirtableClient.new(@responses_table)

    Logger.info("saving flag snapshot for #{conversation.session_id}")
    res = AirtableClient.upsert_record(client, conversation.session_id, fields)
    Logger.debug(inspect(res))
  end

  @doc """
  The structured nurse-dashboard fields for the Responses table. Only fields
  with values are included; flags are derived from stored answers.
  """
  def build_structured_fields(%Conversation{} = conversation) do
    answers = conversation.answers || %{}

    epds_raw = parse_int(map_correct_value(answers, :epds_raw_score))
    anxiety_score = parse_int(map_correct_value(answers, :epds_anxiety_score))

    fields = %{
      phone_number: conversation.session_id,
      name: map_correct_value(answers, :start),
      session_date: format_session_date(conversation.started_at),
      pathways: build_pathways(answers),
      epds_score: epds_raw,
      epds_depression_flag: depression_flag(epds_raw),
      epds_anxiety_score: anxiety_score,
      epds_anxiety_flag: anxiety_flag(anxiety_score),
      q10_safety_flag: safety_flag(answers),
      bp_systolic: parse_int(map_correct_value(answers, :bp_systolic)),
      bp_diastolic: parse_int(map_correct_value(answers, :bp_diastolic)),
      bp_proxy_count: parse_int(map_correct_value(answers, :bp_proxy_count)),
      bp_flag: map_correct_value(answers, :bp_flag),
      grief_route: map_correct_value(answers, :grief_route)
    }

    fields
    |> Map.put(:action_required, build_action_required(fields, answers))
    |> Enum.filter(fn {_key, value} -> value != nil end)
    |> Map.new()
  end

  defp depression_flag(raw) when is_integer(raw) and raw >= @depression_flag_threshold,
    do: "Probable Depression - nurse call required"

  defp depression_flag(_raw), do: nil

  defp anxiety_flag(score) when is_integer(score) and score >= @anxiety_flag_threshold,
    do: "Elevated Anxiety - nurse review required"

  defp anxiety_flag(_score), do: nil

  # Any answer other than "Never" (option 4) on the self-harm question flags,
  # whether it came from EPDS Q10 or the pregnancy-loss safety screen (PL-5)
  defp safety_flag(answers) do
    q10 = map_correct_value(answers, :epds_q10)
    pl = map_correct_value(answers, :pl_safety_screen)

    cond do
      q10 in ["1", "2", "3"] ->
        "SAFETY - IMMEDIATE ACTION REQUIRED (#{convert_choice_to_text("epds_q10", q10)})"

      pl in ["1", "2", "3"] ->
        "SAFETY - IMMEDIATE ACTION REQUIRED (#{convert_choice_to_text("pl_safety_screen", pl)})"

      true ->
        nil
    end
  end

  defp build_pathways(answers) do
    parts =
      [
        convert_choice_to_text(
          "parenthood_stage",
          map_correct_value(answers, :parenthood_stage)
        ),
        convert_choice_to_text(
          "nursing_mother_concerns",
          map_correct_value(answers, :nursing_mother_concerns)
        )
      ]
      |> Enum.filter(& &1)

    if parts == [], do: nil, else: Enum.join(parts, "; ")
  end

  # Consolidated nurse-facing field, most urgent first
  defp build_action_required(fields, answers) do
    entries =
      [
        fields.q10_safety_flag,
        if(map_correct_value(answers, :sos_flag), do: "SOS - IMMEDIATE ATTENTION"),
        if(fields.bp_flag in ["BP_EMERGENCY", "BP_PROXY_EMERGENCY"], do: fields.bp_flag),
        if(fields.grief_route == "C", do: "GRIEF - PRIORITY NURSE CALL (Route C)"),
        if(map_correct_value(answers, :complicated_grief), do: "COMPLICATED_GRIEF"),
        if(fields.bp_flag in ["BP_CONCERN", "BP_PROXY_MILD"], do: fields.bp_flag),
        grief_contact_flag(answers),
        if(map_correct_value(answers, :social_isolation), do: "SOCIAL_ISOLATION"),
        fields.epds_depression_flag,
        fields.epds_anxiety_flag
      ]
      |> Enum.filter(& &1)

    if entries == [], do: nil, else: Enum.join(entries, " | ")
  end

  defp grief_contact_flag(answers) do
    case {map_correct_value(answers, :pl_route_b), map_correct_value(answers, :pl_nurse_offer)} do
      {"1", _} -> "GRIEF - NURSE CALL REQUESTED (Route B)"
      {"2", _} -> "GRIEF - DECLINED CONTACT (Route B)"
      {_, "1"} -> "GRIEF - NURSE CALL REQUESTED"
      {_, "2"} -> "GRIEF - DECLINED CONTACT"
      _ -> nil
    end
  end

  defp parse_int(value) when is_integer(value), do: value

  defp parse_int(value) when is_binary(value) do
    case Integer.parse(value) do
      {number, _} -> number
      :error -> nil
    end
  end

  defp parse_int(_value), do: nil

  defp format_session_date(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp format_session_date(datetime) when is_binary(datetime), do: datetime
  defp format_session_date(_datetime), do: nil

  defp build_response_data(%Conversation{} = conversation) do
    answers = conversation.answers || %{}

    age =
      case map_correct_value(answers, :privacy_intro) |> Integer.parse() do
        {age, _} -> age
        :error -> nil
      end

    notes =
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
          convert_choice_to_text(
            "parenthood_stage",
            map_correct_value(answers, :parenthood_stage)
          ),
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
      |> Enum.map(fn {k, v} -> "#{k}-> #{v}" end)
      |> Enum.join("\n")

    %{
      phone_number: conversation.session_id,
      notes: inspect(notes)
    }
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

    cond do
      question && question.type == :choice ->
        case Integer.parse(answer) do
          {index, ""} when index >= 1 and index <= length(question.options) ->
            Enum.at(question.options, index - 1)

          _ ->
            answer
        end

      question && question.type == :multi_choice ->
        answer
        |> String.split(",")
        |> Enum.map(fn token ->
          case Integer.parse(token) do
            {index, ""} when index >= 1 and index <= length(question.options) ->
              Enum.at(question.options, index - 1)

            _ ->
              token
          end
        end)
        |> Enum.join("; ")

      true ->
        answer
    end
  end

  defp convert_choice_to_text(_question_id, answer), do: answer

  defp map_correct_value(map, key) do
    Map.get(map, key) || Map.get(map, Atom.to_string(key))
  end
end
