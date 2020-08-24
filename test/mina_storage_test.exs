defmodule MinaStorageTest do
  use Mina.DataCase, async: false

  alias MinaStorage.{Partition, Repo}

  describe "get_partition/2" do
    setup do
      partition = Repo.insert!(%Partition{world_id: "test", x: "0", y: "0", reveals: "foo"})
      [partition: partition]
    end

    test "it returns the partition when it exists", %{partition: partition} do
      assert MinaStorage.get_partition("test", 0, 0) == partition
    end

    test "it returns nil when the partition does not exist" do
      assert MinaStorage.get_partition("foo", 0, 0) == nil
    end
  end

  describe "set_partition/3" do
    test "it inserts the partition when it does not yet exist" do
      assert {:ok, _} = MinaStorage.set_partition("test", 0, 0, "foo")
      assert %Partition{reveals: "foo"} = MinaStorage.get_partition("test", 0, 0)
    end

    test "it updates the partition when it already exists" do
      {:ok, _} = MinaStorage.set_partition("test", 0, 0, "foo")
      {:ok, _} = MinaStorage.set_partition("test", 0, 0, "bar")
      assert %Partition{reveals: "bar"} = MinaStorage.get_partition("test", 0, 0)
    end
  end
end
