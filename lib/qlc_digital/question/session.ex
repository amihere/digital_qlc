defmodule QlcDigital.Question.Session do
  @moduledoc """
  Handles a single question-answer session.
  """

  alias QlcDigital.Question.{Conversation, ConversationManager, QuestionConfig}

  # override the current user's flow
  defp reroute(session_id, stage) do
    case ConversationManager.load_conversation(session_id) do
      {:ok, conversation} ->
        updated_conversation = Map.put(conversation, "current_question_id", stage)

        :ok = ConversationManager.save_conversation(updated_conversation)
        {:ok, :resumed, updated_conversation}

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

      String.match?(answer, ~r/^eli return$/) ->
        {:ok, conversation} = ConversationManager.load_conversation(session_id)

        key =
          Map.get(conversation, "answers")
          |> Map.keys()
          |> Enum.sort()
          |> Enum.drop(-1)
          |> List.last()

        reroute(session_id, key)

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
