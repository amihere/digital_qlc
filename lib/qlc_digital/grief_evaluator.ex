defmodule QlcDigital.GriefEvaluator do
  @moduledoc """
  Pure routing for the pregnancy-loss grief indicators (PL-4/PL-6).

  Route rules (per protocol, escalating on doubt):
    * C - complicated/prolonged: 5+ indicators, or the functional-impairment
      indicator together with guilt or avoidance
    * A - mild/integrated: at most 1 indicator AND the loss was a while ago
    * B - acute/significant: everything else (the escalation default,
      including missing timing)

  Indicator indices follow the pl_grief_indicators option order:
  3 = guilt, 4 = avoidance, 5 = functional impairment, 8 = "None of these"
  (ignored when counting).
  """

  @guilt 3
  @avoidance 4
  @functional_impairment 5
  @none_option 8

  @timing_a_while_ago "3"

  def evaluate(indicators, timing) do
    indices =
      indicators
      |> parse_indices()
      |> MapSet.new()
      |> MapSet.delete(@none_option)

    count = MapSet.size(indices)

    complicated_combo =
      MapSet.member?(indices, @functional_impairment) and
        (MapSet.member?(indices, @guilt) or MapSet.member?(indices, @avoidance))

    route =
      cond do
        count >= 5 or complicated_combo -> "C"
        count <= 1 and timing == @timing_a_while_ago -> "A"
        true -> "B"
      end

    %{route: route, complicated: route == "C"}
  end

  defp parse_indices(indicators) when is_binary(indicators) do
    indicators
    |> String.split(",", trim: true)
    |> Enum.flat_map(fn token ->
      case Integer.parse(String.trim(token)) do
        {index, ""} -> [index]
        _ -> []
      end
    end)
  end

  defp parse_indices(_indicators), do: []
end
