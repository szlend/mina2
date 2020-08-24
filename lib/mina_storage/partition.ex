defmodule MinaStorage.Partition do
  use Ecto.Schema

  @primary_key false

  schema "partitions" do
    field :world_id, :string, primary_key: true
    field :x, :string, primary_key: true
    field :y, :string, primary_key: true
    field :reveals, :binary
    timestamps()
  end
end
