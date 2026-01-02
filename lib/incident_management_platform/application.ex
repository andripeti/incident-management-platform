defmodule IncidentManagementPlatform.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      IncidentManagementPlatformWeb.Telemetry,
      IncidentManagementPlatform.Repo,
      {DNSCluster,
       query: Application.get_env(:incident_management_platform, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: IncidentManagementPlatform.PubSub},
      # Start a worker by calling: IncidentManagementPlatform.Worker.start_link(arg)
      # {IncidentManagementPlatform.Worker, arg},
      # Start to serve requests, typically the last entry
      IncidentManagementPlatformWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: IncidentManagementPlatform.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    IncidentManagementPlatformWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
