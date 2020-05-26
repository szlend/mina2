defmodule Mina.MinaHelpers do
  @moduledoc """
  Provides helpers for working with the Mina application.
  """

  alias Mina.Partition

  @doc """
  Reset the application back to initial state.
  """
  @spec reset_state() :: :ok
  def reset_state() do
    # Reset Supervisor and Registry state
    :ok = Partition.Supervisor.stop()
    :ok = Partition.Registry.stop()

    # Make sure the processes are back up before running the next test
    wait_process(Partition.Supervisor)
    wait_process(Partition.Registry)

    :ok
  end

  @doc """
  Waits for a process with a `name` to become available until `timeout`.
  """
  def wait_process(name, timeout \\ 1000) do
    waiter = fn ->
      Stream.repeatedly(fn -> Process.whereis(name) end)
      |> Stream.take_while(&is_nil/1)
      |> Stream.run()
    end

    waiter
    |> Task.async()
    |> Task.await(timeout)
  end
end
