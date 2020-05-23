defmodule Mina.Partition.Supervisor do
  @moduledoc """
  The dynamic supervisor for `Mina.Partition.Server`.
  """

  use Horde.DynamicSupervisor
  alias Mina.{Board, Partition}

  @type start_opt :: {:name, Supervisor.name()}

  @doc """
  Start the partition supervisor with the given `opts`.

  ## Options

  The accepted options are:

  * `:name` - the name of the supervisor process.
  """
  @spec start_link([start_opt]) :: {:ok, pid} | {:error, any}
  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop!(opts, :name)
    Horde.DynamicSupervisor.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Start a partition server under this supervisor
  """
  @spec start_child(Supervisor.supervisor(), Partition.Spec.t(), Board.position()) ::
          {:ok, pid} | {:error, any}
  def start_child(supervisor, spec, position) do
    id = Partition.id_at(spec, position)
    name = Partition.Server.via_position(spec, position)
    child_spec = {Partition.Server, spec: spec, position: position, id: id, name: name}
    Horde.DynamicSupervisor.start_child(supervisor, child_spec)
  end

  @spec ensure_child(Supervisor.supervisor(), Partition.Spec.t(), Board.position()) ::
          {:ok, pid} | {:error, any}
  def ensure_child(supervisor, spec, position) do
    with {:error, {:already_started, pid}} <- start_child(supervisor, spec, position) do
      {:ok, pid}
    end
  end

  @impl true
  def init(_opts) do
    Horde.DynamicSupervisor.init(strategy: :one_for_one)
  end
end
