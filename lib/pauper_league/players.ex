defmodule PauperLeague.Player do
  use Ecto.Schema

  schema "players" do
    field :persona_id, :string
    field :first_name, :string
    field :last_name, :string
    field :display_name, :string
    timestamps()
  end
end
