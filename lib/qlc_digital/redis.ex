defmodule QlcDigital.Redis do
  @moduledoc """
  Redis client for Upstash integration
  """
  require Logger

  @redis_config Application.compile_env(:qlc_digital, :redis, [])
  @url @redis_config[:url]
  @token @redis_config[:token]

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

      {:ok, %HTTPoison.Response{status_code: 400, body: response_body}} ->
        Logger.error("Failed redis: #{response_body}")
        {:error, "failed"}

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
          atom_map =
            Map.new(map, fn {k, v} ->
              atom_key = if is_binary(k), do: String.to_existing_atom(k), else: k
              {atom_key, v}
            end)

          {:ok, struct(struct_name, atom_map)}
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
    rest_command(["HMSET", key] ++ args)
    expire(key, 3600)
  end

  def hmset(key, field_values) when is_list(field_values) do
    args = Enum.flat_map(field_values, fn {field, value} -> [field, value] end)
    rest_command(["HMSET", key] ++ args)
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
