defmodule Solidjs.Repo.Migrations.CreateDataTable do
  use Ecto.Migration

  def change do
    create table(:data) do
      add :price, :string
      add :time, :string
      add :type, :string

      timestamps()
    end
  end
end
