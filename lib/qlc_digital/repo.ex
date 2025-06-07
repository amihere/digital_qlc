defmodule QlcDigital.Repo do
  use Ecto.Repo,
    otp_app: :qlc_digital,
    adapter: Ecto.Adapters.SQLite3
end
