defmodule Mina.Board.Debug do
  @moduledoc """
  Debugging utilities for `Mina.Board`
  """

  alias Mina.Board

  @doc """
  Returns a grid of formatted tiles on the `board` with a given `radius`, centered around `position`
  """
  @spec dump(Board.t(), Board.position(), pos_integer) :: [[integer]]
  def dump(board, {center_x, center_y} = _position, radius) do
    for y <- (center_y + radius)..(center_y - radius) do
      for x <- (center_x - radius)..(center_x + radius) do
        case Board.tile_at(board, {x, y}) do
          :mine -> "x"
          {:proximity, 0} -> "."
          {:proximity, n} -> "#{n}"
        end
      end
    end
  end
end
