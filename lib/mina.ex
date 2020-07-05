defmodule Mina do
  @moduledoc """
  Mina multiplayer minesweeper domain logic.
  """

  alias Mina.{Partition, World}

  @type depth :: pos_integer | :infinity

  @doc """
  Reveals tiles across partitions on the `world` starting at `position`. You can limit
  the `max_depth` to prevent infinite recursion. Returns a map of reveals.
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
  Reveals tiles across partitions on the `world`, starting at `position`. You can limit
  the `max_depth` to prevent infinite recursion. Returns a map of partitioned reveals.
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
    partition_reveals = %{partition_position => reveals}

    # Recursively reveal new tiles and merge reveals belonging to the same partition
    Enum.reduce(
      border_positions,
      partition_reveals,
      fn {partition_position, positions}, partition_reveals ->
        Map.merge(
          partition_reveals,
          do_reveal_tile_partitioned(world, partition_position, positions, depth - 1),
          fn _, p1, p2 -> Map.merge(p1, p2) end
        )
      end
    )
  end

  @doc """
  Loads the partition server on the `world` at `position` and encodes its data with the `serializer`.
  """
  @spec encode_partition_at(World.t(), World.position(), atom) :: {:ok, any} | {:error, any}
  def encode_partition_at(world, position, serializer) do
    with {:ok, server} <- Partition.Supervisor.ensure_partition(world, position) do
      Partition.Server.encode(server, serializer)
    end
  end

  @doc """
  Subscribe to a `topic` scoped to a partition on the `world` at `position`.
  """
  @spec subscribe_partition_at(World.t(), World.position(), String.t()) :: :ok | {:error, any}
  def subscribe_partition_at(world, position, topic) do
    world
    |> Partition.id_at(position)
    |> Partition.subscribe(topic)
  end

  @doc """
  Unsubscribe from a `topic` scoped to a partition on the `world` at `position`.
  """
  @spec unsubscribe_partition_at(World.t(), World.position(), String.t()) :: :ok
  def unsubscribe_partition_at(world, position, topic) do
    world
    |> Partition.id_at(position)
    |> Partition.unsubscribe(topic)
  end

  @doc """
  Broadcast a `message` to a `topic` scoped to a partition on the `world` at `position`.
  """
  @spec broadcast_partition_at!(World.t(), World.position(), String.t(), any) :: :ok
  def broadcast_partition_at!(world, position, topic, message) do
    world
    |> Partition.id_at(position)
    |> Partition.broadcast!(topic, message)
  end
end
