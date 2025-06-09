defmodule QlcDigital.Redis do
  @moduledoc """
  Redis client for Upstash integration
  """
  @redis_config Application.compile_env(:qlc_digital, :redis, [])
  @url @redis_config[:url]
  @token @redis_config[:token]
  @namespace @redis_config[:namespace] <> "."

  # REST API approach (recommended for serverless environments)
  def rest_command(command) do
    headers = [
      {"Authorization", "Bearer #{@token}"},
      {"Content-Type", "application/json"}
    ]

    body = Jason.encode!(command)

    case HTTPoison.post("#{@url}/", body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode!(response_body) do
          %{"result" => value} -> {:ok, value}
          other -> {:ok, other}
        end

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Convenience functions
  def get(key) do
    rest_command(["GET", @namespace <> key])
  end

  def set(key, value, opts \\ []) do
    cmd = ["SET", @namespace <> key, value] ++ build_set_options(opts)
    rest_command(cmd)
  end

  def del(key) do
    rest_command(["DEL", @namespace <> key])
  end

  def exists(key) do
    rest_command(["EXISTS", @namespace <> key])
  end

  def expire(key, seconds) do
    rest_command(["EXPIRE", @namespace <> key, seconds])
  end

  def incr(key) do
    rest_command(["INCR", @namespace <> key])
  end

  def decr(key) do
    rest_command(["DECR", @namespace <> key])
  end

  # Hash operations
  def hget(key, field) do
    rest_command(["HGET", @namespace <> key, field])
  end

  def hset(key, field, value) do
    rest_command(["HSET", @namespace <> key, field, value])
  end

  def hgetall(key) do
    rest_command(["HGETALL", @namespace <> key])
  end

  def hgetall_as_map(key) do
    case hgetall(key) do
      {:ok, fields} when is_list(fields) ->
        map =
          fields |> Enum.chunk_every(2) |> Enum.into(%{}, fn [field, value] -> {field, value} end)

        {:ok, map}

      {:ok, nil} ->
        {:ok, %{}}

      error ->
        error
    end
  end

  def hgetall_as_struct!(key, struct_name) do
    case hgetall_as_struct(key, struct_name) do
      {:ok, struct} ->
        struct

      {:error, reason} ->
        raise "Failed to cast to struct: #{reason}"
    end
  end

  def hgetall_as_struct(key, struct_name) do
    case hgetall_as_map(key) do
      {:ok, map} ->
        # Convert string keys to atoms if needed
        try do
          {:ok, struct(struct_name, map)}
        rescue
          ArgumentError ->
            {:error, :invalid_struct_keys}

          KeyError ->
            {:error, :missing_struct_fields}
        end

      error ->
        error
    end
  end

  def hmset(key, field_values) when is_map(field_values) do
    args = Enum.flat_map(field_values, fn {field, value} -> [field, value] end)
    rest_command(["HMSET", @namespace <> key] ++ args)
  end

  def hmset(key, field_values) when is_list(field_values) do
    args = Enum.flat_map(field_values, fn {field, value} -> [field, value] end)
    rest_command(["HMSET", @namespace <> key] ++ args)
  end

  # List operations
  def lpush(key, value) do
    rest_command(["LPUSH", @namespace <> key, value])
  end

  def rpop(key) do
    rest_command(["RPOP", @namespace <> key])
  end

  # Set operations
  def sadd(key, member) do
    rest_command(["SADD", @namespace <> key, member])
  end

  def smembers(key) do
    rest_command(["SMEMBERS", @namespace <> key])
  end

  # JSON operations (if using RedisJSON)
  def json_set(key, path, value) do
    json_value = Jason.encode!(value)
    rest_command(["JSON.SET", @namespace <> key, path, json_value])
  end

  def json_get(key, path \\ "$") do
    case rest_command(["JSON.GET", @namespace <> key, path]) do
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
