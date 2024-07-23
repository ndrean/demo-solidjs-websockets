defmodule Solidjs.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Solidjs.Release.migrate()
    children = [
      SolidjsWeb.Telemetry,
      Solidjs.Repo,
      {Ecto.Migrator,
        repos: Application.fetch_env!(:solidjs, :ecto_repos),
        skip: skip_migrations?()},
      {DNSCluster, query: Application.get_env(:solidjs, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MyPubsub},
      {DynamicSupervisor, name: DynSup, strategy: :one_for_one},
      # {Solidjs.Streamer, uri: "wss://ws.coincap.io/prices?assets=bitcoin", state: %{symbol: "bitcoin"}},
      {Finch, name: Solidjs.Finch},
      SolidjsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Solidjs.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SolidjsWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp skip_migrations?() do
    # By default, sqlite migrations are run when using a release
    System.get_env("RELEASE_NAME") != nil
  end
end
