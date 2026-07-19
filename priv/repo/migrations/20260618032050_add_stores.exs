defmodule PauperLeague.Repo.Migrations.AddStores do
  use Ecto.Migration

  def change do
    create table("stores") do
      add :eventlink_id, :text
      add :name, :text
      add :address_line_1, :text
      add :address_line_2, :text
      add :address_city, :text
      add :address_state, :text
      add :address_zip_code, :text
    end
  end
end
