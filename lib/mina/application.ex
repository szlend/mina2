defmodule Mina.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies, [])

    children = [
      # Start cluster supervisor
      {Mina.ClusterSupervisor, [topologies]},
      # Start the Ecto repository
      MinaStorage.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Mina.PubSub},
      # Start the Partition registry
      {Mina.Partition.Registry, Application.get_env(:mina, :partition_registry, [])},
      # Start the Partition supervisor
      {Mina.Partition.Supervisor, Application.get_env(:mina, :partition_supervisor, [])},
      # Start the Telemetry supervisor
      MinaWeb.Telemetry,
      # Start the Endpoint (http/https)
      MinaWeb.Endpoint
      # Start a worker by calling: Mina.Worker.start_link(arg)
      # {Mina.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mina.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    MinaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
