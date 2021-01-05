defmodule Mina do
  @moduledoc """
  Mina multiplayer minesweeper domain logic.
  """

  alias Mina.{Partition, World}

  @doc """
  Reveals tiles across partitions on the `world` starting at `position`. You can limit
  the `max_depth` to prevent infinite recursion. Returns a map of reveals.
  """
  @spec reveal_tile(World.t(), World.position(), pos_integer | :infinity) :: World.reveals()
  def reveal_tile(world, position, max_depth \\ :infinity) do
    depth = if max_depth == :infinity, do: -1, else: max_depth
    do_reveal_tile(world, Partition.position(world, position), [position], depth)
  end

  defp do_reveal_tile(_world, _partition_position, _positions, 0), do: %{}

  defp do_reveal_tile(world, partition_position, positions, depth) do
    {:ok, server} = ensure_partition_at(world, partition_position)
    {reveals, border_positions} = Partition.Server.reveal(server, positions)

    Enum.reduce(border_positions, reveals, fn {partition_position, positions}, reveals ->
      Map.merge(reveals, do_reveal_tile(world, partition_position, positions, depth - 1))
    end)
  end

  @doc """
  Attempts to flag a tile on the `world` at `position`. Returns `{:ok, new_reveals}` if
  successful, otherwise `{:error, reason}`.
  """
  @spec flag_tile(World.t(), World.position()) :: {:ok, World.reveals()} | {:error, any}
  def flag_tile(world, position) do
    {:ok, server} = ensure_partition_at(world, Partition.position(world, position))
    Partition.Server.flag(server, position)
  end

  @doc """
  Return the id of a partition on the `world` at tile `position`.
  """
  @spec partition_id_at(World.t(), World.position()) :: Partition.id()
  def partition_id_at(world, position) do
    Partition.id_at(world, position)
  end

  @doc """
  Loads the partition data on the `world` at partition `position`. In case the partition is
  already running, the loading is skipped, returning `{:ok, :skip}` instead.
  """
  @spec load_partition_at(World.t(), World.position()) ::
          {:ok, Partition.t() | :skip} | {:error, any}
  def load_partition_at(world, position) do
    server_opts = partition_server_opts()

    case Partition.Supervisor.start_partition(Partition.Supervisor, world, position, server_opts) do
      {:ok, _pid} -> {:ok, :skip}
      {:error, {:already_started, pid}} -> {:ok, Partition.Server.load(pid)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Subscribe to a `topic` scoped to a partition on the `world` at `position`.
  """
  @spec subscribe_partition_at(World.t(), World.position(), String.t()) :: :ok | {:error, any}
  def subscribe_partition_at(world, position, topic) do
    world
    |> Partition.build_id(position)
    |> Partition.subscribe(topic)
  end

  @doc """
  Unsubscribe from a `topic` scoped to a partition on the `world` at `position`.
  """
  @spec unsubscribe_partition_at(World.t(), World.position(), String.t()) :: :ok
  def unsubscribe_partition_at(world, position, topic) do
    world
    |> Partition.build_id(position)
    |> Partition.unsubscribe(topic)
  end

  defp ensure_partition_at(world, position) do
    server_opts = partition_server_opts()
    Partition.Supervisor.ensure_partition(Partition.Supervisor, world, position, server_opts)
  end

  defp partition_server_opts do
    config = Application.get_env(:mina, :partition, [])
    Keyword.merge([persistent: true, timeout: 10_000], config)
  end
end
