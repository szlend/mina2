defmodule Mina.Partition do
  @moduledoc """
  Provides functions for working with world Partitions.
  """

  alias __MODULE__
  alias Mina.{PubSub, World}

  @type t :: %Partition{world: World.t(), position: World.position(), reveals: World.reveals()}
  @type id :: {World.id(), World.position()}

  defstruct [:world, :position, :reveals]

  @doc """
  Build a new partition on the `world` at `position`. The position coordinates
  have to be a multiple of the world partition size.
  """
  @spec build(World.t(), World.position()) :: t
  def build(%{partition_size: size} = world, {x, y} = position)
      when rem(x, size) == 0 and rem(y, size) == 0 do
    %Partition{world: world, position: position, reveals: %{}}
  end

  @doc """
  Build the partition id on the `world` at partition `position`.
  """
  @spec build_id(World.t(), World.position()) :: id
  def build_id(%{partition_size: size} = world, {x, y} = position)
      when rem(x, size) == 0 and rem(y, size) == 0 do
    {World.id(world), position}
  end

  @doc """
  Returns the position of the partition containing the `position` on the `world`.
  """
  @spec position(World.t(), World.position()) :: World.position()
  def position(%{partition_size: size} = _world, {x, y} = _position) do
    {x - Integer.mod(x, size), y - Integer.mod(y, size)}
  end

  @doc """
  Return the id of a partition on the `world` at tile `position`.
  """
  @spec id_at(World.t(), World.position()) :: id
  def id_at(world, position) do
    {World.id(world), position(world, position)}
  end

  @doc """
  Return the id of the `partition`.
  """
  @spec id(t) :: id
  def id(partition) do
    {World.id(partition.world), partition.position}
  end

  @doc """
  Reveals tiles on a `partition`, starting from `position`. Returns a tuple containing the new
  `partition`, a map of new `reveals` and positions on bordering partitions that need to be
  revealed further.
  """
  @spec reveal(t, World.position()) :: {t, World.reveals(), %{id => [World.position()]}}
  def reveal(%{world: world, reveals: reveals} = partition, position) do
    {internal_reveals, border_reveals} =
      world
      # reveal with bounds that include the neighbouring border
      |> World.reveal(position, reveals: reveals, bounds: extended_bounds(partition))
      # group the reveals by partition position
      |> Enum.group_by(fn {position, _} -> position(world, position) end)
      # cast each partition's reveals into a map
      |> Enum.map(fn {position, reveals} -> {position, Map.new(reveals)} end)
      # split internal reveals and border reveals
      |> Enum.split_with(fn {position, _} -> position == partition.position end)

    reveals = Map.new(internal_reveals)[partition.position] || %{}
    border_positions = Map.new(border_reveals, fn {id, reveals} -> {id, Map.keys(reveals)} end)
    partition = %{partition | reveals: Map.merge(partition.reveals, reveals)}

    {partition, reveals, border_positions}
  end

  @doc """
  Attempts to flag a tile on a `partition` at `position`. If the tile contains a flag, it returns
  `{:ok, {partition, new_reveals}}` with the updated partition, otherwise `{:error, :incorrect_flag}`.
  If the tile has already been revealed, it returns `{:error, :already_revealed}`.
  """
  @spec flag(t, World.position()) :: {:ok, {t, World.reveals()}} | {:error, :already_revealed}
  def flag(%{world: world, reveals: reveals} = partition, position) do
    with {:ok, reveals} <- World.flag(world, position, reveals: reveals) do
      partition = %{partition | reveals: Map.merge(partition.reveals, reveals)}
      {:ok, {partition, reveals}}
    end
  end

  @doc """
  Subscribe to a `topic` scoped to a `partition_id`.
  """
  @spec subscribe(id, String.t()) :: :ok | {:error, {:already_registered, pid}}
  def subscribe(partition_id, topic) do
    Phoenix.PubSub.subscribe(PubSub, pubsub_topic(partition_id, topic))
  end

  @doc """
  Unsubscribe from a `topic` scoped to a `partition_id`.
  """
  @spec unsubscribe(id, String.t()) :: :ok
  def unsubscribe(partition_id, topic) do
    Phoenix.PubSub.unsubscribe(PubSub, pubsub_topic(partition_id, topic))
  end

  @doc """
  Broadcast a `message` to a `topic` scoped to a `partition_id`.
  """
  @spec broadcast!(id, String.t(), any) :: :ok
  def broadcast!(partition_id, topic, message) do
    Phoenix.PubSub.broadcast!(PubSub, pubsub_topic(partition_id, topic), message)
  end

  @doc """
  Save the `partition` reveals to the database.
  """
  @spec save(t) :: :ok | {:error, any}
  def save(%{world: world, position: {x, y}} = partition) do
    with {:ok, encoded_reveals} <- Partition.TileSerializer.encode(partition),
         compressed_reveals = :erlang.term_to_binary(encoded_reveals, [:compressed]),
         {:ok, _} <- MinaStorage.set_partition(World.key(world), x, y, compressed_reveals) do
      :ok
    end
  end

  @doc """
  Load the `partition` reveals from the database.
  """
  @spec load(t) :: {:ok, t} | {:error, any}
  def load(%{world: world, position: {x, y}} = partition) do
    case MinaStorage.get_partition(World.key(world), x, y) do
      %{reveals: compressed_reveals} ->
        encoded_reveals = :erlang.binary_to_term(compressed_reveals)
        Partition.TileSerializer.decode(partition, encoded_reveals)

      nil ->
        {:error, :not_found}
    end
  end

  # The Phoenix PubSub topic name
  defp pubsub_topic({{seed, difficulty, partition_size}, {x, y}}, topic) do
    "partition:#{seed}-#{difficulty}-#{partition_size}:#{x},#{y}:#{topic}"
  end

  # The bounds of the partition, including the border
  defp extended_bounds(%{world: %{partition_size: size}, position: {x, y}} = _partition) do
    {{x - 1, y - 1}, {x + size, y + size}}
  end
end
