defmodule Mina.Partition.Server do
  @moduledoc """
  The server responsible for managing the state of a `Mina.Partition`.
  """

  use GenServer
  alias Mina.{Partition, World}

  @type start_opt ::
          {:world, World.t()}
          | {:position, World.position()}
          | {:persistent, boolean}
          | {:timeout, pos_integer | :infinity}
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
  Attempts to flag tiles on a Partition `server` at `position`. Returns `{:ok, new_reveals}` if
  successful, otherwise `{:error, reason}`.
  """
  @spec flag(GenServer.server(), World.position()) :: {:ok, World.reveals()} | {:error, any}
  def flag(server, position) do
    GenServer.call(server, {:flag, position})
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
    Process.flag(:trap_exit, true)

    world = Keyword.fetch!(opts, :world)
    position = Keyword.fetch!(opts, :position)
    timeout = Keyword.get(opts, :timeout, :infinity)

    state = %{
      partition: Partition.build(world, position),
      persistent: Keyword.get(opts, :persistent, false),
      timeout: timeout,
      timer: reset_timer(timeout)
    }

    {:ok, state, {:continue, :load_state}}
  end

  @impl true
  def handle_continue(:load_state, %{persistent: true} = state) do
    case Mina.load_partition(state.partition) do
      {:ok, partition} -> {:noreply, %{state | partition: partition}}
      {:error, :not_found} -> {:noreply, state}
    end
  end

  def handle_continue(:load_state, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call({:reveal, positions}, _from, %{partition: partition} = state) do
    timer = reset_timer(state.timer, state.timeout)
    {partition, reveals, border_positions} = reveal_positions(positions, partition, %{}, %{})
    {:reply, {reveals, border_positions}, %{state | partition: partition, timer: timer}}
  end

  def handle_call({:flag, position}, _from, %{partition: partition} = state) do
    timer = reset_timer(state.timer, state.timeout)

    case Partition.flag(partition, position) do
      {:ok, {partition, reveals}} ->
        {:reply, {:ok, reveals}, %{state | partition: partition, timer: timer}}

      {:error, reason} ->
        {:reply, {:error, reason}, %{state | timer: timer}}
    end
  end

  def handle_call({:encode, serializer}, _from, %{partition: partition} = state) do
    timer = reset_timer(state.timer, state.timeout)
    {:reply, Partition.encode(serializer, partition), %{state | timer: timer}}
  end

  @impl true
  def handle_info(:shutdown, state) do
    {:stop, :normal, state}
  end

  @impl true
  def terminate(:normal, %{persistent: true, partition: partition}) do
    :ok = Mina.save_partition(partition)
  end

  def terminate(_reason, _state), do: nil

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

  defp reset_timer(timer \\ nil, timeout)

  defp reset_timer(_timer, :infinity), do: nil

  defp reset_timer(nil, timeout) do
    {:ok, timer} = :timer.send_after(timeout, :shutdown)
    timer
  end

  defp reset_timer(timer, timeout) do
    {:ok, :cancel} = :timer.cancel(timer)
    reset_timer(timeout)
  end
end
