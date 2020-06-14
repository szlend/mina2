defmodule MinaWeb.GridLive do
  @moduledoc """
  Live game
  """

  use Phoenix.LiveComponent

  @impl true
  def mount(socket) do
    {:ok, socket, temporary_assigns: [tiles: []]}
  end

  def update(assigns, socket) do
    if assigns.tiles == [] do
      {:ok, socket}
    else
      {:ok, assign(socket, :tiles, assigns.tiles)}
    end
  end

  @impl true
  def render(assigns) do
    ~L"""
    <svg width="1280" height="960" viewBox="0 0 5120 3840" style="overflow: none">
      <rect width="100%" height="100%" fill="url(#bg)" />
      <g id="asdfadsfasdfasf" phx-update="append" class="kek">
        <%= for {{x, y}, tile} <- @tiles do %>
          <use id="t<%= x %>-<%= y %>" x="<%= x * 128 %>" y="<%= y * 128 %>" xlink:href="#<%= tile %>" />
        <% end %>
      </g>
    </svg>
    """
  end
end
