defmodule QlcDigital.User do
  @derive Jason.Encoder
  defstruct name: "", age: -1, email: "", phone: ""
end
