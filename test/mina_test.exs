defmodule MinaTest do
  use Mina.DataCase, async: false

  alias Mina.{Partition, World}

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
    [world: %World{seed: "test", difficulty: 11, partition_size: 3}]
  end

  describe "reveal_tile/3" do
    test "reveals tiles", %{world: world} do
      assert Mina.reveal_tile(world, {0, 0}) == %{{0, 0} => {:proximity, 2}}
    end

    test "reveals tiles across partitions", %{world: world} do
      assert Mina.reveal_tile(world, {1, -2}) == %{
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

    test "reveals tiles across partitions with depth limit", %{world: world} do
      assert Mina.reveal_tile(world, {1, -2}, 1) == %{
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

    test "concurrently reveals expected results", %{world: world} do
      bounds = {{bot_x, bot_y}, {top_x, top_y}} = {{-12, -12}, {11, 11}}
      positions = for x <- bot_x..top_x, y <- bot_y..top_y, do: {x, y}

      # reveal all the positions at random concurrently
      positions
      |> Enum.shuffle()
      |> Task.async_stream(
        fn position -> Mina.reveal_tile(world, position) end,
        max_concurrency: 128,
        ordered: false
      )
      |> Stream.run()

      # get all the reveals from partitions
      partitioned_reveals =
        positions
        |> Enum.map(fn position -> Partition.position(world, position) end)
        |> Enum.uniq()
        |> Enum.reduce(%{}, fn position, reveals ->
          {:ok, pid} = Partition.Supervisor.ensure_partition(world, position)
          partition = :sys.get_state(pid)
          Map.merge(reveals, partition.reveals)
        end)

      # simulate the reveals without partitions
      world_reveals =
        Enum.reduce(positions, %{}, fn position, reveals ->
          new_reveals = World.reveal(world, position, bounds: bounds, reveals: reveals)
          Map.merge(reveals, new_reveals)
        end)

      # partitioned reveals should match world reveals
      assert Enum.count(partitioned_reveals) == Enum.count(world_reveals)
      assert partitioned_reveals == world_reveals
    end
  end

  describe "reveal_tile_partitioned/3" do
    test "reveals tiles", %{world: world} do
      assert Mina.reveal_tile_partitioned(world, {0, 0}) == %{
               {0, 0} => %{{0, 0} => {:proximity, 2}}
             }
    end

    test "reveals tiles across partitions", %{world: world} do
      assert Mina.reveal_tile_partitioned(world, {1, -2}) == %{
               {0, -3} => %{
                 {0, -3} => {:proximity, 1},
                 {0, -2} => {:proximity, 1},
                 {0, -1} => {:proximity, 1},
                 {1, -3} => {:proximity, 0},
                 {1, -2} => {:proximity, 0},
                 {1, -1} => {:proximity, 1},
                 {2, -3} => {:proximity, 1},
                 {2, -2} => {:proximity, 1},
                 {2, -1} => {:proximity, 2}
               },
               {0, -6} => %{
                 {0, -5} => {:proximity, 1},
                 {0, -4} => {:proximity, 1},
                 {1, -5} => {:proximity, 1},
                 {1, -4} => {:proximity, 0},
                 {2, -5} => {:proximity, 1},
                 {2, -4} => {:proximity, 1}
               }
             }
    end

    test "reveals tiles across partitions with depth limit", %{world: world} do
      assert Mina.reveal_tile_partitioned(world, {1, -2}, 1) == %{
               {0, -3} => %{
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
             }
    end
  end
end
