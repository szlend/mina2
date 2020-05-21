defmodule Mina.Partition.Supervisor do
  @moduledoc """
  The dynamic supervisor for `Mina.Partition.Server`.
  """

  use DynamicSupervisor
  alias Mina.{Board, Partition}

  @doc """
  Start the partition supervisor. Accepts no additional options.
  """
  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts \\ []) do
    DynamicSupervisor.start_link(__MODULE__, opts)
  end

  @doc """
  Start a partition server under this supervisor
  """
  @spec start_child(Supervisor.supervisor(), Partition.Spec.t(), Board.position()) ::
          :ignore | {:error, any} | {:ok, pid} | {:ok, pid, any}
  def start_child(supervisor, spec, position) do
    name = Partition.Server.via_spec_position(spec, position)
    child_spec = {Partition.Server, spec: spec, position: position, name: name}
    DynamicSupervisor.start_child(supervisor, child_spec)
  end

  @spec ensure_child(Supervisor.supervisor(), Partition.Spec.t(), Board.position()) ::
          :ignore | {:error, any} | {:ok, any} | {:ok, pid, any}
  def ensure_child(supervisor, spec, position) do
    with {:error, {:already_started, pid}} <- start_child(supervisor, spec, position) do
      {:ok, pid}
    end
  end

  @impl true
  def init(_opts) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
