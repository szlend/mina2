defmodule MinaWeb.GameLive do
  @moduledoc """
  Live game
  """

  use MinaWeb, :live_view

  @tick 5000
  @size 40

  @impl true
  def mount(%{"name" => name}, _session, socket) do
    Process.send_after(self(), :tick, @tick)
    world = Mina.World.build("test", 12)
    tiles = []

    # tiles = for x <- 0..(@size - 1) /2, y <- 0..(@size - 1), do: {{x, y}, tile_at(world, {x, y})}
    tileset_path = Routes.static_path(socket, "/images/tiles.png")

    socket =
      assign(socket,
        name: name,
        world: world,
        tiles: tiles,
        tileset_path: tileset_path,
        x: 0,
        y: 0
      )

    {:ok, socket, temporary_assigns: [tiles: []]}
  end

  @impl true
  def handle_info(:tick, socket) do
    Process.send_after(self(), :tick, @tick)
    position = {Enum.random(0..(@size - 1)), Enum.random(0..(@size - 1))}
    tiles = [{position, tile_at(socket.assigns.world, position)}]
    {:noreply, assign(socket, :tiles, tiles)}
  end

  @impl true
  def handle_event("key", %{"key" => key}, socket) do
    case key do
      "w" -> {:noreply, assign(socket, y: socket.assigns.y - 5)}
      "s" -> {:noreply, assign(socket, y: socket.assigns.y + 5)}
      "a" -> {:noreply, assign(socket, x: socket.assigns.x - 5)}
      "d" -> {:noreply, assign(socket, x: socket.assigns.x + 5)}
      _ -> {:noreply, socket}
    end
  end

  @impl true
  def render(assigns) do
    ~L"""
    <h1>Name: <%= @name %></h1>
    <svg width="0" height="0">
      <defs>
        <image id="tileset" width="512" height="384" xlink:href="<%= @tileset_path %>" />
        <pattern id="bg" patternUnits="userSpaceOnUse" width="128" height="128">
          <use xlink:href="#unknown" />
        </pattern>

        <svg id="unknown" width="128" height="128" viewBox="0 0 128 128">
          <use xlink:href="#tileset" />
        </svg>

        <svg id="flag" width="128" height="128" viewBox="128 0 128 128">
          <use xlink:href="#tileset" />
        </svg>

        <svg id="mine" width="128" height="128" viewBox="256 0 128 128">
          <use xlink:href="#tileset" />
        </svg>

        <svg id="empty" width="128" height="128" viewBox="384 0 128 128">
          <use xlink:href="#tileset" />
        </svg>

        <svg id="1" width="128" height="128" viewBox="0 128 128 128">
          <use xlink:href="#tileset" />
        </svg>

        <svg id="2" width="128" height="128" viewBox="128 128 128 128">
          <use xlink:href="#tileset" />
        </svg>

        <svg id="3" width="128" height="128" viewBox="256 128 128 128">
          <use xlink:href="#tileset" />
        </svg>

        <svg id="4" width="128" height="128" viewBox="384 128 128 128">
          <use xlink:href="#tileset" />
        </svg>

        <svg id="5" width="128" height="128" viewBox="0 256 128 128">
          <use xlink:href="#tileset" />
        </svg>

        <svg id="6" width="128" height="128" viewBox="128 256 128 128">
          <use xlink:href="#tileset" />
        </svg>

        <svg id="7" width="128" height="128" viewBox="256 256 128 128">
          <use xlink:href="#tileset" />
        </svg>

        <svg id="8" width="128" height="128" viewBox="384 256 128 128">
          <use xlink:href="#tileset" />
        </svg>
      </defs>
    </svg>

    <svg width="1280" height="960" viewBox="0 0 5120 3840" phx-keydown="key" tabindex="0" style="overflow: none">

      <rect width="100%" height="100%" fill="url(#bg)" transform="translate(<%= @x %>, <%= @y %>)"/>

      <g id="asdfadsfasdfasf" phx-update="append" transform="translate(<%= @x %>, <%= @y %>)">
        <%= for {{x, y}, tile} <- @tiles do %>
          <use id="t<%= x %>_<%= y %>" x="<%= x * 128 %>" y="<%= y * 128 %>" xlink:href="#<%= tile %>" />
        <% end %>
      </g>
    </svg>
    """
  end

  defp tile_at(world, position) do
    case Mina.World.reveal_at(world, position) do
      {:mine, _} -> "mine"
      {{:proximity, 0}, _} -> "empty"
      {{:proximity, n}, _} -> "#{n}"
    end
  end
end
