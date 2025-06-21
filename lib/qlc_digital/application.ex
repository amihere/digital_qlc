defmodule QlcDigital.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    port = Application.get_env(:qlc_digital, :port)
    host = Application.get_env(:qlc_digital, :host)
    redis_url = Application.get_env(:qlc_digital, :redis)[:url]

    Logger.info(redis_url)

    children = [
      QlcDigital.Question.ConversationManager,
      QlcDigital.Question.QuestionConfig,
      # TODO: remove ssl laxness
      {Redix, {redis_url, [ssl: true, socket_opts: [verify: :verify_none], name: :redix]}},
      {Plug.Cowboy,
       scheme: :http, plug: QlcDigital.Router, options: [port: port, ip: parse_ip(host)]}
    ]

    opts = [strategy: :one_for_one, name: QlcDigital.Supervisor]
    Logger.info("Starting the Eli Bot on port #{port} and host #{host}")
    Supervisor.start_link(children, opts)
  end

  defp parse_ip(host) do
    case :inet.parse_address(String.to_charlist(host)) do
      {:ok, ip} ->
        ip

      {:error, _} ->
        {0, 0, 0, 0}
    end
  end
end
