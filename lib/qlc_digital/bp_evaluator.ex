defmodule QlcDigital.BpEvaluator do
  @moduledoc """
  Pure evaluation of the blood-pressure pathway inputs.

  Device readings (per protocol):
    * emergency: systolic >= 160 or diastolic >= 110
    * concern:   systolic 140-159 or diastolic 90-109
    * normal:    below both

  Proxy symptom screen (5 yes/no questions):
    * emergency: 2+ yes answers
    * flag:      exactly 1 yes
    * normal:    0 yes

  Unreadable or skipped readings evaluate to :concern - escalate on doubt
  without dispatching a possibly-healthy user to the emergency room.
  """

  @systolic_emergency 160
  @diastolic_emergency 110
  @systolic_concern 140
  @diastolic_concern 90

  def evaluate_reading(systolic, diastolic) do
    case {parse_reading(systolic), parse_reading(diastolic)} do
      {sys, dia} when is_integer(sys) and is_integer(dia) ->
        cond do
          sys >= @systolic_emergency or dia >= @diastolic_emergency -> :emergency
          sys >= @systolic_concern or dia >= @diastolic_concern -> :concern
          true -> :normal
        end

      _ ->
        :concern
    end
  end

  @doc """
  Takes the five stored proxy answers ("1" = yes, "2" = no, nil = unanswered)
  and returns `{yes_count, level}`.
  """
  def evaluate_proxy(answers) when is_list(answers) do
    count = Enum.count(answers, &(&1 == "1"))

    level =
      cond do
        count >= 2 -> :emergency
        count == 1 -> :flag
        true -> :normal
      end

    {count, level}
  end

  defp parse_reading(value) when is_binary(value) do
    case Integer.parse(value) do
      {number, ""} when number > 0 -> number
      _ -> nil
    end
  end

  defp parse_reading(_value), do: nil
end
