defmodule Mina.Partition.SupervisorTest do
  use Mina.DataCase, async: true
  alias Mina.{Partition, World}

  setup do
    [world: %World{seed: "test", difficulty: 11, partition_size: 5}]
  end

  describe "start_link/1" do
    test "starts a supervisor" do
      assert {:ok, _supervisor} = start_supervised({Partition.Supervisor, name: __MODULE__})
    end
  end

  describe "start_partition/3" do
    setup do
      {:ok, supervisor} = start_supervised({Partition.Supervisor, name: __MODULE__})
      [supervisor: supervisor]
    end

    test "starts a partition server", %{supervisor: supervisor, world: world} do
      assert {:ok, _server} = Partition.Supervisor.start_partition(supervisor, world, {0, 0})
    end

    test "it names the partition server", %{supervisor: supervisor, world: world} do
      {:ok, _server} = Partition.Supervisor.start_partition(supervisor, world, {0, 0})
      assert GenServer.whereis(Partition.Server.via_position(world, {0, 0})) != nil
    end
  end

  describe "ensure_partition/3" do
    setup %{world: world} do
      {:ok, supervisor} = start_supervised({Partition.Supervisor, name: __MODULE__})
      {:ok, server} = Partition.Supervisor.start_partition(supervisor, world, {0, 0})
      [supervisor: supervisor, server: server]
    end

    test "starts a new partition server if it does not yet exist", %{
      supervisor: supervisor,
      server: server,
      world: world
    } do
      {:ok, new_server} = Partition.Supervisor.ensure_partition(supervisor, world, {5, 0})
      assert new_server != server
    end

    test "returns the existing partition server if it already exists", %{
      supervisor: supervisor,
      server: server,
      world: world
    } do
      {:ok, new_server} = Partition.Supervisor.ensure_partition(supervisor, world, {0, 0})
      assert new_server == server
    end
  end
end
