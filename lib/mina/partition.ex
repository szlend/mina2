defmodule Mina.Partition do
  @moduledoc """
  Provides functions for working with board Partitions
  """

  alias __MODULE__
  alias Mina.Board

  defstruct [:board, :size, :position, :reveals]

  @type t :: %Partition{
          board: Board.t(),
          size: pos_integer,
          position: Board.position(),
          reveals: Board.reveals()
        }
  @type id :: {String.t(), non_neg_integer, pos_integer, Board.position()}

  @doc """
  Build a new partition living in `board` space, at `position` and `size`.
  """
  @spec build(Board.t(), Board.position(), non_neg_integer) :: t
  def build(board, position, size) do
    %Partition{board: board, position: position, size: size, reveals: %{}}
  end

  @doc """
  Return the id of the `partition`.
  """
  @spec id(t) :: id
  def id(partition) do
    {partition.board.seed, partition.board.difficulty, partition.size, partition.position}
  end

  @doc """
  Return the id of a partition at `position` in the same board space as the specified `partition`.
  """
  @spec partition_at(t, Board.position()) :: id
  def partition_at(partition, {x, y} = _position) do
    position = {x - Integer.mod(x, partition.size), y - Integer.mod(y, partition.size)}
    {partition.board.seed, partition.board.difficulty, partition.size, position}
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
      partition.board
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
  defp extended_bounds(%{size: size, position: {x, y}} = _partition) do
    {{x - 1, y - 1}, {x + size + 1, y + size + 1}}
  end
end
