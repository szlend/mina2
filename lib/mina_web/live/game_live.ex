defmodule MinaWeb.GameLive do
  @moduledoc """
  Live game
  """

  use MinaWeb, :live_view

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

    {:ok, socket, temporary_assigns: [actions: []]}
  end

  @impl true
  def handle_event("resize", %{"width" => width, "height" => height}, socket) do
    {:noreply, assign(socket, width: trunc(width), height: trunc(height))}
  end

  @impl true
  def handle_event("camera", %{"x" => x, "y" => y}, socket) do
    x = String.to_integer(x)
    y = String.to_integer(y)
    width = socket.assigns.width
    height = socket.assigns.height

    partitions = partitions_in_viewport(socket, x, y, width, height)
    actions = actions(socket, partitions, socket.assigns.partitions)

    socket = assign(socket, x: x, y: y, partitions: partitions, actions: actions)
    {:noreply, socket}
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
      data-actions="<%= Jason.encode_to_iodata!(@actions) %>"
    />
    """
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

  defp actions(socket, partitions, prev_partitions) do
    added = MapSet.difference(partitions, prev_partitions)
    removed = MapSet.difference(prev_partitions, partitions)

    r = for {x, y} <- removed, do: ["r", to_string(x), to_string(y), nil]
    a = for {x, y} <- added, do: ["a", to_string(x), to_string(y), gen_tiles(socket, x, y)]

    r ++ a
  end

  defp gen_tiles(socket, px, py) do
    world = socket.assigns.world

    for y <- py..(py + world.partition_size - 1), x <- px..(px + world.partition_size - 1) do
      tile_at(world, {x, y})
    end
    |> to_string()
  end

  defp tile_at(world, position) do
    case Mina.World.reveal_at(world, position) do
      {:mine, _} -> ?m
      {{:proximity, n}, _} -> ?0 + n
    end
  end
end
