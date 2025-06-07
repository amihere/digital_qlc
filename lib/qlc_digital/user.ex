defmodule QlcDigital.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:phone, :string)

    belongs_to(:question, QlcDigital.Question, foreign_key: :questions_id)

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:phone, :questions_id])
    |> validate_required([:phone])
    |> unique_constraint(:phone)
    |> foreign_key_constraint(:questions_id)
  end
end
