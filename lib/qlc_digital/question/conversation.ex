defmodule QlcDigital.Question.Conversation do
  @moduledoc """
  Represents a conversation state with answers and current question.
  """

  @derive Jason.Encoder

  defstruct [
    :session_id,
    :current_question_id,
    :answers,
    :started_at,
    :updated_at,
    :completed,
    :question_history
  ]

  @type t :: %__MODULE__{
          session_id: String.t(),
          current_question_id: String.t(),
          answers: map(),
          started_at: DateTime.t(),
          updated_at: DateTime.t(),
          completed: boolean(),
          question_history: list(String.t())
        }

  def new(session_id, current \\ "start") do
    now = DateTime.utc_now()

    %__MODULE__{
      session_id: session_id,
      current_question_id: current,
      answers: %{},
      started_at: now,
      updated_at: now,
      completed: false,
      question_history: [current]
    }
  end

  def add_answer(%__MODULE__{} = conversation, question_id, answer) do
    %{
      conversation
      | answers: Map.put(conversation.answers, question_id, answer),
        updated_at: DateTime.utc_now()
    }
  end

  def set_current_question(%__MODULE__{} = conversation, question_id) do
    completed = question_id == nil || question_id == "completed" || question_id == "final_summary"

    updated_history =
      if question_id && question_id not in conversation.question_history do
        conversation.question_history ++ [question_id]
      else
        conversation.question_history
      end

    %{
      conversation
      | current_question_id: question_id,
        updated_at: DateTime.utc_now(),
        completed: completed,
        question_history: updated_history
    }
  end

  def get_previous_question(%__MODULE__{question_history: history} = _conversation) do
    case Enum.reverse(history) do
      [_current | [previous | _rest]] -> previous
      _ -> nil
    end
  end

  def interpolate_text(text, answers) do
    Regex.replace(~r/\{(\w+)\}/, text, fn _, key ->
      Map.get(answers, key, "{#{key}}")
    end)
  end
end
