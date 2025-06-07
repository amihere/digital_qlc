defmodule QlcDigital.Repo.Migrations.CreateQuestions do
  use Ecto.Migration

  def change do
    create table(:questions) do
      add(:content, :text, null: false)
      add(:number, :integer, null: false)

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:questions, [:number]))
  end
end
