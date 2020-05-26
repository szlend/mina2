defmodule Mina.PartitionTest do
  use Mina.DataCase, async: true
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

    world = %World{seed: "test", difficulty: 11, partition_size: 5}
    partition = %Partition{world: world, position: {0, 0}, reveals: %{}}
    [world: world, partition: partition]
  end

  describe "build/3" do
    test "builds a new partition", %{world: world} do
      assert Partition.build(world, {0, 0}) == %Partition{
               world: world,
               position: {0, 0},
               reveals: %{}
             }
    end

    test "raises an error with invalid position", %{world: world} do
      assert_raise FunctionClauseError, fn -> Partition.build(world, {1, 1}) end
    end
  end

  describe "position/2" do
    test "returns the correct position - inside", %{world: world} do
      assert Partition.position(world, {1, 1}) == {0, 0}
    end

    test "returns the correct position - bottom-left", %{world: world} do
      assert Partition.position(world, {0, 0}) == {0, 0}
    end

    test "returns the correct position - bottom-right position", %{world: world} do
      assert Partition.position(world, {0, 4}) == {0, 0}
    end

    test "returns the correct position - top-left", %{world: world} do
      assert Partition.position(world, {4, 0}) == {0, 0}
    end

    test "returns the correct position - top-right", %{world: world} do
      assert Partition.position(world, {4, 4}) == {0, 0}
    end

    test "returns the correct position - inside negative", %{world: world} do
      assert Partition.position(world, {-4, -4}) == {-5, -5}
    end

    test "returns the correct position - bottom-left negative", %{world: world} do
      assert Partition.position(world, {-5, -5}) == {-5, -5}
    end

    test "returns the correct position - bottom-right negative", %{world: world} do
      assert Partition.position(world, {-1, -5}) == {-5, -5}
    end

    test "returns the correct position - top-left negative", %{world: world} do
      assert Partition.position(world, {-5, -1}) == {-5, -5}
    end

    test "returns the correct position - top-right negative", %{world: world} do
      assert Partition.position(world, {-1, -1}) == {-5, -5}
    end
  end

  describe "id_at/1" do
    test "returns the correct partition id", %{world: world} do
      assert Partition.id_at(world, {0, 0}) == {{"test", 11, 5}, {0, 0}}
    end

    test "raises an error with invalid position", %{world: world} do
      assert_raise FunctionClauseError, fn -> Partition.id_at(world, {1, 1}) end
    end
  end

  describe "id/1" do
    test "returns the correct partition id", %{partition: partition} do
      assert Partition.id(partition) == {{"test", 11, 5}, {0, 0}}
    end
  end

  describe "reveal/2" do
    setup do
      world = %World{seed: "test", difficulty: 11, partition_size: 4}
      partition = %Partition{world: world, position: {-4, -4}, reveals: %{}}
      [world: world, partition: partition]
    end

    test "updates the partition with new reveals", %{partition: partition} do
      {partition, _, _} = Partition.reveal(%{partition | reveals: %{{-3, -1} => :mine}}, {-2, -1})

      assert partition.reveals == %{
               {-2, -1} => :mine,
               {-3, -1} => :mine
             }
    end

    test "returns reveals", %{partition: partition} do
      {_, reveals, _} = Partition.reveal(partition, {-2, -1})
      assert reveals == %{{-2, -1} => :mine}
    end

    test "does not return existing reveals", %{partition: partition} do
      {_, reveals, _} = Partition.reveal(%{partition | reveals: %{{-2, -1} => :mine}}, {-2, -1})
      assert reveals == %{}
    end

    test "does not return reveals outside of bounds", %{partition: partition} do
      {_, reveals, _} = Partition.reveal(partition, {-4, -1})

      assert reveals == %{
               {-4, -4} => {:proximity, 1},
               {-4, -3} => {:proximity, 0},
               {-4, -2} => {:proximity, 0},
               {-4, -1} => {:proximity, 0},
               {-3, -4} => {:proximity, 2},
               {-3, -3} => {:proximity, 0},
               {-3, -2} => {:proximity, 1},
               {-3, -1} => {:proximity, 2},
               {-2, -4} => {:proximity, 2},
               {-2, -3} => {:proximity, 1},
               {-2, -2} => {:proximity, 2}
             }
    end

    test "returns border positions - top-left", %{world: world} do
      partition = %Partition{world: world, position: {-4, -4}, reveals: %{}}
      {_, _, border_positions} = Partition.reveal(partition, {-4, -1})

      assert border_positions == %{
               {-4, 0} => [{-4, 0}, {-3, 0}],
               {-8, 0} => [{-5, 0}],
               {-8, -4} => [{-5, -4}, {-5, -3}, {-5, -2}, {-5, -1}]
             }
    end

    test "returns border positions - top-right", %{world: world} do
      partition = %Partition{world: world, position: {0, 0}, reveals: %{}}
      {_, _, border_positions} = Partition.reveal(partition, {3, 3})

      assert border_positions == %{
               {0, 4} => [{0, 4}, {1, 4}, {2, 4}, {3, 4}],
               {4, 0} => [{4, 0}, {4, 1}, {4, 2}, {4, 3}],
               {4, 4} => [{4, 4}]
             }
    end
  end
end
