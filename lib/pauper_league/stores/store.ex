defmodule PauperLeague.Stores.Store do
  use Ecto.Schema

  schema "stores" do
    field :eventlink_id, :string
    field :name, :string
    field :address_line_1, :string
    field :address_line_2, :string
    field :address_city, :string
    field :address_state, :string
    field :address_zip_code, :string
  end
end
