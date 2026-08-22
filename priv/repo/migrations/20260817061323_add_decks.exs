defmodule PauperLeague.Repo.Migrations.AddDecks do
  use Ecto.Migration

  def change do
    create table(:deck_archetypes) do
      add :name, :text
    end

    alter table(:event_teams) do
      add :deck_archetype_id, references(:deck_archetypes)
    end
  end
end
