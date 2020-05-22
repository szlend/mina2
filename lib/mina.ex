defmodule Mina do
  @moduledoc """
  Mina multiplayer minesweeper domain logic.
  """

  alias Mina.{Board, Partition}

  @doc """
  Reveals tiles across partitions for `spec` at `position`. You can limit the `max_depth`
  to prevent infinite recursion with very easy difficulties. Returns a map of reveals.
  """
  @spec reveal_tile(Partition.Spec.t(), Board.position()) :: Board.reveals()
  def reveal_tile(spec, position, max_depth \\ :infinity) do
    depth = if max_depth == :infinity, do: -1, else: max_depth
    do_reveal_tile(spec, Partition.position(spec, position), [position], depth)
  end

  defp do_reveal_tile(_spec, _partition_position, _positions, 0), do: %{}

  defp do_reveal_tile(spec, partition_position, positions, depth) do
    {:ok, server} = get_partition(spec, partition_position)
    {reveals, border_positions} = Partition.Server.reveal(server, positions)

    Enum.reduce(border_positions, reveals, fn {partition_position, positions}, reveals ->
      Map.merge(reveals, do_reveal_tile(spec, partition_position, positions, depth - 1))
    end)
  end

  defp get_partition(spec, position) do
    Partition.Supervisor.ensure_child(Partition.Supervisor, spec, position)
  end
end
