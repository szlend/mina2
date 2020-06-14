defmodule MinaWeb.PageLive do
  @moduledoc """
  Live search example
  """

  use MinaWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~L"""
    <h1>Welcom to gaem</h1>

    Go to /game/:name
    """
  end
end
