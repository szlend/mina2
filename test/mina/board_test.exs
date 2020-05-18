defmodule Mina.BoardTest do
  use Mina.DataCase

  alias Mina.Board

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
    setup do
      [board: %Board{seed: "test", difficulty: 40}]
    end

    test "returns true when a mine is present", %{board: board} do
      assert Board.mine_at?(board, {0, 1}) == true
    end

    test "returns false when a mine is not present", %{board: board} do
      assert Board.mine_at?(board, {0, 0}) == false
    end
  end

  describe "tile_at/2" do
    setup do
      [board: %Board{seed: "test", difficulty: 40}]
    end

    test "returns a mine when a mine is present", %{board: board} do
      assert Board.tile_at(board, {0, 1}) == :mine
    end

    test "returns a proximity level when a mine is not present", %{board: board} do
      assert Board.tile_at(board, {0, 0}) == {:proximity, 4}
    end
  end
end
