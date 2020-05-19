defmodule Mina.PartitionTest do
  use Mina.DataCase

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
    board = %Board{seed: "test", difficulty: 11}
    partition = %Partition{board: board, size: 5, position: {0, 0}, reveals: %{}}

    [board: board, partition: partition]
  end

  describe "build/3" do
    test "builds a new partition", %{board: board} do
      assert Partition.build(board, {0, 0}, 5) == %Partition{
               board: board,
               size: 5,
               position: {0, 0},
               reveals: %{}
             }
    end
  end

  describe "id/1" do
    test "returns the correct id", %{partition: partition} do
      assert Partition.id(partition) == {"test", 11, 5, {0, 0}}
    end
  end

  describe "partition_at/2" do
    test "returns the correct partition id", %{partition: partition} do
      assert Partition.partition_at(partition, {0, 0}) == {"test", 11, 5, {0, 0}}
      assert Partition.partition_at(partition, {1, 1}) == {"test", 11, 5, {0, 0}}
      assert Partition.partition_at(partition, {4, 4}) == {"test", 11, 5, {0, 0}}
      assert Partition.partition_at(partition, {5, 5}) == {"test", 11, 5, {5, 5}}
      assert Partition.partition_at(partition, {6, 6}) == {"test", 11, 5, {5, 5}}
      assert Partition.partition_at(partition, {-1, -1}) == {"test", 11, 5, {-5, -5}}
      assert Partition.partition_at(partition, {-4, -4}) == {"test", 11, 5, {-5, -5}}
      assert Partition.partition_at(partition, {-5, -5}) == {"test", 11, 5, {-5, -5}}
      assert Partition.partition_at(partition, {-6, -6}) == {"test", 11, 5, {-10, -10}}
    end
  end

  describe "reveal/2" do
    setup %{board: board} do
      [partition: %Partition{board: board, size: 4, position: {-4, -4}, reveals: %{}}]
    end

    test "returns new partition with reveals and border positions", %{partition: partition} do
      partition = %{partition | reveals: %{{-1, -1} => :mine}}

      assert {new_partition, reveals, border_positions} = Partition.reveal(partition, {-4, -1})
      assert new_partition.reveals == Map.merge(partition.reveals, reveals)

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

      assert border_positions == %{
               {"test", 11, 4, {-4, 0}} => [{-4, 0}, {-3, 0}],
               {"test", 11, 4, {-8, 0}} => [{-5, 0}],
               {"test", 11, 4, {-8, -4}} => [{-5, -4}, {-5, -3}, {-5, -2}, {-5, -1}]
             }
    end

    test "does not return any reveals when already revealed", %{partition: partition} do
      partition = %{partition | reveals: %{{-4, -1} => {:proximity, 0}}}
      assert {^partition, %{}, %{}} = Partition.reveal(partition, {-4, -1})
    end
  end
end
