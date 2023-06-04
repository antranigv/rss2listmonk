defmodule Rss2listmonk.MixProject do
  use Mix.Project

  def project do
    [
      app: :rss2listmonk,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      escript: escript()
    ]
  end

  defp escript do
    [
      main_module:  Rss2listmonk.CLI,
      path:         "_build/rss2listmonk"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 2.1"},
      {:poison, "~> 5.0"},
      {:quinn, "~> 1.1"},
      {:date_time_parser, "~> 1.1.5"},
      {:tzdata, "~> 0.1.8", override: true},
      {:html_entities, "~> 0.5.2"},
    ]
  end
end
