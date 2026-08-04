defmodule PauperLeague.Repo.Migrations.AddEventFields do
  use Ecto.Migration

  def change do
    alter table(:events, prefix: :raw) do
      add :description, :text
      add :title, :text
      add :eventlink_status, :text
    end
  end
end
