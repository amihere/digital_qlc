defmodule QlcDigital.Question.ConversationManager do
  @moduledoc """
  Manages conversation state persistence in Redis.
  """

  use GenServer
  alias QlcDigital.Question.Conversation

  @namespace Application.compile_env(:qlc_digital, :redis, [])[:namespace]

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, %{}}
  end

  # Client API
  def save_conversation(%Conversation{} = conversation) do
    GenServer.call(__MODULE__, {:save, conversation})
  end

  def load_conversation(session_id) do
    GenServer.call(__MODULE__, {:load, session_id})
  end

  def list_sessions do
    GenServer.call(__MODULE__, :list_sessions)
  end

  def delete_conversation(session_id) do
    GenServer.call(__MODULE__, {:delete, session_id})
  end

  # Server callbacks
  def handle_call({:save, conversation}, _from, state) do
    key = "#{@namespace}::conversation:#{conversation.session_id}"
    data = Jason.encode!(conversation)

    case Redix.command(:redix, ["SET", key, data]) do
      {:ok, "OK"} ->
        # Also add to sessions set for listing
        Redix.command(:redix, [
          "SADD",
          "#{@namespace}::conversations:sessions",
          conversation.session_id
        ])

        {:reply, :ok, state}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:load, session_id}, _from, state) do
    key = "#{@namespace}::conversation:#{session_id}"

    case Redix.command(:redix, ["GET", key]) do
      {:ok, nil} ->
        {:reply, {:error, :not_found}, state}

      {:ok, data} ->
        case Jason.decode(data, keys: :atoms) do
          {:ok, conversation_data} ->
            conversation = struct(Conversation, conversation_data)
            {:reply, {:ok, conversation}, state}

          {:error, reason} ->
            {:reply, {:error, reason}, state}
        end

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  def handle_call(:list_sessions, _from, state) do
    case Redix.command(:redix, ["SMEMBERS", "#{@namespace}::conversations:sessions"]) do
      {:ok, sessions} -> {:reply, {:ok, sessions}, state}
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  def handle_call({:delete, session_id}, _from, state) do
    key = "#{@namespace}conversation:#{session_id}"

    with {:ok, _} <- Redix.command(:redix, ["DEL", key]),
         {:ok, _} <-
           Redix.command(:redix, ["SREM", "#{@namespace}::conversations:sessions", session_id]) do
      {:reply, :ok, state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end
end
