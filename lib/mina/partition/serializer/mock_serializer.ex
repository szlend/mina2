defmodule Mina.Partition.MockSerializer do
  @moduledoc false

  @behaviour Mina.Partition.Serializer

  def encode(_partition), do: {:ok, "mock"}
  def decode(partition, _data), do: {:ok, partition}
end
