defmodule PauperLeague.Repo.Migrations.AssocTokensToStores do
  use Ecto.Migration

  def change do
    alter table(:access_tokens) do
      add :store_id, references(:stores)
    end
  end
end
