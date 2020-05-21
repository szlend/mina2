defmodule Mina.Partition.Spec do
  @moduledoc """
  Provides functions for working with partition specs. The specs are used as
  instructions for creating new partitions.
  """

  alias __MODULE__
  alias Mina.Board

  @type t :: %Spec{board: Board.t(), size: size}
  @type id :: {Board.seed(), Board.difficulty(), size}
  @type size :: pos_integer

  defstruct [:board, :size]

  @doc """
  Builds a new partition spec for a `board` and partition `size`.
  """
  @spec build(Board.t(), size) :: t
  def build(board, size) do
    %Spec{board: board, size: size}
  end

  @doc """
  Returns the id of a partition `spec`.
  """
  @spec id(t) :: id
  def id(spec) do
    {spec.board.seed, spec.board.difficulty, spec.size}
  end
end
