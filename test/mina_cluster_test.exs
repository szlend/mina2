defmodule MinaClusterTest do
  use Mina.ClusterCase

  alias Mina.{Partition, World}

  setup do
    world = %World{seed: "test", difficulty: 20, partition_size: 5}
    nodes = start_nodes("mina-cluster", 3)
    [world: world, nodes: nodes]
  end

  @tag timeout: :infinity
  describe "reveal_tile/3" do
    test "concurrently reveals expected results across nodes", %{world: world, nodes: nodes} do
      bounds = {{bot_x, bot_y}, {top_x, top_y}} = {{-20, -20}, {19, 19}}
      positions = for x <- bot_x..top_x, y <- bot_y..top_y, do: {x, y}
      chunk_length = div(length(positions), length(nodes)) + 1

      # reveal all the positions at random, concurrently across nodes
      positions
      |> Enum.shuffle()
      |> Enum.chunk_every(chunk_length)
      |> Enum.zip(nodes)
      |> Enum.map(fn {positions, node} ->
        Task.async_stream(
          positions,
          fn position -> :erpc.call(node, Mina, :reveal_tile, [world, position]) end,
          ordered: false
        )
      end)
      |> Task.async_stream(&Stream.run/1, max_concurrency: length(nodes))
      |> Stream.run()

      # get all the reveals from partitions
      partition_reveals =
        positions
        |> Enum.map(fn position -> Partition.position(world, position) end)
        |> Enum.uniq()
        |> Enum.reduce(%{}, fn position, reveals ->
          via = Partition.Server.via_position(world, position)
          pid = :erpc.call(hd(nodes), GenServer, :whereis, [via])
          state = :sys.get_state(pid)
          Map.merge(reveals, state.partition.reveals)
        end)

      # simulate the reveals without partitions
      world_reveals =
        Enum.reduce(positions, %{}, fn position, reveals ->
          new_reveals = World.reveal(world, position, bounds: bounds, reveals: reveals)
          Map.merge(reveals, new_reveals)
        end)

      # partitioned reveals should match world reveals
      assert Enum.count(partition_reveals) == Enum.count(world_reveals)
      assert partition_reveals == world_reveals
    end
  end
end
