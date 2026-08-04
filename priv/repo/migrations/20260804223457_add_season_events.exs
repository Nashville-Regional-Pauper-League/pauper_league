defmodule PauperLeague.Repo.Migrations.AddSeasonEvents do
  use Ecto.Migration

  def change do
    create table(:seasons) do
      add :season_number, :integer
      add :start_date, :date
      add :end_date, :date
      add :active, :boolean
    end

    alter table(:events) do
      add :playoff_rounds, :integer
      add :games_to_win, :integer
      add :season_id, references(:seasons)
    end

    create table(:event_rounds) do
      add :event_id, references(:events)
      add :eventlink_id, :text
      add :round_number, :integer
      add :is_playoff, :boolean
      add :is_final_round, :boolean
    end

    create table(:event_teams) do
      add :event_id, references(:events)
    end

    create table(:event_team_players) do
      add :event_team_id, references(:event_teams)
      add :player_id, references(:players)
    end

    create table(:event_round_matches) do
      add :round_id, references(:event_rounds)
      add :table_number, :integer
      add :is_bye, :boolean
      add :match_id, :string
    end

    create table(:match_results) do
      add :event_round_match_id, references(:event_round_matches)
      add :event_team_id, references(:event_teams)
      add :wins, :integer
      add :draws, :integer
      add :isBye, :boolean
      add :losses, :integer
    end
  end
end
