defmodule Mina.Partition do
  @moduledoc """
  Provides functions for working with board Partitions.
  """

  alias __MODULE__
  alias Mina.Board
  alias Mina.Partition.Spec

  @type t :: %Partition{spec: Spec.t(), position: Board.position(), reveals: Board.reveals()}
  @type id :: {Spec.id(), Board.position()}

  defstruct [:spec, :position, :reveals]

  @doc """
  Build a new partition from a partition `spec` at `position`. The position coordinates
  have to be a multiple of the partition spec size.
  """
  @spec build(Spec.t(), Board.position()) :: t
  def build(%{size: size} = spec, {x, y} = position)
      when rem(x, size) == 0 and rem(y, size) == 0 do
    %Partition{spec: spec, position: position, reveals: %{}}
  end

  @doc """
  Return the id of the `partition`.
  """
  @spec id(t) :: id
  def id(partition) do
    {Spec.id(partition.spec), partition.position}
  end

  @doc """
  Return the id of the partition with a partition `spec` at `position`.
  """
  @spec id_for_spec_position(Spec.t(), Board.position()) :: id
  def id_for_spec_position(spec, position) do
    {Spec.id(spec), position}
  end

  @doc """
  Return the id of a partition at `position` in the same board space as the specified `partition`.
  """
  @spec partition_at(t, Board.position()) :: id
  def partition_at(partition, {x, y} = _position) do
    position = {x - Integer.mod(x, partition.spec.size), y - Integer.mod(y, partition.spec.size)}
    {Spec.id(partition.spec), position}
  end

  @doc """
  Reveals tiles on a `partition`, starting from `position`. Returns a tuple containing the new
  `partition`, a map of new `reveals` and positions on bordering partitions that need to be
  revealed further.
  """
  @spec reveal(t, Board.position()) :: {t, Board.reveals(), %{id => [Board.position()]}}
  def reveal(partition, position) do
    id = id(partition)

    {internal_reveals, border_reveals} =
      partition.spec.board
      # reveal with bounds that include the neighbouring border
      |> Board.reveal(position, reveals: partition.reveals, bounds: extended_bounds(partition))
      # group the reveals by partition id
      |> Enum.group_by(fn {position, _} -> partition_at(partition, position) end)
      # cast each partition's reveals into a map
      |> Enum.map(fn {partition_id, reveals} -> {partition_id, Map.new(reveals)} end)
      # split internal reveals and border reveals
      |> Enum.split_with(fn {partition_id, _} -> partition_id == id end)

    reveals = Map.new(internal_reveals)[id] || %{}
    border_positions = Map.new(border_reveals, fn {id, reveals} -> {id, Map.keys(reveals)} end)
    partition = %{partition | reveals: Map.merge(partition.reveals, reveals)}

    {partition, reveals, border_positions}
  end

  # The bounds of the partition, including the border
  defp extended_bounds(%{spec: %{size: size}, position: {x, y}} = _partition) do
    {{x - 1, y - 1}, {x + size + 1, y + size + 1}}
  end
end
