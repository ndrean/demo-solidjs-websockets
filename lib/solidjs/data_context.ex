defmodule Solidjs.DataContext do
  import Ecto.Query, warn: false
  alias Solidjs.Data
  alias Solidjs.Repo

  def save_data(attrs \\ %{}) do
    %Data{}
    |> Data.changeset(attrs)
    |> Repo.insert()
  end

  def all_data do
    Repo.all(Data)
  end
end
