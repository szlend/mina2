defmodule Mina.Partition.Serializer do
  @moduledoc """
  The behaviour describing encoding and decoding of partitions.
  """
  alias Mina.Partition

  @callback encode(Partition.t()) :: {:ok, term} | {:error, term}
  @callback decode(Partition.t(), term) :: {:ok, Partition.t()} | {:error, term}
end
