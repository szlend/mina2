defmodule Mina.Partition.TileSerializerTest do
  use Mina.DataCase, async: true
  alias Mina.{Partition, World}
  alias Mina.Partition.TileSerializer

  setup do
    reveals = %{
      {-4, 4} => {:proximity, 2},
      {-3, 4} => :mine,
      {-3, 5} => {:proximity, 1},
      {-2, 5} => {:proximity, 2},
      {-1, 5} => :mine,
      {-4, 7} => {:proximity, 1},
      {-3, 7} => {:proximity, 0}
    }

    world = %World{seed: "test", difficulty: 11, partition_size: 4}
    partition = %Partition{world: world, position: {-4, 4}, reveals: %{}}
    [world: world, partition: partition, reveals: reveals]
  end

  describe "encode/1" do
    setup %{partition: partition, reveals: reveals} do
      [partition: %{partition | reveals: reveals}]
    end

    test "encodes the partition reveals", %{partition: partition} do
      assert TileSerializer.encode(partition) == {:ok, "2muuu12muuuu10uu"}
    end
  end

  describe "decode/2" do
    test "decodes the partition reveals", %{partition: partition, reveals: reveals} do
      {:ok, partition} = TileSerializer.decode(partition, "2muuu12muuuu10uu")
      assert partition.reveals == reveals
    end

    test "returns an error for invalid char", %{partition: partition} do
      assert {:error, {:invalid_char, "z"}} = TileSerializer.decode(partition, "2zuuu12muuuu10uu")
    end

    test "returns an error with short input", %{partition: partition} do
      assert {:error, :data_too_short} = TileSerializer.decode(partition, "2muuu12muuuu10u")
    end

    test "returns an error with long input", %{partition: partition} do
      assert {:error, :data_too_long} = TileSerializer.decode(partition, "2muuu12muuuu10uuu")
    end
  end
end
