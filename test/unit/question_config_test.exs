defmodule QlcDigital.Unit.QuestionConfigTest do
  use ExUnit.Case

  alias QlcDigital.Question.QuestionConfig

  @valid_md """
  ## start

  **Question:** Hi! What is your name?
  **Type:** text
  **Next:** done

  ---

  ## done

  **Question:** Bye.
  **Type:** summary
  **Next:** nil
  """

  describe "parse_markdown_questions/1 reference validation" do
    test "accepts a config where all next references exist" do
      assert {:ok, questions} = QuestionConfig.parse_markdown_questions(@valid_md)
      assert map_size(questions) == 2
    end

    test "rejects a bare next reference to a missing question" do
      md = """
      ## start

      **Question:** Hi! What is your name?
      **Type:** text
      **Next:** missing_q
      """

      assert {:error, {:invalid_references, problems}} =
               QuestionConfig.parse_markdown_questions(md)

      assert Enum.any?(problems, &String.contains?(&1, "missing_q"))
    end

    test "rejects a case route target that does not exist" do
      md = """
      ## pick

      **Question:** Pick one.
      **Type:** choice
      **Options:** A, B
      **Next:** case pick: A -> good, B -> missing_q

      ---

      ## good

      **Question:** Bye.
      **Type:** summary
      **Next:** nil
      """

      assert {:error, {:invalid_references, problems}} =
               QuestionConfig.parse_markdown_questions(md)

      assert Enum.any?(problems, &String.contains?(&1, "missing_q"))
    end

    test "rejects a case question whose route count does not match its option count" do
      md = """
      ## pick

      **Question:** Pick one.
      **Type:** choice
      **Options:** A, B, C
      **Next:** case pick: A -> good, B -> good

      ---

      ## good

      **Question:** Bye.
      **Type:** summary
      **Next:** nil
      """

      assert {:error, {:invalid_references, problems}} =
               QuestionConfig.parse_markdown_questions(md)

      assert Enum.any?(problems, &String.contains?(&1, "pick"))
    end
  end
end
