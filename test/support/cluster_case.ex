defmodule Mina.ClusterCase do
  @moduledoc """
  This module defines the setup for tests requiring
  work with multiple nodes.
  """

  use ExUnit.CaseTemplate
  alias Mina.ClusterHelpers

  using do
    quote do
      import Mina.ClusterHelpers, only: [start_nodes: 2]
      import Mina.ClusterCase
    end
  end

  setup_all do
    ClusterHelpers.start()
    on_exit(fn -> ClusterHelpers.stop() end)
  end

  setup tags do
    if tags[:async], do: raise("ClusterCase cannot run in async mode")
    :ok = Application.stop(:mina)
    {:ok, _app} = Application.ensure_all_started(:mina)
    :ok
  end
end
