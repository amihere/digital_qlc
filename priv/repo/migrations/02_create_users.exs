defmodule QlcDigital.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:phone, :string, null: false)
      add(:questions_id, references(:questions, on_delete: :nilify_all))

      timestamps(type: :utc_datetime)
    end

    create(unique_index(:users, [:phone]))
    create(index(:users, [:questions_id]))
  end
end
