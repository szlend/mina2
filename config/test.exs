import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :mina, MinaStorage.Repo,
  username: "postgres",
  database: "mina_test#{System.get_env("MIX_TEST_PARTITION")}",
  hostname: "postgres",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mina, MinaWeb.Endpoint,
  http: [port: 4002],
  server: false

# Increase the number of restarts to prevent the application
# from shutting down between tests
config :mina, :partition, persistent: false, timeout: :infinity
config :mina, :partition_registry, delta_crdt_options: [sync_interval: 50]
config :mina, :partition_supervisor, delta_crdt_options: [sync_interval: 50]

# Print only warnings and errors during test
config :logger, level: :warning
