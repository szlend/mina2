defmodule Mina.ClusterSupervisor do
  @moduledoc """
  Supervisor for managing cluster connections.
  """

  use Supervisor, restart: :transient

  defdelegate init(args), to: Cluster.Supervisor

  def start_link([config]), do: start_link([config, []])

  def start_link([config, opts]) do
    opts = Keyword.merge(opts, name: __MODULE__)
    Cluster.Supervisor.start_link([config, opts])
  end
end
