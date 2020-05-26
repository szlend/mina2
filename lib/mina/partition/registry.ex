defmodule Mina.Partition.Registry do
  @moduledoc """
  Distributed process registry used for tracking partition servers.
  """

  @doc """
  Starts the registry supervisor. See `Horde.Registry.start_link/1`.
  """
  @spec start_link(Keyword.t()) :: {:ok, pid} | {:error, any}
  def start_link(opts) do
    Horde.Registry.start_link(opts)
  end

  @doc """
  Returns a supervisor child spec for the partition registry.
  """
  @spec child_spec(Keyword.t()) :: Supervisor.child_spec()
  def child_spec(opts) do
    opts = Keyword.merge([keys: :unique, members: :auto, name: __MODULE__], opts)
    Horde.Registry.child_spec(opts)
  end

  @doc """
  Stops the `registry` supervisor with `reason` and `timeout`.
  """
  @spec stop(Supervisor.supervisor(), any, :infinity | non_neg_integer) :: :ok
  def stop(registry \\ __MODULE__, reason \\ :normal, timeout \\ 5000) do
    Horde.Registry.stop(registry, reason, timeout)
  end

  # The `:via` tuple callbacks
  @compile {:inline, whereis_name: 1}
  @doc false
  def whereis_name(name), do: Horde.Registry.whereis_name({__MODULE__, name})

  @compile {:inline, register_name: 2}
  @doc false
  def register_name(name, pid), do: Horde.Registry.register_name({__MODULE__, name}, pid)

  @compile {:inline, unregister_name: 1}
  @doc false
  def unregister_name(name), do: Horde.Registry.unregister_name({__MODULE__, name})
end
