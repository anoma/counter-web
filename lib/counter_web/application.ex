defmodule CounterWeb.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CounterWebWeb.Telemetry,
      # CounterWeb.Repo,
      {DNSCluster, query: Application.get_env(:counter_web, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CounterWeb.PubSub},
      # Start a worker by calling: CounterWeb.Worker.start_link(arg)
      # {CounterWeb.Worker, arg},
      # Start to serve requests, typically the last entry
      CounterWebWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CounterWeb.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CounterWebWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
