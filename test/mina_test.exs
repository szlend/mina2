defmodule MinaTest do
  use Mina.AppCase, async: false

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
          partition = :sys.get_state(pid).partition
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

  describe "flag_tile/3" do
    test "flags a tile", %{world: world} do
      assert Mina.flag_tile(world, {0, 1}) == {:ok, %{{0, 1} => :flag}}
    end

    test "returns empty reveals when tile empty", %{world: world} do
      assert Mina.flag_tile(world, {0, 0}) == {:error, :incorrect_flag}
    end

    test "concurrently reveals expected results", %{world: world} do
      bounds = {{bot_x, bot_y}, {top_x, top_y}} = {{-12, -12}, {11, 11}}
      positions = for x <- bot_x..top_x, y <- bot_y..top_y, do: {x, y}

      # reveal all the positions at random concurrently
      positions
      |> Enum.shuffle()
      |> Task.async_stream(
        fn position -> Mina.flag_tile(world, position) end,
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
          partition = :sys.get_state(pid).partition
          Map.merge(reveals, partition.reveals)
        end)

      # simulate the reveals without partitions
      world_reveals =
        Enum.reduce(positions, %{}, fn position, reveals ->
          case World.flag(world, position, bounds: bounds, reveals: reveals) do
            {:ok, new_reveals} -> Map.merge(reveals, new_reveals)
            {:error, _reason} -> reveals
          end
        end)

      # partitioned reveals should match world reveals
      assert Enum.count(partitioned_reveals) == Enum.count(world_reveals)
      assert partitioned_reveals == world_reveals
    end
  end

  describe "partition_id_at/2" do
    test "it returns the partition id", %{world: world} do
      assert {{"test", 11, 3}, {0, 0}} = Mina.partition_id_at(world, {1, 1})
    end
  end

  describe "load_partition_at/2" do
    test "it skips loading when starting a new partition", %{world: world} do
      assert {:ok, :skip} = Mina.load_partition_at(world, {0, 0})
    end

    test "it loads the partition data", %{world: world} do
      {:ok, _server} = Mina.load_partition_at(world, {0, 0})
      assert {:ok, %Partition{}} = Mina.load_partition_at(world, {0, 0})
    end
  end

  describe "subscribe_partition_at/3" do
    test "it returns :ok", %{world: world} do
      assert Mina.subscribe_partition_at(world, {0, 0}, "test") == :ok
    end
  end

  describe "unsubscribe_partition_at/3" do
    test "it returns :ok", %{world: world} do
      assert Mina.unsubscribe_partition_at(world, {0, 0}, "test") == :ok
    end
  end
end
