defmodule QlcDigital.Question.QuestionConfig do
  @moduledoc """
  Configuration for questions and their flow logic.
  Easy to modify and extend with new questions.
  Can load from hardcoded config or from markdown files.
  """

  use Agent

  # State to hold loaded questions
  @agent_name __MODULE__

  @default_questions %{}

  def start_link(_opts) do
    Agent.start_link(fn -> @default_questions end, name: @agent_name)
  end

  def load_from_file(file_path) do
    case File.read(file_path) do
      {:ok, content} ->
        case parse_markdown_questions(content) do
          {:ok, questions} ->
            Agent.update(@agent_name, fn _ -> questions end)
            {:ok, map_size(questions)}

          {:error, reason} ->
            {:error, reason}
        end

      {:error, reason} ->
        {:error, {:file_error, reason}}
    end
  end

  def get_question(question_id) do
    questions = Agent.get(@agent_name, & &1)
    Map.get(questions, question_id)
  end

  def get_all_questions do
    Agent.get(@agent_name, & &1)
  end

  def get_start_question do
    get_question("start")
  end

  def reload_default do
    Agent.update(@agent_name, fn _ -> @default_questions end)
    :ok
  end

  # Markdown parsing functions
  def parse_markdown_questions(content) do
    try do
      questions =
        content
        |> String.split("## ")
        # Remove anything before first ##
        |> Enum.drop(1)
        |> Enum.map(&parse_question_block/1)
        # Remove nils
        |> Enum.filter(& &1)
        |> Enum.into(%{}, fn q -> {q.id, q} end)

      # Validate that all next references exist
      case validate_question_references(questions) do
        :ok -> {:ok, questions}
        {:error, reason} -> {:error, reason}
      end
    rescue
      e -> {:error, {:parse_error, Exception.message(e)}}
    end
  end

  defp parse_question_block(block) do
    lines = String.split(block, "\n", trim: true)

    case lines do
      [id_line | rest] ->
        id = String.trim(id_line)
        parse_question_content(id, rest)

      _ ->
        nil
    end
  end

  defp parse_question_content(id, lines) do
    {question_text, remaining_lines} = extract_question_text(lines)

    if question_text do
      attributes = parse_attributes(remaining_lines)

      %{
        id: id,
        text: question_text,
        type: Map.get(attributes, :type, :text),
        options: Map.get(attributes, :options, []),
        next: parse_next_value(Map.get(attributes, :next))
      }
    else
      nil
    end
  end

  defp extract_question_text([]), do: {nil, []}

  defp extract_question_text([line | rest]) do
    line = String.trim(line)

    if String.starts_with?(line, "**Question:**") do
      question = String.trim_leading(line, "**Question:**") |> String.trim()
      {question, rest}
    else
      extract_question_text(rest)
    end
  end

  # Get all the extra values in the text
  defp parse_attributes(lines) do
    lines
    |> Enum.reduce(%{}, fn line, acc ->
      line = String.trim(line)

      cond do
        String.starts_with?(line, "**Type:**") ->
          type_str = String.trim_leading(line, "**Type:**") |> String.trim()
          Map.put(acc, :type, String.to_atom(type_str))

        String.starts_with?(line, "**Options:**") ->
          options_str = String.trim_leading(line, "**Options:**") |> String.trim()
          options = String.split(options_str, ",") |> Enum.map(&String.trim/1)
          Map.put(acc, :options, options)

        String.starts_with?(line, "**Next:**") ->
          next_str = String.trim_leading(line, "**Next:**") |> String.trim()
          Map.put(acc, :next, next_str)

        true ->
          acc
      end
    end)
  end

  defp parse_next_value(nil), do: nil
  defp parse_next_value("nil"), do: nil
  defp parse_next_value(""), do: nil

  defp parse_next_value(next_str) do
    # Check if it's a conditional next (contains conditions)
    if String.contains?(next_str, "if") or String.contains?(next_str, "case") do
      # Try to parse as Elixir code for conditional logic
      parse_conditional_next(next_str)
    else
      # Simple string reference
      next_str
    end
  end

  defp parse_conditional_next(condition_str) do
    # This is a simplified parser for common conditional patterns
    # In a real implementation, you might want to use Code.eval_string with proper security
    cond do
      String.contains?(condition_str, "age >= 18") ->
        fn answers ->
          age = String.to_integer(Map.get(answers, "age", "0"))
          if age >= 18, do: "interests_adult", else: "interests_youth"
        end

      String.contains?(condition_str, "interests_adult") ->
        fn answers ->
          case Map.get(answers, "interests_adult") do
            "Technology" -> "tech_experience"
            "Arts" -> "art_type"
            "Sports" -> "sport_type"
            "Business" -> "business_type"
            _ -> "summary"
          end
        end

      String.contains?(condition_str, "interests_youth") ->
        fn answers ->
          case Map.get(answers, "interests_youth") do
            "Video Games" -> "game_type"
            "Reading" -> "book_genre"
            "Sports" -> "sport_type"
            "Music" -> "music_instrument"
            _ -> "summary"
          end
        end

      true ->
        # Fallback to treating as simple string
        condition_str
    end
  end

  @doc """
  checks all the next links are valid
  """
  defp validate_question_references(questions) do
    question_ids = MapSet.new(Map.keys(questions))

    invalid_refs =
      questions
      |> Map.values()
      |> Enum.flat_map(fn q ->
        case q.next do
          nil ->
            []

          next when is_binary(next) ->
            if MapSet.member?(question_ids, next) do
              []
            else
              vals = String.split(" -> ")
              last = List.last(vals)

              [last | vals]
              |> Enum.filter(&String.contains?(&1, ","))
              |> Enum.map(&(String.split(&1, ", ") |> List.first()))
              |> Enum.filter(&MapSet.member?(question_ids, &1))
            end

          # Skip function validation
          _func ->
            []
        end
      end)

    if Enum.empty?(invalid_refs) do
      :ok
    else
      {:error, {:invalid_references, invalid_refs}}
    end
  end

  def export_to_markdown(file_path \\ "exported_questions.md") do
    questions = get_all_questions()

    content =
      [
        "# Question Configuration\n",
        "This file defines the questions and flow for the interactive question app.\n\n"
        | Enum.map(questions, &format_question_as_markdown/1)
      ]
      |> List.flatten()
      |> Enum.join("")

    File.write(file_path, content)
  end

  defp format_question_as_markdown({_id, question}) do
    [
      "## #{question.id}\n\n",
      "**Question:** #{question.text}\n\n",
      "**Type:** #{question.type}\n\n",
      format_options(question.options),
      format_next(question.next),
      "\n---\n\n"
    ]
  end

  defp format_options([]), do: ""

  defp format_options(options) do
    "**Options:** #{Enum.join(options, ", ")}\n\n"
  end

  defp format_next(nil), do: "**Next:** nil\n\n"
  defp format_next(next) when is_binary(next), do: "**Next:** #{next}\n\n"
  defp format_next(_func), do: "**Next:** [conditional function]\n\n"
end
