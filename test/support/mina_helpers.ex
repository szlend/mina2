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
    for pid <- Partition.Supervisor.children() do
      :ok = Partition.Supervisor.terminate_child(pid)
    end

    :ok
  end
end
