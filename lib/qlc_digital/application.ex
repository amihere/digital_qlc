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
    redis_ca_cert_file = redis_config[:ca_cert_file]
    whatsapp_config = Application.get_env(:qlc_digital, :whatsapp, [])

    base_children = [
      QlcDigital.Question.ConversationManager,
      {QlcDigital.Question.QuestionConfig, [file_path: "new_questions.md"]},
      {QlcDigital.WhatsappClient, [config: whatsapp_config]},
      {Plug.Cowboy,
       scheme: :http, plug: QlcDigital.Router, options: [port: port, ip: parse_ip(host)]}
    ]

    children =
      cond do
        is_nil(redis_url) ->
          Logger.warning("REDIS_URL not configured, skipping Redis connection")
          base_children

        String.starts_with?(redis_url, "rediss://") and is_nil(redis_ca_cert_file) ->
          raise """
          REDIS_URL uses rediss:// but REDIS_CA_CERT_FILE is unset. Refusing to \
          start: this would either fall back to plaintext or skip certificate \
          verification, both of which defeat the point of TLS over the public \
          internet. Set REDIS_CA_CERT_FILE to the CA bundle that signed the \
          server certificate.
          """

        true ->
          redis_child = {Redix, {redis_url, redix_opts(redis_url, redis_ca_cert_file)}}
          List.insert_at(base_children, -2, redis_child)
      end

    opts = [strategy: :one_for_one, name: QlcDigital.Supervisor]
    Logger.info("Starting the Eli Bot on port #{port} and host #{host}")
    Supervisor.start_link(children, opts)
  end

  defp redix_opts("rediss://" <> _ = url, ca_cert_file) do
    %URI{host: host} = URI.parse(url)

    ssl_opts = [
      verify: :verify_peer,
      cacertfile: ca_cert_file,
      depth: 3,
      server_name_indication: String.to_charlist(host),
      customize_hostname_check: [
        match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
      ]
    ]

    [name: :redix, socket_opts: ssl_opts]
  end

  defp redix_opts(_plaintext_url, _ca_cert_file) do
    [name: :redix]
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
