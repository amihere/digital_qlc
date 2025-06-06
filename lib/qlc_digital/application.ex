defmodule QlcDigital.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: QlcDigital.Router, options: [port: 4000]}
    ]

    opts = [strategy: :one_for_one, name: QlcDigital.Supervisor]
    Logger.info("Starting the QLC Digital Bot on port 4000")
    Supervisor.start_link(children, opts)
  end
end
