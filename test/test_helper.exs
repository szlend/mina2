Application.load(:mina)

for app <- Application.spec(:mina, :applications) do
  Application.ensure_all_started(app)
end

ExUnit.start()
# Ecto.Adapters.SQL.Sandbox.mode(MinaStorage.Repo, :manual)
