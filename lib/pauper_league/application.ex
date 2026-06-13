defmodule PauperLeague.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PauperLeagueWeb.Telemetry,
      PauperLeague.Repo,
      {DNSCluster, query: Application.get_env(:pauper_league, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PauperLeague.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: PauperLeague.Finch},
      # Start a worker by calling: PauperLeague.Worker.start_link(arg)
      # {PauperLeague.Worker, arg},
      # Start to serve requests, typically the last entry
      PauperLeagueWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PauperLeague.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PauperLeagueWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
