defmodule PauperLeague.Repo.Migrations.AddRawEventRounds do
  use Ecto.Migration

  def change do
    create table(:event_round, prefix: :raw) do
      add :event_id, references(:events, prefix: :raw)
      add :round_no, :integer
      add :data, :jsonb
      timestamps()
    end
  end
end
