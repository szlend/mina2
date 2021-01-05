defmodule Mina.ClusterCase do
  @moduledoc """
  This module defines the setup for tests requiring
  work with multiple nodes.
  """

  use ExUnit.CaseTemplate
  alias Mina.ClusterHelpers

  using do
    quote do
      use Mina.DataCase, async: false
      import Mina.ClusterHelpers, only: [start_nodes: 2]
      import Mina.ClusterCase
    end
  end

  setup_all do
    ClusterHelpers.start()
    on_exit(fn -> ClusterHelpers.stop() end)
  end

  setup do
    on_exit(fn -> ClusterHelpers.stop_nodes(Node.list() -- [Node.self()]) end)
  end
end
