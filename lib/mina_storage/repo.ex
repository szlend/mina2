defmodule MinaStorage.Repo do
  use Ecto.Repo,
    otp_app: :mina,
    adapter: Ecto.Adapters.Postgres
end
