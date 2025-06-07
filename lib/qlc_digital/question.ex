defmodule QlcDigital.Question do
  use Ecto.Schema
  import Ecto.Changeset

  schema "questions" do
    field(:content, :string)
    field(:number, :integer)

    has_many(:users, WhatsappBot.User)

    timestamps(type: :utc_datetime)
  end

  def changeset(question, attrs) do
    question
    |> cast(attrs, [:content, :number])
    |> validate_required([:content, :number])
    |> unique_constraint(:number)
  end
end
