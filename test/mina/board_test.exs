defmodule Mina.BoardTest do
  use Mina.DataCase

  alias Mina.Board

  setup do
    #  -5   -4   -3   -2   -1    0    1    2    3    4    5
    # ["1", "2", "1", "2", "2", "2", "1", ".", "1", "x", "x"],  5
    # ["x", "3", "x", "2", "x", "1", ".", ".", "1", "2", "3"],  4
    # ["x", "3", "2", "3", "2", "1", ".", ".", ".", ".", "."],  3
    # ["2", "2", "2", "x", "2", "1", "1", ".", ".", ".", "."],  2
    # ["1", "1", "x", "3", "3", "x", "2", "1", ".", "1", "1"],  1
    # ["1", "1", "3", "x", "3", "2", "x", "2", "1", "2", "x"],  0
    # [".", ".", "2", "x", "2", "1", "1", "2", "x", "2", "1"], -1
    # [".", ".", "1", "2", "2", "1", ".", "1", "1", "1", "."], -2
    # [".", ".", ".", "1", "x", "1", ".", "1", "1", "1", "1"], -3
    # ["1", "1", "2", "2", "2", "1", ".", "1", "x", "2", "3"], -4
    # ["1", "x", "2", "x", "2", "1", "1", "1", "2", "x", "3"]  -5
    [board: %Board{seed: "test", difficulty: 11}]
  end

  describe "build/2" do
    test "builds a new board" do
      assert Board.build("test", 0) == %Board{seed: "test", difficulty: 0}
      assert Board.build("test", 50) == %Board{seed: "test", difficulty: 50}
      assert Board.build("test", 100) == %Board{seed: "test", difficulty: 100}
    end

    test "raises an error with invalid difficulty" do
      assert_raise FunctionClauseError, fn -> Board.build("test", -1) end
      assert_raise FunctionClauseError, fn -> Board.build("test", 101) end
    end
  end

  describe "mine_at?/2" do
    test "returns true when a mine is present", %{board: board} do
      assert Board.mine_at?(board, {0, 1}) == true
    end

    test "returns false when a mine is not present", %{board: board} do
      assert Board.mine_at?(board, {0, 0}) == false
    end
  end

  describe "tile_at/2" do
    test "returns a mine when a mine is present", %{board: board} do
      assert Board.tile_at(board, {0, 1}) == :mine
    end

    test "returns a proximity level when a mine is not present", %{board: board} do
      assert Board.tile_at(board, {0, 0}) == {:proximity, 2}
    end
  end

  describe "reveal/2" do
    test "reveals a mine", %{board: board} do
      assert Board.reveal(board, {0, 1}) == %{{0, 1} => :mine}
    end

    test "reveals a proximate tile", %{board: board} do
      assert Board.reveal(board, {0, 0}) == %{{0, 0} => {:proximity, 2}}
    end

    test "reveals an empty tile", %{board: board} do
      assert Board.reveal(board, {1, -2}) == %{
               {0, -5} => {:proximity, 1},
               {0, -4} => {:proximity, 1},
               {0, -3} => {:proximity, 1},
               {0, -2} => {:proximity, 1},
               {0, -1} => {:proximity, 1},
               {1, -5} => {:proximity, 1},
               {1, -4} => {:proximity, 0},
               {1, -3} => {:proximity, 0},
               {1, -2} => {:proximity, 0},
               {1, -1} => {:proximity, 1},
               {2, -5} => {:proximity, 1},
               {2, -4} => {:proximity, 1},
               {2, -3} => {:proximity, 1},
               {2, -2} => {:proximity, 1},
               {2, -1} => {:proximity, 2}
             }
    end

    test "reveals only tiles within bounds", %{board: board} do
      assert Board.reveal(board, {1, -2}, bounds: {{0, -3}, {2, -1}}) == %{
               {0, -3} => {:proximity, 1},
               {0, -2} => {:proximity, 1},
               {0, -1} => {:proximity, 1},
               {1, -3} => {:proximity, 0},
               {1, -2} => {:proximity, 0},
               {1, -1} => {:proximity, 1},
               {2, -3} => {:proximity, 1},
               {2, -2} => {:proximity, 1},
               {2, -1} => {:proximity, 2}
             }
    end

    test "does not reveal tiles outside bounds", %{board: board} do
      assert Board.reveal(board, {3, 3}, bounds: {{-2, -2}, {2, 2}}) == %{}
    end
  end
end
