defmodule Mina.Board.Reveal do
  @moduledoc false

  alias Mina.Board
  import Mina.Board.Bounds, only: [in_bounds?: 2]

  @spec reveal(Board.t(), Board.position(), Board.reveals()) :: Board.reveals()
  def reveal(board, position, bounds \\ nil, prev_reveals \\ %{}, new_reveals \\ %{})

  # stop revealing when a tile is out of bounds
  def reveal(_, position, bounds, _, new_reveals) when not in_bounds?(bounds, position) do
    new_reveals
  end

  # stop revealing when a tile has already been revealed in this reveal
  def reveal(_, position, _, _, new_reveals) when is_map_key(new_reveals, position) do
    new_reveals
  end

  # stop revealing when a tile has already been revealed in previous reveals
  def reveal(_, position, _, prev_reveals, new_reveals) when is_map_key(prev_reveals, position) do
    new_reveals
  end

  def reveal(board, position, bounds, prev_reveals, new_reveals) do
    tile = Board.tile_at(board, position)
    new_reveals = Map.put(new_reveals, position, tile)

    # if the tile is empty, reveal adjacent tiles
    if tile == {:proximity, 0} do
      position
      |> Board.adjacent_positions()
      |> Enum.reduce(new_reveals, fn position, new_reveals ->
        reveal(board, position, bounds, prev_reveals, new_reveals)
      end)
    else
      new_reveals
    end
  end
end
