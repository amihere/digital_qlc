defmodule QlcDigital.MixProject do
  use Mix.Project

  def project do
    [
      app: :qlc_digital,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {QlcDigital.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:redix, "~> 1.5.2"},
      {:httpoison, "~> 2.0"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.6"},
      {:plug, "~> 1.14"}
    ]
  end
end
