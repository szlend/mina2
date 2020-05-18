defmodule Mina.Board.Reveal do
  @moduledoc false

  alias Mina.Board
  import Mina.Board.Bounds, only: [in_bounds?: 2]

  @spec reveal(Board.t(), Board.position(), Board.reveals()) :: Board.reveals()
  def reveal(board, position, bounds \\ nil, reveals \\ %{})

  # stop revealing when a tile has already been revealed
  def reveal(_board, position, _bounds, reveals) when is_map_key(reveals, position) do
    reveals
  end

  # stop revealing when a tile is out of bounds
  def reveal(_board, position, bounds, reveals) when not in_bounds?(bounds, position) do
    reveals
  end

  def reveal(board, position, bounds, reveals) do
    tile = Board.tile_at(board, position)
    reveals = Map.put(reveals, position, tile)

    # if the tile is empty, reveal adjacent tiles
    if tile == {:proximity, 0} do
      position
      |> Board.adjacent_positions()
      |> Enum.reduce(reveals, fn position, reveals ->
        reveal(board, position, bounds, reveals)
      end)
    else
      reveals
    end
  end
end
