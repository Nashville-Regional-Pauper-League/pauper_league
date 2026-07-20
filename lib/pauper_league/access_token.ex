defmodule PauperLeague.AccessToken do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  schema "access_tokens" do
    field :auth_token, :string
    field :refresh_token, :string
    field :expires_at, :utc_datetime
    field :current, :boolean

    belongs_to :store, PauperLeague.Stores.Store
  end

  def create(params) do
    store_id = params.store_id

    current =
      from(at in __MODULE__,
        where: at.current and at.store_id == ^store_id
      )
      |> PauperLeague.Repo.all()

    current
    |> Enum.each(fn at -> at |> change(%{current: false}) |> PauperLeague.Repo.update() end)

    params = Map.merge(params, %{current: true})

    %__MODULE__{}
    |> change(params)
    |> PauperLeague.Repo.insert()
  end

  def get_current(store_id) do
    __MODULE__
    |> where([at], at.current and at.store_id == ^store_id)
    |> PauperLeague.Repo.one()
  end
end
