defmodule CounterWeb.Repo do
  use Ecto.Repo,
    otp_app: :counter_web,
    adapter: Ecto.Adapters.Postgres
end
