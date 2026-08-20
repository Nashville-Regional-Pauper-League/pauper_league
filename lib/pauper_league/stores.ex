defmodule PauperLeague.Stores do
  @moduledoc """
    Placeholder for store logic
  """

  def list do
    PauperLeague.Stores.Store
    |> PauperLeague.Repo.all()
  end
end
