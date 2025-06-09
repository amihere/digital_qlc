defmodule QlcDigital.MessageHandler do
  require Logger

  alias QlcDigital.{User, Redis}

  def handle_message(%{"from" => from, "text" => %{"body" => body}, "id" => message_id}) do
    Logger.info("Received message [#{message_id}] from #{from}: #{body}")

    # Hi overrides all previous progress
    case String.downcase(String.trim(body)) do
      "hi" ->
        manage_next_step(from, body)

      _ ->
        # Find user. If they exist, resume else start from -
        case Redis.hgetall_as_struct(get_hmap_key(from), User) do
          {:ok, user} ->
            Logger.info(user)
            {step, _} = Integer.parse(user.step)
            manage_next_step(from, body, step)

          {:error, reason} ->
            Logger.info("The user #{from} is new")
            Logger.error("Could not find user #{reason}")
            manage_next_step(from, body)
        end
    end
  end

  def handle_message(message) do
    Logger.info("Received non-text message: #{inspect(message)}")
  end

  def manage_next_step(from, body, step \\ 0) do
    response = "Thanks for your message! Say 'hi' to start a conversation."

    Logger.info("Current step #{step}")

    case step do
      0 ->
        response =
          """
          Hello!
          Welcome to the Sister Check-In Circle Program!

          This Program is designed to help new and expectant mothers who may be experiencing anxiety,
          depression, or simply need additional support during this critical time in their lives.

          The program connects mothers with trained facilitators and peer support
          groups via WhatsApp, providing convenient access to mental health resources and community support.

          If you are interested in joining this program, we would like to ask a few questions.
          """

        question = "1. What is your name?"
        send_message(from, response)
        send_message(from, question)

        Logger.info("Responded to 'hi' from #{from}")
        user = %User{:phone => from, :step => step + 1}
        Redis.hmset(get_hmap_key(from), user |> Map.from_struct())

      1 ->
        # Check if this might be a name response (simple heuristic)
        name = body

        if String.contains?(name, ["my name is", "i am", "i'm"]) or
             (String.length(name) > 1 and String.length(name) < 50 and
                not String.contains?(name, " ")) do
          Logger.info("User #{from} provided name: #{name}")

          response = """
          Nice to meet you, #{extract_name(name)}!

          2. What is your age?
          """

          send_message(from, response)

          {:ok, user} = Redis.hgetall_as_struct(get_hmap_key(from), User)
          user = struct(user, name: name, step: step + 1) |> Map.from_struct()

          Redis.hmset(get_hmap_key(from), user)
        else
          Logger.info("User #{from} provided name: #{name} #{body}")
          send_message(from, response)
        end

      2 when is_binary(body) ->
        # Check if this might be a name response (simple heuristic)
        Logger.info("User #{from} provided age: #{body}")

        case Integer.parse(body) do
          {age, ""} ->
            response = """
            Thanks!

            3. What is your email?

            (Say NO if you don't have one)
            """

            send_message(from, response)

            {:ok, user} = Redis.hgetall_as_struct(get_hmap_key(from), User)
            user = struct(user, age: age, step: step + 1) |> Map.from_struct()

            Redis.hmset(get_hmap_key(from), user)

          :error ->
            Logger.info("User #{from} provided age as: #{body}")
            response = "Please enter your age as a number (e.g. 18)"
            send_message(from, response)
        end

      3 ->
        email_public =
          case body |> String.trim() |> String.downcase() do
            "no" -> "(empty)"
            email -> email
          end

        {:ok, user} = Redis.hgetall_as_struct(get_hmap_key(from), User)

        Logger.info("User #{from} provided email as: #{body}")

        response = """
        Thank you, all your information has been securely saved!

        Name: #{user.name}
        Age: #{user.age}
        Phone: #{user.phone}
        Email: #{email_public}

        We will reach out to you with some forms to see how we can better serve you!

        Please note, if any of your information is wrong, send hi! This will restart the process so you can update your information!
        """

        send_message(from, response)

        user = struct(user, email: email_public, step: step + 1) |> Map.from_struct()
        Redis.hmset(get_hmap_key(from), user)

      _ ->
        send_message(from, response)
    end
  end

  defp extract_name(text) do
    text
    |> String.downcase()
    |> String.replace(~r/my name is |i am |i'm /, "")
    |> String.trim()
    |> String.split()
    |> List.first()
    |> case do
      nil -> "friend"
      name -> String.capitalize(name)
    end
  end

  defp send_message(to, message) do
    config = QlcDigital.Config.get_config()

    url = "https://graph.facebook.com/v22.0/#{config.whatsapp_phone_id}/messages"

    headers = [
      {"Authorization", "Bearer #{config.whatsapp_token}"},
      {"Content-Type", "application/json"}
    ]

    body =
      Jason.encode!(%{
        messaging_product: "whatsapp",
        to: to,
        type: "text",
        text: %{body: message}
      })

    case HTTPoison.post(url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200}} ->
        Logger.info("Message sent successfully to #{to}")
        :ok

      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} ->
        Logger.error("Failed to send message. Status: #{status_code}, Body: #{response_body}")
        :error

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("HTTP request failed: #{reason}")
        :error
    end
  end

  defp get_hmap_key(key) do
    key <> ".step"
  end
end
