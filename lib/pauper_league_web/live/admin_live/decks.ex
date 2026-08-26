defmodule PauperLeagueWeb.AdminLive.Decks do
  use PauperLeagueWeb, :live_view

  import Ecto.Query
  import Ecto.Changeset

  @impl true
  def mount(_params, _session, socket) do
    changeset = %PauperLeague.DeckArchetype{} |> change()

    socket =
      assign(socket, default_decks: PauperLeague.DeckArchetype.all())
      |> assign(:form, to_form(changeset))

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("live_select_change", %{"id" => id, "text" => text}, socket) do
    options =
      if text == "" do
        socket.assigns.default_decks
      else
        socket.assigns.default_decks
        |> Enum.map(fn d -> Map.get(d, :label) end)
        |> Enum.filter(&(String.downcase(&1) |> String.contains?(String.downcase(text))))
      end

    send_update(LiveSelect.Component, options: options, id: id)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "create-deck",
        %{
          "deck_archetype" => %{
            "deck_archetype_name" => new_name
          }
        },
        socket
      ) do
    exists? =
      PauperLeague.DeckArchetype
      |> where([d], fragment("lower(?) = lower(?)", d.name, ^new_name))
      |> PauperLeague.Repo.exists?()

    if not exists? do
      %PauperLeague.DeckArchetype{}
      |> change(%{name: new_name})
      |> PauperLeague.Repo.insert()
    end

    {:noreply, socket |> assign(default_decks: PauperLeague.DeckArchetype.all())}
  end
end
