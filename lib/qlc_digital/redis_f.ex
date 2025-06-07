defmodule QlcDigital.Redis do
  @moduledoc """
  Redis client for Upstash integration
  """

  # REST API approach (recommended for serverless environments)
  def rest_command(command) do
    url = Application.get_env(:qlc_digital, :redis)[:url]
    token = Application.get_env(:qlc_digital, :redis)[:token]

    headers = [
      {"Authorization", "Bearer #{token}"},
      {"Content-Type", "application/json"}
    ]

    body = Jason.encode!(command)

    case HTTPoison.post("#{url}/", body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        Jason.decode!(response_body)

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Convenience functions
  def get(key) do
    rest_command(["GET", key])
  end

  def set(key, value, opts \\ []) do
    cmd = ["SET", key, value] ++ build_set_options(opts)
    rest_command(cmd)
  end

  def del(key) do
    rest_command(["DEL", key])
  end

  def exists(key) do
    rest_command(["EXISTS", key])
  end

  def expire(key, seconds) do
    rest_command(["EXPIRE", key, seconds])
  end

  def incr(key) do
    rest_command(["INCR", key])
  end

  def decr(key) do
    rest_command(["DECR", key])
  end

  # Hash operations
  def hget(key, field) do
    rest_command(["HGET", key, field])
  end

  def hset(key, field, value) do
    rest_command(["HSET", key, field, value])
  end

  def hgetall(key) do
    rest_command(["HGETALL", key])
  end

  # List operations
  def lpush(key, value) do
    rest_command(["LPUSH", key, value])
  end

  def rpop(key) do
    rest_command(["RPOP", key])
  end

  # Set operations
  def sadd(key, member) do
    rest_command(["SADD", key, member])
  end

  def smembers(key) do
    rest_command(["SMEMBERS", key])
  end

  # JSON operations (if using RedisJSON)
  def json_set(key, path, value) do
    json_value = Jason.encode!(value)
    rest_command(["JSON.SET", key, path, json_value])
  end

  def json_get(key, path \\ "$") do
    case rest_command(["JSON.GET", key, path]) do
      {:ok, json_string} when is_binary(json_string) ->
        Jason.decode(json_string)

      other ->
        other
    end
  end

  # Helper functions
  defp build_set_options(opts) do
    Enum.flat_map(opts, fn
      {:ex, seconds} -> ["EX", to_string(seconds)]
      {:px, milliseconds} -> ["PX", to_string(milliseconds)]
      {:nx, true} -> ["NX"]
      {:xx, true} -> ["XX"]
      _ -> []
    end)
  end
end
