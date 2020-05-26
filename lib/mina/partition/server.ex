defmodule Mina.Partition.Server do
  @moduledoc """
  The server responsible for managing the state of a `Mina.Partition`.
  """

  use GenServer
  alias Mina.{Board, Partition}

  @type start_opt ::
          {:spec, Partition.Spec.t()}
          | {:position, Board.position()}
          | {:name, GenServer.name()}

  @type via :: {:via, Partition.Registry, Partition.id()}

  @doc """
  Starts a new `Partition.Server` with the given `opts`.

  ## Options

  The accepted options are:

  * `:spec` - the `Mina.Partition.Spec` to base the server partition on.
  * `:position` - the partition position on the board.
  * `:name` - the name of the server process.
  """
  @spec start_link([start_opt]) :: {:ok, pid} | {:error, any}
  def start_link(opts) do
    {server_opts, opts} = Keyword.split(opts, [:name])
    GenServer.start_link(__MODULE__, opts, server_opts)
  end

  @doc """
  Get the server via-tuple for a given partition `spec` and `position`.
  """
  @spec via_position(Partition.Spec.t(), Board.position()) :: via
  def via_position(spec, position) do
    {:via, Partition.Registry, Partition.id_at(spec, position)}
  end

  @doc """
  Reveals tiles on a Partition `server` at `positions`. Returns a map of new `reveals`.
  """
  @spec reveal(GenServer.server(), [Board.position()]) ::
          {Board.reveals(), %{Partition.id() => [Board.position()]}}
  def reveal(server, positions) do
    GenServer.call(server, {:reveal, positions})
  end

  def child_spec(opts) do
    {id, opts} = Keyword.pop(opts, :id, __MODULE__)
    %{id: id, restart: :transient, start: {__MODULE__, :start_link, [opts]}}
  end

  @impl true
  def init(opts) do
    spec = Keyword.fetch!(opts, :spec)
    position = Keyword.fetch!(opts, :position)
    partition = Partition.build(spec, position)

    {:ok, partition}
  end

  @impl true
  def handle_call({:reveal, positions}, _from, partition) do
    {partition, reveals, border_positions} = reveal_positions(positions, partition, %{}, %{})
    {:reply, {reveals, border_positions}, partition}
  end

  defp reveal_positions([], partition, reveals, border_positions) do
    {partition, reveals, border_positions}
  end

  defp reveal_positions([position | positions], partition, reveals, border_positions) do
    {partition, new_reveals, new_border_positions} = Partition.reveal(partition, position)

    reveal_positions(
      positions,
      partition,
      Map.merge(reveals, new_reveals),
      Map.merge(border_positions, new_border_positions)
    )
  end
end
