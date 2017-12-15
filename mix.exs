defmodule Logtales.Mixfile do
  use Mix.Project

  def project do
    [
      app: :logtales,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps(),
      dialyzer: [ plt_add_deps: :transitive ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Logtales, []},
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
      {:timex, "~> 3.1"},
      {:eye_drops, "~> 1.3"},
      {:dialyxir, "~> 0.5.1", only: [:dev], runtime: false},
    ]
  end
end
