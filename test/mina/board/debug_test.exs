defmodule Mina.Board.DebugTest do
  use Mina.DataCase

  alias Mina.Board
  alias Mina.Board.Debug

  describe "dump/3" do
    setup do
      [board: %Board{seed: "test", difficulty: 40}]
    end

    test "returns a grid of tiles", %{board: board} do
      assert Debug.dump(board, {0, 0}, 1) == [
               ["x", "x", "3"],
               ["6", "4", "x"],
               ["4", "x", "2"]
             ]
    end
  end
end
