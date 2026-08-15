defmodule PauperLeague.Repo.Migrations.EditMatchResults do
  use Ecto.Migration

  def change do
    rename table(:match_results), :isBye, to: :is_bye
  end
end
