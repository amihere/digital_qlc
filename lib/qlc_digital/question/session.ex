defmodule QlcDigital.Question.Session do
  @moduledoc """
  Handles a single question-answer session.
  """

  require Logger

  alias QlcDigital.Question.{Conversation, ConversationManager, QuestionConfig}
  alias QlcDigital.{SignupHandler, EpdsScorer, ResponseSaver}

  # override the current user's flow
  defp reroute(session_id, stage) do
    case ConversationManager.load_conversation(session_id) do
      {:ok, conversation} ->
        updated_conversation = Map.put(conversation, :current_question_id, stage)

        :ok = ConversationManager.save_conversation(updated_conversation)
        {:ok, :new, [initial: %Conversation{}, q: updated_conversation]}

      # rerouting was not possible
      _ ->
        _start_session(session_id)
    end
  end

  def start_session(session_id, answer) do
    answer = String.downcase(answer) |> String.trim()

    cond do
      String.match?(answer, ~r/^eli stop$/) ->
        reroute(session_id, "parenthood_stage")

      String.match?(answer, ~r/^eli restart$/) ->
        reroute(session_id, "start")

      String.match?(answer, ~r/^sos$/) ->
        reroute(session_id, "crisis_checkin")

      String.match?(answer, ~r/^eli return$/) ->
        {:ok, conversation} = ConversationManager.load_conversation(session_id)

        key =
          Map.get(conversation, "answers")
          |> Map.keys()
          |> List.last()

        reroute(session_id, key)

      String.match?(answer, ~r/^eli back$/) ->
        case ConversationManager.load_conversation(session_id) do
          {:ok, conversation} ->
            previous_question = Conversation.get_previous_question(conversation)

            if previous_question do
              reroute(session_id, previous_question)
            else
              reroute(session_id, "start")
            end

          _ ->
            _start_session(session_id)
        end

      true ->
        _start_session(session_id)
    end
  end

  defp _start_session(session_id) do
    case ConversationManager.load_conversation(session_id) do
      {:ok, conversation} ->
        {:ok, :resumed, conversation}

      {:error, :not_found} ->
        conversation = Conversation.new(session_id)
        welcome = Conversation.new(session_id, "welcome")
        :ok = ConversationManager.save_conversation(conversation)
        {:ok, :new, [initial: welcome, q: conversation]}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_current_question(%Conversation{} = conversation) do
    # Add EPDS score summary for epds_completion question
    question =
      if conversation.current_question_id == "epds_completion" do
        score_data = EpdsScorer.calculate_epds_score(conversation)

        Logger.debug(
          "Your EPDS assessment score: #{score_data.total_score}/#{score_data.max_score}. #{score_data.interpretation[:note]}"
        )

        qid = score_data.interpretation[:route]
        QuestionConfig.get_question(qid)
      else
        QuestionConfig.get_question(conversation.current_question_id)
      end

    if question do
      # Interpolate any variables in the question text
      interpolated_text = Conversation.interpolate_text(question.text, conversation.answers)
      %{question | text: interpolated_text}
    else
      nil
    end
  end

  defp format_text(text, answers) do
    name = Map.get(answers, "start") || Map.get(answers, :start, "friend")

    text
    |> String.replace(". ", ".\n\n")
    |> String.replace("? ", "?\n\n")
    |> String.replace("{name}", name)
  end

  def display_question(%{type: :number, text: text, options: []}, answers) do
    format_text(text, answers)
  end

  def display_question(%{type: :text, text: text, options: []}, answers) do
    format_text(text, answers)
  end

  def display_question(%{type: :choice, options: options} = question, answers) do
    choices =
      options
      |> Enum.with_index(1)
      |> Enum.map(fn {option, index} -> "\n#{index} #{option}" end)

    text = format_text(question.text, answers)
    "#{text}\n\n#{choices}\n\nChoose (1 - #{length(options)})"
  end

  def answer_question(%Conversation{} = conversation, answer) do
    current_question = QuestionConfig.get_question(conversation.current_question_id)

    if current_question do
      # Validate answer based on question type
      case validate_answer(current_question, answer) do
        {:ok, validated_answer} ->
          # Add answer to conversation
          updated_conversation =
            conversation
            |> Conversation.add_answer(current_question.id, validated_answer)

          # Determine next question
          next_question_id =
            determine_next_question(current_question, updated_conversation.answers)

          # Update current question
          final_conversation =
            Conversation.set_current_question(updated_conversation, next_question_id)

          # Upsert bio info to Airtable when reaching parenthood_stage
          if next_question_id == "parenthood_stage" do
            Task.start(fn -> SignupHandler.upsert_bio_info(final_conversation) end)
          end

          # Add EPDS score to conversation when reaching epds_completion
          final_conversation_with_score =
            if next_question_id == "epds_completion" do
              score_data = EpdsScorer.calculate_epds_score(final_conversation)

              Conversation.add_answer(
                final_conversation,
                "epds_score",
                "#{score_data.total_score}/#{score_data.max_score}"
              )
            else
              final_conversation
            end

          # Save complete response to Airtable when conversation ends
          if next_question_id == nil do
            Task.start(fn ->
              Logger.warning("saving details")
              ResponseSaver.save_complete_response(final_conversation_with_score)
            end)
          end

          # Save to Redis
          :ok = ConversationManager.save_conversation(final_conversation_with_score)

          {:ok, final_conversation_with_score}

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, :invalid_question}
    end
  end

  # Private functions
  defp validate_answer(%{type: :text}, answer) when is_binary(answer) and answer != "" do
    {:ok, String.trim(answer)}
  end

  defp validate_answer(%{type: :number}, answer) when is_binary(answer) do
    # TODO: remove skip to property
    if String.downcase(answer) == "skip" do
      {:ok, ""}
    else
      case Integer.parse(answer) do
        {number, ""} -> {:ok, to_string(number)}
        _ -> {:error, "Please enter a valid number"}
      end
    end
  end

  defp validate_answer(%{type: :choice, options: options}, answer) when is_binary(answer) do
    cond do
      answer in options -> {:ok, answer}
      answer in (1..Enum.count(options) |> Enum.map(&Integer.to_string(&1))) -> {:ok, answer}
      true -> {:error, "Please choose from: #{Enum.join(1..Enum.count(options), ", ")}"}
    end
  end

  defp validate_answer(%{type: :summary}, _answer) do
    {:ok, "completed"}
  end

  defp validate_answer(_, _) do
    {:error, "Invalid answer format"}
  end

  defp determine_next_question(%{next: next}, answers) when is_function(next) do
    next.(answers)
  end

  defp determine_next_question(%{next: next}, _answers) when is_binary(next) do
    next
  end

  defp determine_next_question(%{next: nil}, _answers) do
    nil
  end

  defp determine_next_question(_, _) do
    nil
  end
end
