defmodule QlcDigital.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    port = Application.get_env(:qlc_digital, :port)
    host = Application.get_env(:qlc_digital, :host)
    redis_config = Application.get_env(:qlc_digital, :redis, [])
    redis_url = redis_config[:url]

    base_children = [
      QlcDigital.Question.ConversationManager,
      {QlcDigital.Question.QuestionConfig, [file_path: "new_questions.md"]},
      QlcDigital.WhatsappClient,
      {Plug.Cowboy,
       scheme: :http, plug: QlcDigital.Router, options: [port: port, ip: parse_ip(host)]}
    ]

    children = 
      if redis_url do
        # TODO: remove ssl laxness
        redis_child = {Redix, {redis_url, [ssl: true, socket_opts: [verify: :verify_none], name: :redix]}}
        List.insert_at(base_children, -2, redis_child)
      else
        Logger.warning("Redis URL not configured, skipping Redis connection")
        base_children
      end

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
