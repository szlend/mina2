defmodule Mina.ClusterCase do
  @moduledoc """
  This module defines the setup for tests requiring
  work with multiple nodes.
  """

  use ExUnit.CaseTemplate
  alias Mina.{ClusterHelpers, MinaHelpers}

  using do
    quote do
      import Mina.ClusterHelpers, only: [start_nodes: 2]
      import Mina.ClusterCase
    end
  end

  setup_all do
    ClusterHelpers.start()
    :ok
  end

  @doc """
  A helper that resets the Mina application back to initial state within a cluster.
  """
  def reset_state do
    MinaHelpers.reset_cluster_state()
    MinaHelpers.reset_state()
  end
end
