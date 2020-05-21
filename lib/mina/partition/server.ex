defmodule Mina.Partition.Server do
  @moduledoc """
  The server responsible for managing the state of a `Mina.Partition`.
  """

  use GenServer
  alias Mina.{Board, Partition}

  @type start_opt :: {:partition, Partition.t()}

  @doc """
  Starts a new `Partition.Server` with the given `opts`.
  ## Options

  The accepted options are:

  * `:partition` - the `Mina.Partition` to base the server on.
  """
  @spec start_link([start_opt]) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @doc """
  Reveals tiles on a Partition.Server `pid`, starting from `position`.
  Returns a map of new `reveals`.
  """
  @spec reveal(pid, Board.position()) :: Board.reveals()
  def reveal(pid, position) do
    GenServer.call(pid, {:reveal, position})
  end

  @impl true
  def init(opts) do
    {:ok, Keyword.fetch!(opts, :partition)}
  end

  @impl true
  def handle_call({:reveal, position}, _from, partition) do
    {partition, reveals, _border_positions} = Partition.reveal(partition, position)
    {:reply, reveals, partition}
  end
end
