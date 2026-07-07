defmodule QlcDigital.AirtableClient do
  @moduledoc """
  API client for Airtable
  """
  require Logger

  @airtable_config Application.compile_env(:qlc_digital, :airtable, [])
  @base_url @airtable_config[:url]
  @token @airtable_config[:token]

  defstruct [:table_name]

  def new(table_name) do
    %__MODULE__{
      table_name: table_name
    }
  end

  # Error responses are not always JSON (proxies, outages); never raise here
  defp decode_error_body(response_body) do
    case Jason.decode(response_body) do
      {:ok, decoded} -> decoded
      {:error, _} -> response_body
    end
  end

  # Create a new record
  def create_record(%__MODULE__{} = client, fields) do
    url = build_url(client)
    headers = build_headers()

    body =
      %{
        "fields" => normalize_fields(fields)
      }
      |> Jason.encode!()

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        {:ok, Jason.decode!(response_body)}

      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} ->
        {:error, {status_code, decode_error_body(response_body)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def upsert_record(%__MODULE__{} = client, phone_number, fields) do
    case find_by_phone_number(client, phone_number) do
      {:ok, record} when not is_nil(record) ->
        record_id = record["id"]
        update_record(client, record_id, fields)

      _ ->
        create_record(client, fields)
    end
  end

  def find_by_phone_number(%__MODULE__{} = client, phone_number) do
    headers = build_headers()

    filter_formula = "fldKhmDyobYdgIlY7=#{phone_number}"
    url = "#{build_url(client)}?filterByFormula=#{URI.encode(filter_formula)}"

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode!(response_body) do
          %{"records" => []} ->
            {:ok, nil}

          %{"records" => [record | _]} ->
            {:ok, record}

          {:error, decode_error} ->
            Logger.error(decode_error)
            {:error, "Could not decode json"}
        end

      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} ->
        {:error, {status_code, decode_error_body(response_body)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Get a record by ID
  def get_record(%__MODULE__{} = client, record_id) do
    url = build_url(client, record_id)
    headers = build_headers()

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        record = Jason.decode!(response_body)
        {:ok, denormalize_record(record)}

      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} ->
        {:error, {status_code, decode_error_body(response_body)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Update a record
  def update_record(%__MODULE__{} = client, record_id, fields) do
    url = build_url(client, record_id)
    headers = build_headers()

    body =
      %{
        "fields" => normalize_fields(fields)
      }
      |> Jason.encode!()

    case HTTPoison.patch(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        record = Jason.decode!(response_body)
        {:ok, denormalize_record(record)}

      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} ->
        {:error, {status_code, decode_error_body(response_body)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # List records with optional filtering
  def list_records(%__MODULE__{} = client, opts \\ []) do
    url = build_url(client)
    headers = build_headers()

    query_params = build_query_params(opts)
    url_with_params = if query_params != "", do: url <> "?" <> query_params, else: url

    case HTTPoison.get(url_with_params, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        response = Jason.decode!(response_body)
        records = Enum.map(response["records"], &denormalize_record/1)
        {:ok, %{records: records, offset: response["offset"]}}

      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} ->
        {:error, {status_code, decode_error_body(response_body)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Delete a record
  def delete_record(%__MODULE__{} = client, record_id) do
    url = build_url(client, record_id)
    headers = build_headers()

    case HTTPoison.delete(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        {:ok, Jason.decode!(response_body)}

      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} ->
        {:error, {status_code, decode_error_body(response_body)}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Private helper functions

  defp build_url(%__MODULE__{table_name: table_name}) do
    "#{@base_url}/#{URI.encode(table_name)}"
  end

  defp build_url(%__MODULE__{} = client, record_id) do
    build_url(client) <> "/#{record_id}"
  end

  defp build_headers() do
    [
      {"Authorization", "Bearer #{@token}"},
      {"Content-Type", "application/json"}
    ]
  end

  defp build_query_params(opts) do
    opts
    |> Enum.filter(fn {_key, value} -> value != nil end)
    |> Enum.map(fn {key, value} -> "#{key}=#{URI.encode(to_string(value))}" end)
    |> Enum.join("&")
  end

  # Normalize fields for Airtable API (convert Elixir-friendly keys to Airtable field names)
  defp normalize_fields(fields) do
    Enum.reduce(fields, %{}, fn {key, value}, acc ->
      field_name = normalize_field_name(key)
      normalized_value = normalize_field_value(value)
      Map.put(acc, field_name, normalized_value)
    end)
  end

  # Convert snake_case to "Title Case" for Airtable field names
  defp normalize_field_name(key) when is_atom(key) do
    key |> Atom.to_string() |> normalize_field_name()
  end

  defp normalize_field_name(key) when is_binary(key) do
    key
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  # Handle special field value types
  defp normalize_field_value(value) when is_map(value) and not is_struct(value) do
    # Handle phone number objects and other structured data
    case value do
      %{number: number} -> number
      %{phone: phone} -> phone
      %{email: email} -> email
      _ -> value
    end
  end

  defp normalize_field_value(value), do: value

  # Denormalize record data coming back from Airtable
  defp denormalize_record(record) do
    fields = record["fields"] || %{}

    denormalized_fields =
      fields
      |> Enum.reduce(%{}, fn {key, value}, acc ->
        snake_key = key |> String.downcase() |> String.replace(" ", "_") |> String.to_atom()
        Map.put(acc, snake_key, value)
      end)

    %{
      id: record["id"],
      fields: denormalized_fields,
      created_time: record["createdTime"]
    }
  end
end
