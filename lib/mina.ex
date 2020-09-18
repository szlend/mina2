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
  Partition `reveals` according to partition size defined by `world`.
  """
  @spec partition_reveals(World.t(), World.reveals()) :: %{World.position() => World.reveals()}
  def partition_reveals(world, reveals) do
    reveals
    |> Enum.group_by(fn {position, _tile} -> Partition.position(world, position) end)
    |> Map.new(fn {position, reveals} -> {position, Map.new(reveals)} end)
  end

  @doc """
  Ensure the partition server on the `world` at `position` is running, returning its pid or error.
  """
  @spec ensure_partition_at(World.t(), World.position()) :: {:ok, pid} | {:error, any}
  def ensure_partition_at(world, position) do
    config = Application.get_env(:mina, :partition, [])
    server_opts = Keyword.merge([persistent: true, timeout: 10_000], config)
    Partition.Supervisor.ensure_partition(Partition.Supervisor, world, position, server_opts)
  end

  @doc """
  Save the `partition` reveals to the database.
  """
  @spec save_partition(Partition.t()) :: :ok | {:error, any}
  def save_partition(%{world: world, position: {x, y}} = partition) do
    with {:ok, encoded_reveals} <- Partition.TileSerializer.encode(partition),
         compressed_reveals = :erlang.term_to_binary(encoded_reveals, [:compressed]),
         {:ok, _} <- MinaStorage.set_partition(World.key(world), x, y, compressed_reveals) do
      :ok
    end
  end

  @doc """
  Load the `partition` reveals from the database.
  """
  @spec load_partition(Partition.t()) :: {:ok, Mina.Partition.t()} | {:error, any}
  def load_partition(%{world: world, position: {x, y}} = partition) do
    case MinaStorage.get_partition(World.key(world), x, y) do
      %{reveals: compressed_reveals} ->
        encoded_reveals = :erlang.binary_to_term(compressed_reveals)
        Partition.TileSerializer.decode(partition, encoded_reveals)

      nil ->
        {:error, :not_found}
    end
  end

  @doc """
  Loads the partition server on the `world` at `position` and encodes its data with the `serializer`.
  """
  @spec encode_partition_at(World.t(), World.position(), atom) :: {:ok, any} | {:error, any}
  def encode_partition_at(world, position, serializer) do
    with {:ok, server} <- ensure_partition_at(world, position) do
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
