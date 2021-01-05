defmodule MinaClusterTest do
  use Mina.ClusterCase, async: false

  alias Mina.{Partition, World}

  setup do
    world = %World{seed: "test", difficulty: 20, partition_size: 5}
    nodes = start_nodes("mina-cluster", 3)
    on_exit(fn -> reset_state() end)

    [world: world, nodes: nodes]
  end

  describe "reveal_tile/3" do
    test "concurrently reveals expected results across nodes", %{world: world, nodes: nodes} do
      bounds = {{bot_x, bot_y}, {top_x, top_y}} = {{-20, -20}, {19, 19}}
      positions = for x <- bot_x..top_x, y <- bot_y..top_y, do: {x, y}
      chunk_length = div(length(positions), length(nodes))

      # reveal all the positions at random, concurrently across nodes
      positions
      |> Enum.shuffle()
      |> Enum.chunk_every(chunk_length, chunk_length)
      |> Enum.zip(nodes ++ [Node.self()])
      |> Enum.map(fn {positions, node} ->
        Task.async_stream(
          positions,
          fn position -> :rpc.call(node, Mina, :reveal_tile, [world, position]) end,
          max_concurrency: 32,
          ordered: false
        )
      end)
      |> Task.async_stream(&Stream.run/1, max_concurrency: length(nodes) + 1)
      |> Stream.run()

      # get all the reveals from partitions
      partition_reveals =
        positions
        |> Enum.map(fn position -> Partition.position(world, position) end)
        |> Enum.uniq()
        |> Enum.reduce(%{}, fn position, reveals ->
          {:ok, pid} = Partition.Supervisor.ensure_partition(world, position)
          partition = :sys.get_state(pid).partition
          Map.merge(reveals, partition.reveals)
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
