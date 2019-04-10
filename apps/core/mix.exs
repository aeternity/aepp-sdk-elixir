defmodule Core.MixProject do
  use Mix.Project

  def project do
    [
      app: :core,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:aesophia,
       git: "https://github.com/aeternity/aesophia.git",
       manager: :rebar,
       ref: "267fef3a5bb87c8ac35f125024fbfa07511f13de"},
    {:aeternity_node, in_umbrella: true},
    {:utils, in_umbrella: true}
    ]
  end
end
