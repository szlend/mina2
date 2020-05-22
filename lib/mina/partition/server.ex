defmodule Mina.Partition.Server do
  @moduledoc """
  The server responsible for managing the state of a `Mina.Partition`.
  """

  use GenServer
  alias Mina.{Board, Partition}

  @type start_opt :: {:partition, Partition.t()}
  @type via :: {:via, Registry, {Partition.Registry, Partition.id()}}

  @doc """
  Starts a new `Partition.Server` with the given `opts`.
  ## Options

  The accepted options are:

  * `:spec` - the `Mina.Partition.Spec` to base the server partition on.
  * `:position` - the partition position on the board.
  * `:name` - the name of the server process.
  """
  @spec start_link([start_opt]) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    {server_opts, opts} = Keyword.split(opts, [:name])
    GenServer.start_link(__MODULE__, opts, server_opts)
  end

  @doc """
  Get the server via-tuple for a given partition `spec` and `position`.
  """
  @spec via_position(Partition.Spec.t(), Board.position()) :: via
  def via_position(spec, position) do
    {:via, Registry, {Partition.Registry, Partition.id_at(spec, position)}}
  end

  @doc """
  Reveals tiles on a Partition.Server `pid`, starting from `position`.
  Returns a map of new `reveals`.
  """
  @spec reveal(GenServer.server(), Board.position()) :: Board.reveals()
  def reveal(server, position) do
    GenServer.call(server, {:reveal, position})
  end

  @impl true
  def init(opts) do
    spec = Keyword.fetch!(opts, :spec)
    position = Keyword.fetch!(opts, :position)
    partition = Partition.build(spec, position)

    {:ok, partition}
  end

  @impl true
  def handle_call({:reveal, position}, _from, partition) do
    {partition, reveals, _border_positions} = Partition.reveal(partition, position)
    {:reply, reveals, partition}
  end
end
