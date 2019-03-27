defmodule AeppSdkElixir.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [{:excoveralls, "~> 0.10", only: :test}, {:ex_doc, "~> 0.19", only: :dev, runtime: false}]
  end
  defp aliases do
    [build_api: &build_api/1]
  end

  defp build_api([generator_version, api_specification_version]) do
    Enum.each(
      [
        {"wget",
         [
           "--verbose",
           "https://github.com/aeternity/openapi-generator/releases/download/#{generator_version}/#{get_file_name(:generator)}-#{generator_version}-ubuntu-x86_64.tar.gz"
         ]},
        {"wget",
         [
           "--verbose",
           "https://raw.githubusercontent.com/aeternity/aeternity/#{api_specification_version}/config/#{get_file_name(:specification)}.yaml"
         ]},
        {"tar", ["zxvf", "#{get_file_name(:generator)}-#{generator_version}-ubuntu-x86_64.tar.gz"]},
        {"rm", ["#{get_file_name(:generator)}-#{generator_version}-ubuntu-x86_64.tar.gz"]},
        {"java",
         [
           "-jar",
           "./#{get_file_name(:generator)}.jar",
           "generate",
           "-i",
           "./#{get_file_name(:specification)}.yaml",
           "-g",
           "elixir",
           "-o",
           "./apps/aeternity_node/"
         ]},
         {"mix",["format"]},
         {"rm", ["-f","#{get_file_name(:generator)}.jar"]},
         {"rm", ["-f","#{get_file_name(:specification)}.yaml"]}
      ],
      fn {com, args} -> System.cmd(com, args) end
    )
  end

  defp get_file_name(:specification) do
    "swagger"
  end

  defp get_file_name(:generator) do
    "openapi-generator-cli"
  end
end
