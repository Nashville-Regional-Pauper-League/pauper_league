defmodule PauperLeague.Repo.Migrations.AddRawEvents do
  use Ecto.Migration

  def change do
    execute "CREATE SCHEMA raw;"

    create table(:events, prefix: :raw) do
      add :eventlink_id, :text
      add :format, :text
      add :event_date, :date
      add :internal_state, :text
      add :store_id, references(:stores, prefix: :public)

      timestamps()
    end

    create unique_index(:events, [:eventlink_id], prefix: :raw)

    create table(:event_data, prefix: :raw) do
      add :event_id, references(:events, prefix: :raw)
      add :data, :jsonb
      timestamps()
    end
  end
end
