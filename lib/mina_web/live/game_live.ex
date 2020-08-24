defmodule MinaWeb.GameLive do
  @moduledoc """
  Live game
  """

  use MinaWeb, :live_view

  alias Mina.Partition.TileSerializer

  @tileset %{
    "u" => [0, 0],
    "f" => [128, 0],
    "m" => [256, 0],
    "0" => [384, 0],
    "1" => [0, 128],
    "2" => [128, 128],
    "3" => [256, 128],
    "4" => [384, 128],
    "5" => [0, 256],
    "6" => [128, 256],
    "7" => [256, 256],
    "8" => [384, 256]
  }
  @tileset_json Jason.encode!(@tileset)

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        world: Mina.World.build("test", 15, partition_size: 50),
        tileset: @tileset_json,
        tileset_url: Routes.static_path(socket, "/images/tiles.png"),
        tile_size: 128,
        tile_scale: 1 / 4,
        width: 1280,
        height: 720,
        x: 0,
        y: 0,
        partitions: MapSet.new()
      )

    {:ok, socket}
  end

  @impl true
  def handle_event("resize", %{"width" => width, "height" => height}, socket) do
    x = socket.assigns.x
    y = socket.assigns.y
    width = trunc(width)
    height = trunc(height)
    socket = handle_viewport_change(socket, x, y, width, height)
    {:noreply, socket}
  end

  @impl true
  def handle_event("camera", %{"x" => x, "y" => y}, socket) do
    x = String.to_integer(x)
    y = String.to_integer(y)
    width = socket.assigns.width
    height = socket.assigns.height
    socket = handle_viewport_change(socket, x, y, width, height)
    {:noreply, socket}
  end

  @impl true
  def handle_event("reveal", %{"x" => x, "y" => y}, socket) do
    x = String.to_integer(x)
    y = String.to_integer(y)

    partition_reveals = Mina.reveal_tile_partitioned(socket.assigns.world, {x, y})

    for {partition_position, reveals} <- partition_reveals do
      message = {:action, encode_action_update(partition_position, reveals)}
      Mina.broadcast_partition_at!(socket.assigns.world, partition_position, "actions", message)
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info({:action, action}, socket) do
    {:noreply, push_event(socket, "actions", %{actions: [action]})}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <div
      id="game"
      phx-hook="Game"
      phx-update="ignore"
      data-tileset="<%= @tileset %>"
      data-tileset-url="<%= @tileset_url %>"
      data-tile-size="<%= @tile_size %>"
      data-tile-scale="<%= @tile_scale %>"
      data-partition-size="<%= @world.partition_size %>"
    />
    """
  end

  defp handle_viewport_change(socket, x, y, width, height) do
    partitions = partitions_in_viewport(socket, x, y, width, height)

    added = MapSet.difference(partitions, socket.assigns.partitions)
    removed = MapSet.difference(socket.assigns.partitions, partitions)

    # Unsubscribe from partitions out of the viewport
    removed_actions =
      for {x, y} <- removed do
        Mina.unsubscribe_partition_at(socket.assigns.world, {x, y}, "actions")
        encode_action_remove({x, y})
      end

    # Subscribe to partitions in the viewport
    added_actions =
      for {x, y} <- added do
        Mina.subscribe_partition_at(socket.assigns.world, {x, y}, "actions")
        encode_action_add({x, y}, socket.assigns.world)
      end

    socket
    |> push_event("actions", %{actions: removed_actions ++ added_actions})
    |> assign(
      x: x,
      y: y,
      width: width,
      height: height,
      partitions: partitions
    )
  end

  defp partitions_in_viewport(socket, x, y, width, height) do
    partition_size = socket.assigns.world.partition_size
    tile_size = trunc(socket.assigns.tile_size * socket.assigns.tile_scale)

    min_tile_x = div(x - width, tile_size)
    min_tile_y = div(y - height, tile_size)
    max_tile_x = div(x + width, tile_size)
    max_tile_y = div(y + height, tile_size)

    min_x = min_tile_x - Integer.mod(min_tile_x, partition_size)
    min_y = min_tile_y - Integer.mod(min_tile_y, partition_size)
    max_x = max_tile_x + partition_size - Integer.mod(max_tile_x, partition_size)
    max_y = max_tile_y + partition_size - Integer.mod(max_tile_y, partition_size)

    xs = min_x |> Stream.iterate(&(&1 + partition_size)) |> Stream.take_while(&(&1 < max_x))
    ys = min_y |> Stream.iterate(&(&1 + partition_size)) |> Stream.take_while(&(&1 < max_y))

    MapSet.new(for y <- ys, x <- xs, do: {x, y})
  end

  defp encode_action_update({px, py}, reveals) do
    data =
      for {{x, y}, tile} <- reveals do
        char = TileSerializer.encode_tile(tile)
        [x - px, y - py, to_string([char])]
      end

    ["u", to_string(px), to_string(py), data]
  end

  defp encode_action_add({px, py}, world) do
    {:ok, data} = Mina.encode_partition_at(world, {px, py}, TileSerializer)
    ["a", to_string(px), to_string(py), data]
  end

  defp encode_action_remove({px, py}) do
    ["r", to_string(px), to_string(py), nil]
  end
end
