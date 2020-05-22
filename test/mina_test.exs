defmodule MinaTest do
  use Mina.DataCase, async: false

  alias Mina.{Board, Partition}

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

    on_exit(&reset_state/0)

    board = %Board{seed: "test", difficulty: 11}
    spec = %Partition.Spec{board: board, size: 3}

    [spec: spec]
  end

  describe "reveal_tile/3" do
    test "reveals tiles", %{spec: spec} do
      assert Mina.reveal_tile(spec, {0, 0}) == %{{0, 0} => {:proximity, 2}}
    end

    test "reveals tiles across partitions", %{spec: spec} do
      assert Mina.reveal_tile(spec, {1, -2}) == %{
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

    test "reveals tiles across partitions with depth limit", %{spec: spec} do
      assert Mina.reveal_tile(spec, {1, -2}, 1) == %{
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
  end
end
