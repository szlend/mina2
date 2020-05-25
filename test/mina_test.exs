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

    [board: board, spec: spec]
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

    test "concurrently reveals expected results", %{board: board, spec: spec} do
      bounds = {{bot_x, bot_y}, {top_x, top_y}} = {{-12, -12}, {11, 11}}
      positions = for x <- bot_x..top_x, y <- bot_y..top_y, do: {x, y}

      # reveal all the positions at random concurrently
      positions
      |> Enum.shuffle()
      |> Task.async_stream(
        fn position -> Mina.reveal_tile(spec, position) end,
        max_concurrency: 128,
        ordered: false
      )
      |> Stream.run()

      # get all the reveals from partitions
      partitioned_reveals =
        positions
        |> Enum.map(fn position -> Partition.position(spec, position) end)
        |> Enum.uniq()
        |> Enum.reduce(%{}, fn position, reveals ->
          {:ok, pid} = Partition.Supervisor.ensure_partition(spec, position)
          partition = :sys.get_state(pid)
          Map.merge(reveals, partition.reveals)
        end)

      # simulate the reveals without partitions
      board_reveals =
        Enum.reduce(positions, %{}, fn position, reveals ->
          new_reveals = Board.reveal(board, position, bounds: bounds, reveals: reveals)
          Map.merge(reveals, new_reveals)
        end)

      # partitioned reveals should match board reveals
      assert Enum.count(partitioned_reveals) == Enum.count(board_reveals)
      assert partitioned_reveals == board_reveals
    end
  end
end
