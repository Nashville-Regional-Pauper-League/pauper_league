defmodule PauperLeagueWeb.PageController do
  use PauperLeagueWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home)
  end
end
