defmodule Mina.Partition.SupervisorTest do
  use Mina.DataCase, async: false
  alias Mina.{Board, Partition}

  setup do
    board = %Board{seed: "test", difficulty: 11}
    spec = %Partition.Spec{board: board, size: 5}

    [spec: spec]
  end

  describe "start_link/1" do
    test "starts a supervisor" do
      assert {:ok, _supervisor} = Partition.Supervisor.start_link([])
    end

    test "starts a named supervisor" do
      name = __MODULE__.StartLinkNamed
      {:ok, supervisor} = Partition.Supervisor.start_link(name: name)
      assert Keyword.get(Process.info(supervisor), :registered_name) == name
    end
  end

  describe "start_child/3" do
    setup do
      {:ok, supervisor} = Partition.Supervisor.start_link()
      [supervisor: supervisor]
    end

    test "starts a partition server", %{supervisor: supervisor, spec: spec} do
      assert {:ok, _server} = Partition.Supervisor.start_child(supervisor, spec, {0, 0})
    end

    test "it names the partition server", %{supervisor: supervisor, spec: spec} do
      {:ok, _server} = Partition.Supervisor.start_child(supervisor, spec, {0, 0})
      assert GenServer.whereis(Partition.Server.via_position(spec, {0, 0})) != nil
    end
  end

  describe "ensure_child/3" do
    setup %{spec: spec} do
      {:ok, supervisor} = Partition.Supervisor.start_link()
      {:ok, server} = Partition.Supervisor.start_child(supervisor, spec, {0, 0})
      [supervisor: supervisor, server: server]
    end

    test "starts a new partition server if it does not yet exist", %{
      supervisor: supervisor,
      server: server,
      spec: spec
    } do
      {:ok, new_server} = Partition.Supervisor.ensure_child(supervisor, spec, {5, 0})
      assert new_server != server
    end

    test "returns the existing partition server if it already exists", %{
      supervisor: supervisor,
      server: server,
      spec: spec
    } do
      {:ok, new_server} = Partition.Supervisor.ensure_child(supervisor, spec, {0, 0})
      assert new_server == server
    end
  end
end
