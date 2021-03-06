defmodule Mina.Partition.TileSerializer do
  @moduledoc """
  A Partition serializer for serializing tiles in a compact string format.
  """

  @behaviour Mina.Partition.Serializer

  alias Mina.{Partition, World}

  @doc """
  Encode partition tiles.
  """
  @impl true
  @spec encode(Partition.t()) :: {:ok, String.t()}
  def encode(partition) do
    size = partition.world.partition_size
    reveals = partition.reveals
    {from_x, from_y} = partition.position

    data =
      for y <- 0..(size - 1),
          x <- 0..(size - 1),
          do: encode_tile(reveals[{from_x + x, from_y + y}])

    {:ok, to_string(data)}
  end

  @doc """
  Decode partition tiles.
  """
  @impl true
  @spec decode(Partition.t(), String.t()) :: {:ok, Partition.t()} | {:error, term}
  def decode(partition, data) do
    {from_x, from_y} = partition.position

    with {:ok, reveals} <- do_decode(data, 0, 0, partition.world.partition_size) do
      reveals = for {{x, y}, tile} <- reveals, do: {{from_x + x, from_y + y}, tile}
      {:ok, %{partition | reveals: Map.new(reveals)}}
    end
  end

  @doc """
  Encode a single tile.
  """
  @spec encode_tile(World.tile()) :: pos_integer
  def encode_tile(nil), do: ?u
  def encode_tile(:mine), do: ?m
  def encode_tile(:flag), do: ?f
  def encode_tile({:proximity, n}), do: ?0 + n

  @doc """
  Decode a single tile.
  """
  @spec decode_tile(pos_integer) ::
          :skip | {:ok, World.tile()} | {:error, {:invalid_char, binary}}
  def decode_tile(?u), do: :skip
  def decode_tile(?m), do: {:ok, :mine}
  def decode_tile(?f), do: {:ok, :flag}
  def decode_tile(n) when n in ?0..?8, do: {:ok, {:proximity, n - ?0}}
  def decode_tile(char), do: {:error, {:invalid_char, to_string([char])}}

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
end
