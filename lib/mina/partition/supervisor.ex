defmodule Mina.Partition.Supervisor do
  @moduledoc """
  A distributed dynamic supervisor for `Mina.Partition.Server`.
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
    {name, opts} = Keyword.pop(opts, :name, __MODULE__)
    opts = Keyword.merge([strategy: :one_for_one, members: :auto], opts)
    Horde.DynamicSupervisor.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Start a partition server under a `supervisor`.
  """
  @spec start_partition(Supervisor.supervisor(), Partition.Spec.t(), Board.position()) ::
          {:ok, pid} | {:error, any}
  def start_partition(supervisor \\ __MODULE__, spec, position) do
    id = Partition.id_at(spec, position)
    name = Partition.Server.via_position(spec, position)
    child_spec = {Partition.Server, spec: spec, position: position, id: id, name: name}
    Horde.DynamicSupervisor.start_child(supervisor, child_spec)
  end

  @doc """
  Ensure a partition server is running under a `supervisor`. This will start a new server
  if one is not yet running.
  """
  @spec ensure_partition(Supervisor.supervisor(), Partition.Spec.t(), Board.position()) ::
          {:ok, pid} | {:error, any}
  def ensure_partition(supervisor \\ __MODULE__, spec, position) do
    with {:error, {:already_started, pid}} <- start_partition(supervisor, spec, position) do
      {:ok, pid}
    end
  end

  @doc """
  Terminate a partition server with `pid` running under `supervisor`.
  """
  @spec terminate_child(Supervisor.supervisor(), pid) ::
          :ok | {:error, :not_found | {:node_dead_or_shutting_down, binary}}
  def terminate_child(supervisor \\ __MODULE__, pid) do
    Horde.DynamicSupervisor.terminate_child(supervisor, pid)
  end

  @doc """
  Return a list of partition server pids running under `supervisor`.
  """
  @spec children(Supervisor.supervisor()) :: [pid]
  def children(supervisor \\ __MODULE__) do
    supervisor
    |> Horde.DynamicSupervisor.which_children()
    |> Enum.map(fn {:undefined, pid, _type, _modules} -> pid end)
  end

  @doc """
  Stops the `supervisor` with `reason` and `timeout`.
  """
  def stop(supervisor \\ __MODULE__, reason \\ :normal, timeout \\ 5000) do
    Horde.DynamicSupervisor.stop(supervisor, reason, timeout)
  end

  @impl true
  def init(opts) do
    Horde.DynamicSupervisor.init(opts)
  end
end
