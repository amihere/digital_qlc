defmodule QlcDigital.Signup do
  @moduledoc """
  Signup module to allow AirtableClient to store this
  """

  @derive Jason.Encoder

  defstruct [:name, :phone_number, :email, :age, :notes]

  def new(attrs \\ %{}) do
    struct(__MODULE__, attrs)
  end

  def to_airtable_fields(%__MODULE__{} = signup) do
    %{
      name: signup.name,
      email: signup.email,
      age: signup.age,
      phone_number: signup.phone_number,
      notes: signup.notes
    }
    |> Enum.filter(fn {_key, value} -> value != nil end)
    |> Enum.into(%{})
  end

  def from_airtable_record(record) do
    fields = record.fields

    %__MODULE__{
      name: fields[:name],
      email: fields[:email],
      age: fields[:age],
      phone_number: fields[:phone_number],
      notes: fields[:notes]
    }
  end
end
