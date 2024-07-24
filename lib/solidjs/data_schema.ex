defmodule Solidjs.Data do
  use Ecto.Schema
  import Ecto.Changeset

  schema "data" do
    field :price, :string
    field :time, :string
    field :type, :string

    # timestamps()
  end

  @doc false
  def changeset(data, attrs) do
    data
    |> cast(attrs, [:price, :time, :type])
    |> validate_required([:price, :time, :type])
  end
end
