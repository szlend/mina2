defmodule Mina.Partition.ServerTest do
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
    spec = %Partition.Spec{board: board, size: 5}
    partition = %Partition{spec: spec, position: {0, 0}, reveals: %{}}

    [partition: partition]
  end

  describe "reveal/2" do
    setup %{partition: partition} do
      {:ok, server} = Partition.Server.start_link(partition: partition)
      [server: server]
    end

    test "reveals a mine", %{server: server} do
      assert Partition.Server.reveal(server, {1, 0}) == %{{1, 0} => :mine}
    end

    test "keeps track of reveals", %{server: server} do
      Partition.Server.reveal(server, {0, 0})
      Partition.Server.reveal(server, {1, 0})

      assert :sys.get_state(server).reveals == %{
               {0, 0} => {:proximity, 2},
               {1, 0} => :mine
             }
    end
  end
end
