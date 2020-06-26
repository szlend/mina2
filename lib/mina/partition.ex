defmodule Mina.Partition do
  @moduledoc """
  Provides functions for working with world Partitions.
  """

  alias __MODULE__
  alias Mina.World

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
  Returns the position of the partition containing the `position` on the `world`.
  """
  @spec position(World.t(), World.position()) :: World.position()
  def position(%{partition_size: size} = _world, {x, y} = _position) do
    {x - Integer.mod(x, size), y - Integer.mod(y, size)}
  end

  @doc """
  Return the id of a partition on the `world` at `position`.
  """
  @spec id_at(World.t(), World.position()) :: id
  def id_at(%{partition_size: size} = world, {x, y} = position)
      when rem(x, size) == 0 and rem(y, size) == 0 do
    {World.id(world), position}
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
  Encode the `partition` with the given `serializer` implementing `Mina.Partition.Serializer`.
  """
  @spec encode(atom, t) :: {:ok, term} | {:error, term}
  def encode(serializer, partition) do
    serializer.encode(partition)
  end

  @doc """
  Decode `data` into `partition` with the given `serializer` implementing `Mina.Partition.Serializer`.
  """
  @spec decode(atom, t, term) :: {:ok, term} | {:error, term}
  def decode(serializer, partition, data) do
    serializer.decode(partition, data)
  end

  # The bounds of the partition, including the border
  defp extended_bounds(%{world: %{partition_size: size}, position: {x, y}} = _partition) do
    {{x - 1, y - 1}, {x + size, y + size}}
  end
end
