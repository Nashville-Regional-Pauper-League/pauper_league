defmodule PauperLeague.Repo.Migrations.AddAccessTokens do
  use Ecto.Migration

  def change do
    create table("access_tokens") do
      add :auth_token, :text
      add :refresh_token, :text
      add :expires_at, :utc_datetime
      add :current, :boolean
    end
  end
end
