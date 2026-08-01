defmodule PauperLeagueWeb.AdminController do
  use PauperLeagueWeb, :controller

  def base(conn, _params) do
    render(conn, :base)
  end

  def stores(conn, _params) do
    stores = PauperLeague.Stores.list()

    conn
    |> assign(:store_list, stores)
    |> render(:stores)
  end
end
