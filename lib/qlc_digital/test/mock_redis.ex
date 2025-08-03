defmodule QlcDigital.Test.MockRedis do
  @moduledoc """
  In-memory Redis client for testing.
  Implements the same interface as Redix but stores data in memory.
  """

  use GenServer

  def start_link({_redis_url, opts}) do
    name = Keyword.get(opts, :name, :redix)
    GenServer.start_link(__MODULE__, %{}, name: name)
  end

  def init(_) do
    {:ok, %{data: %{}, sets: %{}}}
  end

  # Redix.command/2 interface
  def command(server, ["SET", key, value]) do
    GenServer.call(server, {:set, key, value})
  end

  def command(server, ["GET", key]) do
    GenServer.call(server, {:get, key})
  end

  def command(server, ["DEL", key]) do
    GenServer.call(server, {:del, key})
  end

  def command(server, ["SADD", set_key, member]) do
    GenServer.call(server, {:sadd, set_key, member})
  end

  def command(server, ["SREM", set_key, member]) do
    GenServer.call(server, {:srem, set_key, member})
  end

  def command(server, ["SMEMBERS", set_key]) do
    GenServer.call(server, {:smembers, set_key})
  end

  # Handle unknown commands
  def command(_server, command) do
    {:error, "Unknown command: #{inspect(command)}"}
  end

  # Server callbacks
  def handle_call({:set, key, value}, _from, state) do
    new_data = Map.put(state.data, key, value)
    {:reply, {:ok, "OK"}, %{state | data: new_data}}
  end

  def handle_call({:get, key}, _from, state) do
    case Map.get(state.data, key) do
      nil -> {:reply, {:ok, nil}, state}
      value -> {:reply, {:ok, value}, state}
    end
  end

  def handle_call({:del, key}, _from, state) do
    new_data = Map.delete(state.data, key)
    count = if Map.has_key?(state.data, key), do: 1, else: 0
    {:reply, {:ok, count}, %{state | data: new_data}}
  end

  def handle_call({:sadd, set_key, member}, _from, state) do
    current_set = Map.get(state.sets, set_key, MapSet.new())
    new_set = MapSet.put(current_set, member)
    new_sets = Map.put(state.sets, set_key, new_set)
    added = if MapSet.member?(current_set, member), do: 0, else: 1
    {:reply, {:ok, added}, %{state | sets: new_sets}}
  end

  def handle_call({:srem, set_key, member}, _from, state) do
    current_set = Map.get(state.sets, set_key, MapSet.new())
    new_set = MapSet.delete(current_set, member)
    new_sets = Map.put(state.sets, set_key, new_set)
    removed = if MapSet.member?(current_set, member), do: 1, else: 0
    {:reply, {:ok, removed}, %{state | sets: new_sets}}
  end

  def handle_call({:smembers, set_key}, _from, state) do
    current_set = Map.get(state.sets, set_key, MapSet.new())
    members = MapSet.to_list(current_set)
    {:reply, {:ok, members}, state}
  end

  def handle_call(:clear_all, _from, _state) do
    {:reply, :ok, %{data: %{}, sets: %{}}}
  end

  def handle_call(:get_all, _from, state) do
    {:reply, %{data: state.data, sets: state.sets}, state}
  end

  # Handle cast for Redix pipelining compatibility
  def handle_cast({:pipeline, commands, caller, _timeout}, state) do
    {results, new_state} = Enum.reduce(commands, {[], state}, fn cmd, {acc_results, acc_state} ->
      {result, updated_state} = execute_command(cmd, acc_state)
      {[result | acc_results], updated_state}
    end)
    
    final_results = Enum.reverse(results)
    send(elem(caller, 0), {elem(caller, 1), {:ok, final_results}})
    {:noreply, new_state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  # Helper function to execute command and return result + new state
  defp execute_command(["SET", key, value], state) do
    new_data = Map.put(state.data, key, value)
    {"OK", %{state | data: new_data}}
  end

  defp execute_command(["GET", key], state) do
    result = Map.get(state.data, key)
    {result, state}
  end

  defp execute_command(["DEL", key], state) do
    new_data = Map.delete(state.data, key)
    count = if Map.has_key?(state.data, key), do: 1, else: 0
    {count, %{state | data: new_data}}
  end

  defp execute_command(["SADD", set_key, member], state) do
    current_set = Map.get(state.sets, set_key, MapSet.new())
    new_set = MapSet.put(current_set, member)
    new_sets = Map.put(state.sets, set_key, new_set)
    added = if MapSet.member?(current_set, member), do: 0, else: 1
    {added, %{state | sets: new_sets}}
  end

  defp execute_command(["SREM", set_key, member], state) do
    current_set = Map.get(state.sets, set_key, MapSet.new())
    new_set = MapSet.delete(current_set, member)
    new_sets = Map.put(state.sets, set_key, new_set)
    removed = if MapSet.member?(current_set, member), do: 1, else: 0
    {removed, %{state | sets: new_sets}}
  end

  defp execute_command(["SMEMBERS", set_key], state) do
    current_set = Map.get(state.sets, set_key, MapSet.new())
    members = MapSet.to_list(current_set)
    {members, state}
  end

  defp execute_command(command, state) do
    {{:error, "Unknown command: #{inspect(command)}"}, state}
  end

  # Test helper functions
  def clear_all_data(server \\ :redix) do
    GenServer.call(server, :clear_all)
  end

  def get_all_data(server \\ :redix) do
    GenServer.call(server, :get_all)
  end
end