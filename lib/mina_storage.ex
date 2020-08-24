defmodule MinaStorage do
  @moduledoc """
  Functions for working with Mina database storage.
  """

  import Ecto.Query
  alias MinaStorage.{Partition, Repo}

  @doc """
  Get the partition with `world_id` at `x` and `y` coordinates from the database.
  """
  @spec get_partition(String.t(), integer, integer) :: Partition.t() | nil
  def get_partition(world_id, x, y) do
    query =
      from p in Partition,
        where: p.world_id == ^world_id,
        where: p.x == ^to_string(x) and p.y == ^to_string(y)

    Repo.one(query)
  end

  @doc """
  Set the `reveals` for the partition with `world_id` at `x` and `y` coordinates in the database.
  """
  @spec set_partition(String.t(), integer, integer, binary) ::
          {:ok, Partition.t()} | {:error, any}
  def set_partition(world_id, x, y, reveals) do
    partition = %Partition{world_id: world_id, x: to_string(x), y: to_string(y), reveals: reveals}

    Repo.insert(partition,
      on_conflict: :replace_all,
      conflict_target: [:world_id, :x, :y],
      returning: false
    )
  end
end
