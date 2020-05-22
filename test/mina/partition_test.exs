defmodule Mina.PartitionTest do
  use Mina.DataCase, async: true
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
    spec = %Partition.Spec{board: board, size: 5}
    partition = %Partition{spec: spec, position: {0, 0}, reveals: %{}}

    [board: board, spec: spec, partition: partition]
  end

  describe "build/3" do
    test "builds a new partition", %{spec: spec} do
      assert Partition.build(spec, {0, 0}) == %Partition{
               spec: spec,
               position: {0, 0},
               reveals: %{}
             }
    end

    test "raises an error with invalid position", %{spec: spec} do
      assert_raise FunctionClauseError, fn -> Partition.build(spec, {1, 1}) end
    end
  end

  describe "id_at/2" do
    test "returns the correct partition id - inside", %{spec: spec} do
      assert Partition.id_at(spec, {1, 1}) == {{"test", 11, 5}, {0, 0}}
    end

    test "returns the correct partition id - bottom-left", %{spec: spec} do
      assert Partition.id_at(spec, {0, 0}) == {{"test", 11, 5}, {0, 0}}
    end

    test "returns the correct partition id - bottom-right position", %{spec: spec} do
      assert Partition.id_at(spec, {0, 4}) == {{"test", 11, 5}, {0, 0}}
    end

    test "returns the correct partition id - top-left", %{spec: spec} do
      assert Partition.id_at(spec, {4, 0}) == {{"test", 11, 5}, {0, 0}}
    end

    test "returns the correct partition id - top-right", %{spec: spec} do
      assert Partition.id_at(spec, {4, 4}) == {{"test", 11, 5}, {0, 0}}
    end

    test "returns the correct partition id - inside negative", %{spec: spec} do
      assert Partition.id_at(spec, {-4, -4}) == {{"test", 11, 5}, {-5, -5}}
    end

    test "returns the correct partition id - bottom-left negative", %{spec: spec} do
      assert Partition.id_at(spec, {-5, -5}) == {{"test", 11, 5}, {-5, -5}}
    end

    test "returns the correct partition id - bottom-right negative", %{spec: spec} do
      assert Partition.id_at(spec, {-1, -5}) == {{"test", 11, 5}, {-5, -5}}
    end

    test "returns the correct partition id - top-left negative", %{spec: spec} do
      assert Partition.id_at(spec, {-5, -1}) == {{"test", 11, 5}, {-5, -5}}
    end

    test "returns the correct partition id - top-right negative", %{spec: spec} do
      assert Partition.id_at(spec, {-1, -1}) == {{"test", 11, 5}, {-5, -5}}
    end
  end

  describe "id/1" do
    test "returns the correct partition id", %{partition: partition} do
      assert Partition.id(partition) == {{"test", 11, 5}, {0, 0}}
    end
  end

  describe "reveal/2" do
    setup %{board: board} do
      spec = %Partition.Spec{board: board, size: 4}
      partition = %Partition{spec: spec, position: {-4, -4}, reveals: %{}}

      [partition: partition]
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

    test "returns border positions", %{partition: partition} do
      {_, _, border_positions} = Partition.reveal(partition, {-4, -1})

      assert border_positions == %{
               {{"test", 11, 4}, {-4, 0}} => [{-4, 0}, {-3, 0}],
               {{"test", 11, 4}, {-8, 0}} => [{-5, 0}],
               {{"test", 11, 4}, {-8, -4}} => [{-5, -4}, {-5, -3}, {-5, -2}, {-5, -1}]
             }
    end
  end
end
