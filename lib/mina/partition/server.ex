defmodule Mina.Partition.Server do
  @moduledoc """
  The server responsible for managing the state of a `Mina.Partition`.
  """

  use GenServer
  alias Mina.{Partition, World}

  @type start_opt ::
          {:world, World.t()}
          | {:position, World.position()}
          | {:name, GenServer.name()}

  @type via :: {:via, Partition.Registry, Partition.id()}

  @doc """
  Starts a new `Partition.Server` with the given `opts`.

  ## Options

  The accepted options are:

  * `:world` - the `Mina.World` to base the server partition on.
  * `:position` - the partition position on the world.
  * `:name` - the name of the server process.
  """
  @spec start_link([start_opt]) :: {:ok, pid} | {:error, any}
  def start_link(opts) do
    {server_opts, opts} = Keyword.split(opts, [:name])
    GenServer.start_link(__MODULE__, opts, server_opts)
  end

  @doc """
  Returns a supervisor child spec for the partition server.
  """
  @spec child_spec(Keyword.t()) :: Supervisor.child_spec()
  def child_spec(opts) do
    {id, opts} = Keyword.pop(opts, :id, __MODULE__)
    %{id: id, restart: :transient, start: {__MODULE__, :start_link, [opts]}}
  end

  @doc """
  Get the server via-tuple for a given `world` and `position`.
  """
  @spec via_position(World.t(), World.position()) :: via
  def via_position(world, position) do
    {:via, Partition.Registry, Partition.id_at(world, position)}
  end

  @doc """
  Reveals tiles on a Partition `server` at `positions`. Returns a map of new `reveals`.
  """
  @spec reveal(GenServer.server(), [World.position()]) ::
          {World.reveals(), %{Partition.id() => [World.position()]}}
  def reveal(server, positions) do
    GenServer.call(server, {:reveal, positions})
  end

  @doc """
  Encode the `partition` with the given `serializer` implementing `Mina.Partition.Serializer`.
  """
  @spec encode(GenServer.server(), atom) :: {:ok, term} | {:error, term}
  def encode(server, serializer) do
    GenServer.call(server, {:encode, serializer})
  end

  @impl true
  def init(opts) do
    world = Keyword.fetch!(opts, :world)
    position = Keyword.fetch!(opts, :position)
    partition = Partition.build(world, position)

    {:ok, partition}
  end

  @impl true
  def handle_call({:reveal, positions}, _from, partition) do
    {partition, reveals, border_positions} = reveal_positions(positions, partition, %{}, %{})
    {:reply, {reveals, border_positions}, partition}
  end

  def handle_call({:encode, serializer}, _from, partition) do
    {:reply, Partition.encode(serializer, partition), partition}
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
