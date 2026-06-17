defmodule PauperLeague.AccessToken do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  schema "access_tokens" do
    field :auth_token, :string
    field :refresh_token, :string
    field :expires_at, :utc_datetime
    field :current, :boolean
  end

  def create(params) do
    current =
      from(at in __MODULE__,
        where: at.current
      )
      |> PauperLeague.Repo.all()

    current
    |> Enum.each(fn at -> at |> change(%{current: false}) |> PauperLeague.Repo.update() end)

    params = Map.merge(params, %{current: true})

    %__MODULE__{}
    |> change(params)
    |> PauperLeague.Repo.insert()
  end

  def get_current do
    __MODULE__
    |> where([at], at.current)
    |> PauperLeague.Repo.one()
  end
end
