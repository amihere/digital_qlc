defmodule QlcDigital.Router do
  use Plug.Router
  require Logger

  defp whatsapp_client_module do
    Application.get_env(:qlc_digital, :whatsapp_client_module, QlcDigital.WhatsappClient)
  end

  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)
  plug(Plug.Static, at: "/", from: :qlc_digital, only: ~w(public))

  # Webhook verification endpoint
  get "/webhook" do
    verify_token = whatsapp_client_module().get_verify_token()

    case conn.params do
      %{
        "hub.mode" => "subscribe",
        "hub.verify_token" => ^verify_token,
        "hub.challenge" => challenge
      } ->
        Logger.info("Webhook verified successfully")
        send_resp(conn, 200, challenge)

      _ ->
        Logger.warning("Webhook verification failed")
        send_resp(conn, 403, "Forbidden")
    end
  end

  # Webhook endpoint for receiving messages
  post "/webhook" do
    case conn.body_params do
      %{"entry" => entries} when is_list(entries) ->
        Enum.each(entries, &process_entry/1)
        send_resp(conn, 200, "OK")

      _ ->
        Logger.warning("Invalid webhook payload received")
        send_resp(conn, 400, "Bad Request")
    end
  end

  get "/heartbeat" do
    send_resp(conn, 200, "OK")
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  defp process_entry(%{"changes" => changes}) when is_list(changes) do
    Enum.each(changes, &process_change/1)
  end

  defp process_entry(_), do: :ok

  defp process_change(%{"value" => %{"messages" => messages}}) when is_list(messages) do
    Enum.each(messages, &QlcDigital.MessageHandler.handle_message/1)
  end

  defp process_change(_), do: :ok
end
