defmodule Mina.Partition.ServerTest do
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

    [world: %World{seed: "test", difficulty: 11, partition_size: 5}]
  end

  describe "start_link/1" do
    test "starts a server", %{world: world} do
      assert {:ok, _server} = start_supervised({Partition.Server, world: world, position: {0, 0}})
    end

    test "starts a named server", %{world: world} do
      {:ok, server} =
        start_supervised({Partition.Server, world: world, position: {0, 0}, name: __MODULE__})

      assert Keyword.get(Process.info(server), :registered_name) == __MODULE__
    end
  end

  describe "via_position/2" do
    test "builds a via-tuple", %{world: world} do
      assert Partition.Server.via_position(world, {0, 0}) ==
               {:via, Partition.Registry, {{"test", 11, 5}, {0, 0}}}
    end
  end

  describe "reveal/2" do
    setup %{world: world} do
      {:ok, server} = start_supervised({Partition.Server, world: world, position: {0, 0}})
      [server: server]
    end

    test "returns reveals", %{server: server} do
      {reveals, _border_positions} = Partition.Server.reveal(server, [{0, 0}, {1, 0}])

      assert reveals == %{
               {0, 0} => {:proximity, 2},
               {1, 0} => :mine
             }
    end

    test "returns border_positions", %{server: server} do
      {_reveals, border_positions} = Partition.Server.reveal(server, [{2, 2}])

      assert border_positions == %{
               {0, 5} => [{0, 5}, {1, 5}, {2, 5}, {3, 5}],
               {5, 0} => [{5, 1}, {5, 2}, {5, 3}, {5, 4}]
             }
    end

    test "keeps track of reveals", %{server: server} do
      Partition.Server.reveal(server, [{0, 0}])
      Partition.Server.reveal(server, [{1, 0}])

      assert :sys.get_state(server).reveals == %{
               {0, 0} => {:proximity, 2},
               {1, 0} => :mine
             }
    end
  end
end
