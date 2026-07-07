defmodule QlcDigital.Question.Checkpoints do
  @moduledoc """
  Computed routing and side effects that the markdown question flow cannot
  express: score-based rerouting, threshold evaluation, and Airtable writes
  tied to specific points in the conversation.

  `apply/3` runs two kinds of rules:

    * after-answer rules, keyed on the question that was just answered
      (e.g. score the EPDS once epds_q10 is in)
    * resolve-next rules, keyed on the computed next question id
      (e.g. replace epds_completion with its score-resolved variant),
      iterated until the next id stops changing

  Rules return side effects as functions of the final conversation; the
  Session fires them fire-and-forget so a slow Airtable call never blocks
  the reply to the user.
  """

  alias QlcDigital.Question.Conversation
  alias QlcDigital.{BpEvaluator, EpdsScorer, GriefEvaluator, ResponseSaver, SignupHandler}

  # resolve-next rules can chain (diversions); guard against a rule cycle
  @max_resolutions 5

  @doc """
  Runs checkpoint rules for one answered question.

  Returns `{next_question_id, conversation, side_effects}` where side_effects
  is a list of 1-arity functions to be run with the final conversation.
  """
  def apply(answered_question_id, next_question_id, %Conversation{} = conversation) do
    {conversation, effects} = after_answer(answered_question_id, conversation)
    resolve(next_question_id, conversation, effects, @max_resolutions)
  end

  @doc """
  Answer lookup that works with both string and atom keys (answers loaded
  from Redis have atom keys, freshly written ones have string keys).
  """
  def get_answer(%Conversation{answers: answers}, key) when is_binary(key) do
    answers = answers || %{}
    Map.get(answers, key) || Map.get(answers, String.to_atom(key))
  end

  defp resolve(next_id, conversation, effects, 0), do: {next_id, conversation, effects}

  defp resolve(next_id, conversation, effects, budget) do
    case resolve_next(next_id, conversation) do
      {^next_id, conversation, new_effects} ->
        {next_id, conversation, effects ++ new_effects}

      {other_id, conversation, new_effects} ->
        resolve(other_id, conversation, effects ++ new_effects, budget - 1)
    end
  end

  # -- after-answer rules ---------------------------------------------------

  # Score the EPDS as soon as q10 is answered so both the safety branch and
  # the completion branch carry the scores (the safety branch never reaches
  # epds_completion)
  defp after_answer("epds_q10", conversation) do
    score_data = EpdsScorer.calculate_epds_score(conversation)
    anxiety = EpdsScorer.calculate_anxiety_subscore(conversation)

    conversation =
      conversation
      |> Conversation.add_answer(
        "epds_score",
        "#{score_data.total_score}/#{score_data.max_score}"
      )
      |> Conversation.add_answer("epds_raw_score", "#{score_data.raw_total}")
      |> Conversation.add_answer("epds_anxiety_score", "#{anxiety.score}")

    # Any Q10 answer other than "Never" (option 4) is a safety flag that must
    # reach the nurse dashboard immediately - including "Hardly ever", which
    # continues the conversation instead of entering the safety protocol
    effects =
      if get_answer(conversation, "epds_q10") in ["1", "2", "3"] do
        [fn final -> ResponseSaver.save_flag_snapshot(final) end]
      else
        []
      end

    {conversation, effects}
  end

  # Both BP readings are in: evaluate and store the flag level. The markdown
  # Next is bp_normal (mildest); resolve_next upgrades from the stored flag.
  defp after_answer("bp_diastolic", conversation) do
    level =
      BpEvaluator.evaluate_reading(
        get_answer(conversation, "bp_systolic"),
        get_answer(conversation, "bp_diastolic")
      )

    flag =
      case level do
        :emergency -> "BP_EMERGENCY"
        :concern -> "BP_CONCERN"
        :normal -> "BP_NORMAL"
      end

    conversation = Conversation.add_answer(conversation, "bp_flag", flag)

    effects =
      if level in [:emergency, :concern] do
        [fn final -> ResponseSaver.save_flag_snapshot(final) end]
      else
        []
      end

    {conversation, effects}
  end

  # All five proxy symptom answers are in: count the yes responses
  defp after_answer("bp_proxy_q5", conversation) do
    proxy_answers = Enum.map(1..5, fn i -> get_answer(conversation, "bp_proxy_q#{i}") end)
    {count, level} = BpEvaluator.evaluate_proxy(proxy_answers)

    flag =
      case level do
        :emergency -> "BP_PROXY_EMERGENCY"
        :flag -> "BP_PROXY_MILD"
        :normal -> "BP_PROXY_NORMAL"
      end

    conversation =
      conversation
      |> Conversation.add_answer("bp_proxy_count", "#{count}")
      |> Conversation.add_answer("bp_flag", flag)

    effects =
      if level in [:emergency, :flag] do
        [fn final -> ResponseSaver.save_flag_snapshot(final) end]
      else
        []
      end

    {conversation, effects}
  end

  # The grief screen is complete: evaluate the A/B/C route (used by
  # resolve_next when the Never branch lands on pl_route_a) and alert the
  # care team immediately on any non-Never safety answer
  defp after_answer("pl_safety_screen", conversation) do
    grief =
      GriefEvaluator.evaluate(
        get_answer(conversation, "pl_grief_indicators"),
        get_answer(conversation, "pl_loss_timing")
      )

    conversation = Conversation.add_answer(conversation, "grief_route", grief.route)

    conversation =
      if grief.complicated do
        Conversation.add_answer(conversation, "complicated_grief", "true")
      else
        conversation
      end

    effects =
      if get_answer(conversation, "pl_safety_screen") in ["1", "2", "3"] do
        [fn final -> ResponseSaver.save_flag_snapshot(final) end]
      else
        []
      end

    {conversation, effects}
  end

  # Nurse-contact decisions in the pregnancy-loss pathway reach the
  # dashboard immediately (requested and declined both matter to the team)
  defp after_answer("pl_nurse_offer", conversation) do
    {conversation, [fn final -> ResponseSaver.save_flag_snapshot(final) end]}
  end

  defp after_answer("pl_route_b", conversation) do
    {conversation, [fn final -> ResponseSaver.save_flag_snapshot(final) end]}
  end

  defp after_answer("pl_route_c", conversation) do
    conversation =
      if get_answer(conversation, "pl_route_c") == "2" do
        Conversation.add_answer(conversation, "social_isolation", "true")
      else
        conversation
      end

    {conversation, [fn final -> ResponseSaver.save_flag_snapshot(final) end]}
  end

  defp after_answer(_question_id, conversation), do: {conversation, []}

  # -- resolve-next rules ---------------------------------------------------

  # Reaching parenthood_stage means intake is complete: upsert bio info
  defp resolve_next("parenthood_stage" = next_id, conversation) do
    {next_id, conversation, [fn final -> SignupHandler.upsert_bio_info(final) end]}
  end

  # Resolve the EPDS completion variant from the score at answer time, so
  # validation and routing run against the question the user actually sees.
  # A pregnancy-loss user who flagged a physical concern at PL-3 first
  # diverts through the proxy symptom questions (per PL-7 protocol note).
  defp resolve_next("epds_completion" = next_id, conversation) do
    if physical_concern_pending?(conversation) do
      {"bp_proxy_q1", conversation, []}
    else
      score_data = EpdsScorer.calculate_epds_score(conversation)
      {score_data.interpretation[:route] || next_id, conversation, []}
    end
  end

  # Checkout is the PL pathway's fall-through target; divert to the proxy
  # questions when a physical concern is still unscreened, and return to the
  # score-resolved completion options after the PL proxy tail when the EPDS
  # was completed
  defp resolve_next("checkout_point" = next_id, conversation) do
    epds_done = get_answer(conversation, "epds_q10") != nil
    proxy_done = get_answer(conversation, "bp_proxy_q1") != nil
    pl_physical = get_answer(conversation, "pl_physical_check") == "2"

    cond do
      physical_concern_pending?(conversation) -> {"bp_proxy_q1", conversation, []}
      pl_physical and proxy_done and epds_done -> {"epds_completion", conversation, []}
      true -> {next_id, conversation, []}
    end
  end

  # Upgrade the default BP outcome to the evaluated severity
  defp resolve_next("bp_normal" = next_id, conversation) do
    case get_answer(conversation, "bp_flag") do
      "BP_EMERGENCY" -> {"bp_emergency", conversation, []}
      "BP_CONCERN" -> {"bp_concern", conversation, []}
      _ -> {next_id, conversation, []}
    end
  end

  defp resolve_next("bp_proxy_normal" = next_id, conversation) do
    # Pregnancy-loss users get the short tail variants (no re-entry into the
    # nursing-mother emotion menu); emergencies escalate identically
    pl_context = get_answer(conversation, "pl_physical_check") == "2"

    case get_answer(conversation, "bp_flag") do
      "BP_PROXY_EMERGENCY" ->
        {"bp_proxy_emergency", conversation, []}

      "BP_PROXY_MILD" ->
        {if(pl_context, do: "bp_proxy_flag_pl", else: "bp_proxy_flag"), conversation, []}

      _ ->
        {if(pl_context, do: "bp_proxy_normal_pl", else: next_id), conversation, []}
    end
  end

  # Conversation is ending normally: save the complete response
  defp resolve_next("final_summary" = next_id, conversation) do
    {next_id, conversation, [fn final -> ResponseSaver.save_complete_response(final) end]}
  end

  # Grief route upgrade: the markdown Never-branch default is route A;
  # replace it with the evaluated route and alert the team on B/C
  defp resolve_next("pl_route_a" = next_id, conversation) do
    case get_answer(conversation, "grief_route") do
      "B" ->
        {"pl_route_b", conversation, [fn final -> ResponseSaver.save_flag_snapshot(final) end]}

      "C" ->
        {"pl_route_c", conversation, [fn final -> ResponseSaver.save_flag_snapshot(final) end]}

      _ ->
        {next_id, conversation, []}
    end
  end

  defp resolve_next(next_id, conversation), do: {next_id, conversation, []}

  defp physical_concern_pending?(conversation) do
    get_answer(conversation, "pl_physical_check") == "2" and
      get_answer(conversation, "bp_proxy_q1") == nil
  end
end
