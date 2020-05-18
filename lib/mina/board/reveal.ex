defmodule Mina.Board.Reveal do
  @moduledoc false

  alias Mina.Board

  @spec reveal(Board.t(), Board.position(), Board.reveals()) :: Board.reveals()
  def reveal(board, position, reveals \\ %{})

  # stop revealing when a tile has already been revealed
  def reveal(_board, position, reveals) when is_map_key(reveals, position), do: reveals

  def reveal(board, position, reveals) do
    tile = Board.tile_at(board, position)
    reveals = Map.put(reveals, position, tile)

    # if the tile is empty, reveal adjacent tiles
    if tile == {:proximity, 0} do
      position
      |> Board.adjacent_positions()
      |> Enum.reduce(reveals, fn position, reveals ->
        reveal(board, position, reveals)
      end)
    else
      reveals
    end
  end
end
