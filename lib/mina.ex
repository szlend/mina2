defmodule Mina do
  @moduledoc """
  Mina multiplayer minesweeper domain logic.
  """

  alias Mina.{Partition, World}

  @type depth :: pos_integer | :infinity

  @doc """
  Reveals tiles across partitions on the `world` at `position`. You can limit the `max_depth`
  to prevent infinite recursion with very easy difficulties. Returns a map of reveals.
  """
  @spec reveal_tile(World.t(), World.position(), depth) :: World.reveals()
  def reveal_tile(world, position, max_depth \\ :infinity) do
    depth = if max_depth == :infinity, do: -1, else: max_depth
    do_reveal_tile(world, Partition.position(world, position), [position], depth)
  end

  defp do_reveal_tile(_world, _partition_position, _positions, 0), do: %{}

  defp do_reveal_tile(world, partition_position, positions, depth) do
    {:ok, server} = Partition.Supervisor.ensure_partition(world, partition_position)
    {reveals, border_positions} = Partition.Server.reveal(server, positions)

    Enum.reduce(border_positions, reveals, fn {partition_position, positions}, reveals ->
      Map.merge(reveals, do_reveal_tile(world, partition_position, positions, depth - 1))
    end)
  end

  @doc """
  Reveals tiles across partitions on the `world` at `position`. You can limit the `max_depth`
  to prevent infinite recursion with very easy difficulties. Returns a map of partitioned reveals.
  """
  @spec reveal_tile_partitioned(World.t(), World.position(), depth) :: World.partitioned_reveals()
  def reveal_tile_partitioned(world, position, max_depth \\ :infinity) do
    depth = if max_depth == :infinity, do: -1, else: max_depth
    do_reveal_tile_partitioned(world, Partition.position(world, position), [position], depth)
  end

  defp do_reveal_tile_partitioned(_world, _partition_position, _positions, 0), do: %{}

  defp do_reveal_tile_partitioned(world, partition_position, positions, depth) do
    {:ok, server} = Partition.Supervisor.ensure_partition(world, partition_position)
    {reveals, border_positions} = Partition.Server.reveal(server, positions)
    partitions = %{partition_position => reveals}

    Enum.reduce(border_positions, partitions, fn {partition_position, positions}, partitions ->
      Map.merge(
        partitions,
        do_reveal_tile_partitioned(world, partition_position, positions, depth - 1),
        fn _k, a, b -> Map.merge(a, b) end
      )
    end)
  end

  @doc """
  Loads the partition server on the `world` at `position` and encodes it with the `serializer`.
  """
  @spec encode_partition(World.t(), World.position(), atom) :: {:ok, any} | {:error, any}
  def encode_partition(world, position, serializer) do
    with {:ok, server} <- Mina.Partition.Supervisor.ensure_partition(world, position) do
      Partition.Server.encode(server, serializer)
    end
  end
end
