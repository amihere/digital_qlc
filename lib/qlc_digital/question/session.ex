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

  defp format_text(text, answers) do
    name = Map.get(answers, "start") || Map.get(answers, :start, "friend")

    text
    |> String.replace(". ", ".\n\n ")
    |> String.replace("? ", "?\n\n ")
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
      "Name: #{Map.get(answers, "start", "N/A")}",
      "Age: #{Map.get(answers, "age", "N/A")}",
      "Location: #{Map.get(answers, "location", "N/A")}"
    ]

    # (summary_parts ++ additional_info)

    summary_parts
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
