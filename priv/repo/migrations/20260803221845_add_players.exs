defmodule PauperLeague.Repo.Migrations.AddPlayers do
  use Ecto.Migration

  def change do
    create table(:players) do
      add :persona_id, :text
      add :first_name, :text
      add :last_name, :text
      add :display_name, :text
      timestamps()
    end

    create unique_index(:players, [:persona_id])
  end
end
