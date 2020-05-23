defmodule Mina.Partition.ServerTest do
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

    [spec: spec]
  end

  describe "start_link/1" do
    test "starts a server", %{spec: spec} do
      assert {:ok, _server} = Partition.Server.start_link(spec: spec, position: {0, 0})
    end

    test "starts a named server", %{spec: spec} do
      name = __MODULE__.StartLinkNamed
      {:ok, server} = Partition.Server.start_link(spec: spec, position: {0, 0}, name: name)
      assert Keyword.get(Process.info(server), :registered_name) == name
    end
  end

  describe "via_position/2" do
    test "builds a via-tuple", %{spec: spec} do
      assert Partition.Server.via_position(spec, {0, 0}) ==
               {:via, Horde.Registry, {Partition.Registry, {{"test", 11, 5}, {0, 0}}}}
    end
  end

  describe "reveal/2" do
    setup %{spec: spec} do
      {:ok, server} = Partition.Server.start_link(spec: spec, position: {0, 0})
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
