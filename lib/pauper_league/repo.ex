defmodule PauperLeague.Repo do
  use Ecto.Repo,
    otp_app: :pauper_league,
    adapter: Ecto.Adapters.Postgres
end
