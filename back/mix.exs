defmodule Logtales.Mixfile do
  use Mix.Project

  def project do
    [
      app: :logtales,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:cowboy, :plug, :timex],
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 1.1"},
      {:plug, "~> 1.0"},
      {:poison, "~> 3.1"},
      {:flow, "~> 0.12.0"},
      {:timex, "~> 3.1"}
    ]
  end
end
