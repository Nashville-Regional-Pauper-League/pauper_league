defmodule PauperLeague.Repo.Migrations.AddStage do
  use Ecto.Migration

  def change do
    execute "CREATE SCHEMA stage;"

    create table(:events, prefix: :stage) do
      add :eventlink_id, :text
      add :format, :text
      add :event_date, :date
      add :store_id, references(:stores, prefix: :public)
      add :playoff_rounds, :integer
      add :games_to_win, :integer
      add :season_id, references(:seasons, prefix: :public)
      timestamps()
    end

    create unique_index(:events, [:eventlink_id], prefix: :stage)

    create table(:event_rounds, prefix: :stage) do
      add :event_id, references(:events, prefix: :stage)
      add :eventlink_id, :text
      add :round_number, :integer
      add :is_playoff, :boolean
      add :is_final_round, :boolean
    end

    create table(:event_teams, prefix: :stage) do
      add :event_id, references(:events, prefix: :stage)
      add :team_id, :text
      add :deck_archetype_id, references(:deck_archetypes, prefix: :public)
    end

    create table(:event_team_players, prefix: :stage) do
      add :event_team_id, references(:event_teams, prefix: :stage)
      add :player_id, references(:players, prefix: :public)
    end

    create table(:event_round_matches, prefix: :stage) do
      add :round_id, references(:event_rounds, prefix: :stage)
      add :table_number, :integer
      add :is_bye, :boolean
      add :match_id, :string
    end

    create table(:match_results, prefix: :stage) do
      add :event_round_match_id, references(:event_round_matches, prefix: :stage)
      add :event_team_id, references(:event_teams, prefix: :stage)
      add :wins, :integer
      add :draws, :integer
      add :is_bye, :boolean
      add :losses, :integer
    end
  end
end
