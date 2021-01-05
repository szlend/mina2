defmodule Mina.ClusterHelpers do
  @moduledoc """
  Provides helpers for working with local child clusters.
  """

  @doc """
  Starts the current node as a distributed node.
  """
  @spec start() :: {:ok, :undefined | pid} | {:ok, :undefined | pid, any} | {:error, any}
  def start do
    :net_kernel.start([:"manager@127.0.0.1"])
  end

  @spec stop() :: :ok | {:error, :not_allowed | :not_found}
  def stop do
    :net_kernel.stop()
  end

  @doc """
  Starts an `amount` number of child nodes named by `prefix` and index number.
  Returns a list of node names.
  """
  @spec start_nodes(String.t(), pos_integer()) :: [node]
  def start_nodes(prefix, amount) do
    Enum.map(1..amount, fn idx ->
      args = '-setcookie "#{:erlang.get_cookie()}"'
      {:ok, node} = :slave.start_link('127.0.0.1', :"#{prefix}#{idx}", args)
      node
    end)
    |> Task.async_stream(fn node ->
      # Configure path and start Mix
      true = :erpc.call(node, :code, :set_path, [:code.get_path()])
      {:ok, _} = :erpc.call(node, Application, :ensure_all_started, [:mix])
      :ok = :erpc.call(node, Mix, :env, [Mix.env()])

      mix_args = [
        "app.start",
        # returns an error when the application fails to start
        "--permanent",
        "--no-archives-check",
        # skips recompilation
        "--no-compile",
        # prevents a race condition when loading deps into path
        "--no-load-deps",
        "--no-deps-check",
        "--no-elixir-version-check",
        "--no-validate-compile-env"
      ]

      # Start the application
      :ok = :erpc.call(node, Mix.CLI, :main, [mix_args])

      node
    end)
    |> Enum.map(fn {:ok, node} -> node end)
  end

  @doc """
  Stops a list of child `nodes`.
  """
  @spec stop_nodes([node]) :: :ok
  def stop_nodes(nodes) do
    Enum.each(nodes, &:slave.stop/1)
  end
end
