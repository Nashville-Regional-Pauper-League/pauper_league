defmodule PauperLeague.Repo.Migrations.EditEvents do
  use Ecto.Migration

  def change do
    alter table(:events) do
      timestamps(default: DateTime.utc_now() |> DateTime.to_iso8601())
    end
  end
end
