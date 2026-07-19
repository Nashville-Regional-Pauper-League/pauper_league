defmodule PauperLeague.Repo.Migrations.AddEvents do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :eventlink_id, :text
      add :format, :text
      add :event_date, :date
      add :store_id, references(:stores)
    end

    create unique_index(:events, [:eventlink_id])
  end
end
