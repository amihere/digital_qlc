defmodule QlcDigital.Test.MockWhatsappClient do
  @moduledoc """
  Mock WhatsApp client for testing - captures messages instead of sending them.
  """

  use Agent
  require Logger

  @agent_name __MODULE__

  def start_link(opts) do
    config = Keyword.get(opts, :config, %{})

    initial_state = %{
      token: config[:token],
      phone_id: config[:phone_id],
      verify_token: config[:verify_token],
      webhook_url: config[:webhook_url],
      sent_messages: []
    }

    Agent.start_link(fn -> initial_state end, name: @agent_name)
  end

  def get_config do
    Agent.get(@agent_name, & &1)
  end

  def get_verify_token do
    Agent.get(@agent_name, fn state -> state.verify_token end)
  end

  def send_message(to, message) do
    timestamp = DateTime.utc_now()

    Agent.update(@agent_name, fn state ->
      sent_message = %{
        to: to,
        message: message,
        timestamp: timestamp,
        status: :sent
      }

      %{state | sent_messages: [sent_message | state.sent_messages]}
    end)

    Logger.info("Mock: Message sent to #{to}: #{message}")
    :ok
  end

  def update_config(new_config) do
    Agent.update(@agent_name, fn state ->
      Map.merge(state, new_config)
    end)
  end

  # Test helper functions
  def get_sent_messages do
    Agent.get(@agent_name, fn state -> Enum.reverse(state.sent_messages) end)
  end

  def clear_sent_messages do
    Agent.update(@agent_name, fn state ->
      %{state | sent_messages: []}
    end)
  end

  def get_last_message do
    Agent.get(@agent_name, fn state ->
      case state.sent_messages do
        [last | _] -> last
        [] -> nil
      end
    end)
  end

  def message_count do
    Agent.get(@agent_name, fn state -> length(state.sent_messages) end)
  end
end
