defmodule Mina.Partition.TileSerializer do
  @moduledoc """
  A Partition serializer for serializing tiles in a compact string format.
  """

  @behaviour Mina.Partition.Serializer

  alias Mina.Partition

  @doc """
  Encode partition tiles.
  """
  @impl true
  @spec encode(Partition.t()) :: {:ok, String.t()}
  def encode(partition) do
    size = partition.world.partition_size
    reveals = partition.reveals
    data = for y <- 0..(size - 1), x <- 0..(size - 1), do: encode_tile(reveals[{x, y}])
    {:ok, to_string(data)}
  end

  @doc """
  Decode partition tiles.
  """
  @impl true
  @spec decode(Partition.t(), String.t()) :: {:ok, Partition.t()} | {:error, term}
  def decode(partition, data) do
    with {:ok, reveals} <- do_decode(data, 0, 0, partition.world.partition_size) do
      {:ok, %{partition | reveals: Map.new(reveals)}}
    end
  end

  # update x and y at the end of a row
  defp do_decode(data, x, y, size) when x == size do
    do_decode(data, 0, y + 1, size)
  end

  # stop if the end was reached
  defp do_decode(<<>>, _x, y, size) when y == size do
    {:ok, []}
  end

  # return an error if too many rows
  defp do_decode(_data, _x, y, size) when y == size do
    {:error, :data_too_long}
  end

  # return an error if not enough rows
  defp do_decode(<<>>, _x, _y, _size) do
    {:error, :data_too_short}
  end

  # recursively decode each character
  defp do_decode(<<char::size(8), rest::binary>>, x, y, size) do
    with {:ok, tile} <- decode_tile(char),
         {:ok, tiles} <- do_decode(rest, x + 1, y, size) do
      {:ok, [{{x, y}, tile} | tiles]}
    else
      :skip -> do_decode(rest, x + 1, y, size)
      {:error, reason} -> {:error, reason}
    end
  end

  defp encode_tile(nil), do: ?u
  defp encode_tile(:mine), do: ?m
  defp encode_tile({:proximity, n}), do: ?0 + n

  defp decode_tile(?u), do: :skip
  defp decode_tile(?m), do: {:ok, :mine}
  defp decode_tile(n) when n in ?0..?8, do: {:ok, {:proximity, n - ?0}}
  defp decode_tile(char), do: {:error, {:invalid_char, to_string([char])}}
end
