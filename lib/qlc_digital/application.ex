defmodule QlcDigital.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    if Mix.env() == :test do
      start_test_environment()
    else
      start_production_environment()
    end
  end

  defp start_test_environment do
    port = Application.get_env(:qlc_digital, :test_port, 4001)
    _host = "127.0.0.1"
    
    children = QlcDigital.Test.TestConfig.get_test_children()
    
    opts = [strategy: :one_for_one, name: QlcDigital.Supervisor]
    Logger.info("Starting Eli Bot in TEST mode on port #{port}")
    Supervisor.start_link(children, opts)
  end

  defp start_production_environment do
    port = Application.get_env(:qlc_digital, :port)
    host = Application.get_env(:qlc_digital, :host)
    redis_config = Application.get_env(:qlc_digital, :redis, [])
    redis_url = redis_config[:url]
    whatsapp_config = Application.get_env(:qlc_digital, :whatsapp, [])

    base_children = [
      QlcDigital.Question.ConversationManager,
      {QlcDigital.Question.QuestionConfig, [file_path: "new_questions.md"]},
      {QlcDigital.WhatsappClient, [config: whatsapp_config]},
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
