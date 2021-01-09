defmodule Mina.Debug do
  @moduledoc false

  def disconnect do
    :ok = Supervisor.terminate_child(Mina.Supervisor, Mina.ClusterSupervisor)
    Enum.each(nodes(), fn node -> Node.disconnect(node) end)
    :ok
  end

  def connect do
    {:ok, _child} = Supervisor.restart_child(Mina.Supervisor, Mina.ClusterSupervisor)
    :ok
  end

  defp nodes do
    Enum.filter(Node.list(), &String.starts_with?(to_string(&1), "mina@mina"))
  end
end
