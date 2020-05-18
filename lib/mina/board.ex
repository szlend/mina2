defmodule Mina.Board do
  @moduledoc """
  Provides basic minesweeper game logic
  """

  alias __MODULE__

  defstruct [:seed, :difficulty]

  @type t :: %Board{seed: String.t(), difficulty: non_neg_integer()}
  @type position :: {integer, integer}
  @type tile :: :mine | {:proximity, 0..8}

  @doc """
  Builds a new board for a given `seed` and `difficulty`
  """
  @spec build(String.t(), non_neg_integer()) :: t
  def build(seed, difficulty) when difficulty >= 0 and difficulty <= 100 do
    %Board{seed: seed, difficulty: difficulty}
  end

  @doc """
  Check whether a mine is present on the `board` at a given `position`
  """
  @spec mine_at?(t, position) :: boolean
  def mine_at?(board, position) do
    :erlang.phash2({board.seed, position}, 100) < board.difficulty
  end

  @doc """
  Returns the type of tile on the `board` at a given `position`.
  A tile can be either a `:mine` or a `{:proximity, rank}`
  """
  @spec tile_at(t, position) :: tile
  def tile_at(board, position) do
    if mine_at?(board, position) do
      :mine
    else
      {:proximity, proximate_mines(board, position)}
    end
  end

  @spec proximate_mines(t, position) :: non_neg_integer
  defp proximate_mines(board, position) do
    position
    |> adjacent_positions()
    |> Enum.count(fn position -> mine_at?(board, position) end)
  end

  @spec adjacent_positions(position) :: [position]
  defp adjacent_positions({x, y} = _position) do
    [
      {x - 1, y + 1},
      {x + 0, y + 1},
      {x + 1, y + 1},
      {x - 1, y + 0},
      {x + 1, y + 0},
      {x - 1, y - 1},
      {x + 0, y - 1},
      {x + 1, y - 1}
    ]
  end
end
