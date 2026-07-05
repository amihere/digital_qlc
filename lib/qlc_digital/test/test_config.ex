defmodule QlcDigital.Test.TestConfig do
  @moduledoc """
  Configuration module for test environment.
  Provides mock implementations and test-specific settings.
  """

  def get_test_children do
    [
      QlcDigital.Question.ConversationManager,
      {QlcDigital.Question.QuestionConfig, [file_path: "new_questions.md"]},
      {QlcDigital.Test.MockWhatsappClient, [config: get_test_whatsapp_config()]},
      {QlcDigital.Test.MockRedis, {"redis://localhost:6379", [name: :redix]}},
      {Plug.Cowboy,
       scheme: :http,
       plug: QlcDigital.Router,
       options: [port: get_test_port(), ip: {127, 0, 0, 1}]}
    ]
  end

  def get_test_whatsapp_config do
    %{
      token: "test_token_12345",
      phone_id: "test_phone_id_67890",
      verify_token: "test_verify_token_abcde",
      webhook_url: "http://localhost:#{get_test_port()}/webhook"
    }
  end

  def get_test_port do
    Application.get_env(:qlc_digital, :test_port, 4001)
  end

  def get_test_redis_config do
    # In test, we don't use Redis - the mock conversation manager handles storage
    %{url: nil}
  end

  # Helper to determine if we're in test mode
  def test_mode? do
    Mix.env() == :test
  end

  # Alias the mock modules to their real counterparts for seamless testing
  def conversation_manager_module do
    if test_mode?() do
      QlcDigital.Test.MockConversationManager
    else
      QlcDigital.Question.ConversationManager
    end
  end

  def whatsapp_client_module do
    if test_mode?() do
      QlcDigital.Test.MockWhatsappClient
    else
      QlcDigital.WhatsappClient
    end
  end

  def question_config_module do
    if test_mode?() do
      QlcDigital.Test.MockQuestionConfig
    else
      QlcDigital.Question.QuestionConfig
    end
  end
end
