defmodule MinaStorage.Repo.Migrations.CreatePartitionTable do
  use Ecto.Migration

  def change do
    create table("partitions", primary_key: false) do
      add :world_id, :text, primary_key: true
      add :x, :text, primary_key: true
      add :y, :text, primary_key: true
      add :reveals, :bytea, null: false
      timestamps()
    end
  end
end
