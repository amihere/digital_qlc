defmodule QlcDigital.Question.Session do
  @moduledoc """
  Handles a single question-answer session.
  """

  alias QlcDigital.Question.{Conversation, ConversationManager, QuestionConfig}

  def start_session(session_id) do
    case ConversationManager.load_conversation(session_id) do
      {:ok, conversation} ->
        {:ok, :resumed, conversation}

      {:error, :not_found} ->
        conversation = Conversation.new(session_id)
        :ok = ConversationManager.save_conversation(conversation)
        {:ok, :new, conversation}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_current_question(%Conversation{} = conversation) do
    question = QuestionConfig.get_question(conversation.current_question_id)

    if question do
      # Interpolate any variables in the question text
      interpolated_text = Conversation.interpolate_text(question.text, conversation.answers)
      %{question | text: interpolated_text}
    else
      nil
    end
  end

  def display_question(%{type: :choice, options: options} = question) do
    choices =
      options
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {option, index} -> "\n#{index} #{option}" end)

    "#{question.text}\n\n#{choices}\n\nChoose (1 - #{length(options)})"
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

          # Save to Redis
          :ok = ConversationManager.save_conversation(final_conversation)

          {:ok, final_conversation}

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:error, :invalid_question}
    end
  end

  def get_summary(%Conversation{} = conversation) do
    answers = conversation.answers

    summary_parts = [
      "Name: #{Map.get(answers, "name", "N/A")}",
      "Age: #{Map.get(answers, "age", "N/A")}",
      "Location: #{Map.get(answers, "location", "N/A")}",
      "Phone: #{Map.get(answers, "phone", "N/A")}"
    ]

    # Add conditional summary based on path taken
    additional_info =
      cond do
        Map.has_key?(answers, "tech_experience") ->
          [
            "Interest: Technology",
            "Experience: #{answers["tech_experience"]} years",
            "Languages: #{Map.get(answers, "programming_languages", "None specified")}"
          ]

        Map.has_key?(answers, "art_type") ->
          [
            "Interest: Arts",
            "Art Type: #{answers["art_type"]}",
            "Experience: #{Map.get(answers, "art_years", "Not specified")}"
          ]

        true ->
          ["Path: #{inspect(Map.keys(answers))}"]
      end

    (summary_parts ++ additional_info)
    |> Enum.join("\n")
  end

  # Private functions
  defp validate_answer(%{type: :text}, answer) when is_binary(answer) and answer != "" do
    {:ok, String.trim(answer)}
  end

  defp validate_answer(%{type: :number}, answer) when is_binary(answer) do
    case Integer.parse(answer) do
      {number, ""} -> {:ok, to_string(number)}
      _ -> {:error, "Please enter a valid number"}
    end
  end

  defp validate_answer(%{type: :choice, options: options}, answer) when is_binary(answer) do
    if answer in options do
      {:ok, answer}
    else
      {:error, "Please choose from: #{Enum.join(options, ", ")}"}
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
