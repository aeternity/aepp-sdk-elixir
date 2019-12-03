defmodule AeppSdkElixir.MixProject do
  use Mix.Project

  def project do
    [
      app: :aepp_sdk_elixir,
      version: "0.5.1",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      aliases: aliases(),
      elixir: "~> 1.9",
      test_coverage: [tool: ExCoveralls],
      docs: [logo: "logo.png", filter_prefix: "AeppSDK"],
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
    [
      {:excoveralls, "~> 0.10", only: :test},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:aesophia,
       git: "https://github.com/aeternity/aesophia.git", manager: :rebar, tag: "v4.0.0"},
      {:enoise,
       git: "https://github.com/aeternity/enoise.git",
       manager: :rebar,
       ref: "c06bbae07d5a6711e60254e45e57e37e270b961d"},
      {:distillery, "~> 2.0"},
      {:enacl,
       github: "aeternity/enacl", ref: "26180f42c0b3a450905d2efd8bc7fd5fd9cece75", override: true},
      {:tesla, "~> 1.2.1"},
      {:poison, "~> 3.0.0"},
      {:ranch, "~> 1.7"},
      {:hackney, "~> 1.15"},
      {:argon2_elixir, "~> 2.0"},
      {:uuid, "~> 1.1"},
      {:credo, "~> 1.1.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp description(), do: "Elixir SDK targeting the Æternity node implementation."

  defp package() do
    [
      licenses: ["ISC License"],
      links: %{"GitHub" => "https://github.com/aeternity/aepp-sdk-elixir"}
    ]
  end

  defp aliases do
    [build_api: &build_api/1]
  end

  defp build_api([generator_version, aenode_spec_vsn, middleware_spec_vsn]) do
    Enum.each(
      [
        get_generator(generator_version),
        get_swagger_spec(:aenode, aenode_spec_vsn),
        get_swagger_spec(:middleware, middleware_spec_vsn),
        {"tar",
         ["zxvf", "#{get_file_name(:generator)}-#{generator_version}-ubuntu-x86_64.tar.gz"]},
        {"rm", ["#{get_file_name(:generator)}-#{generator_version}-ubuntu-x86_64.tar.gz"]},
        prepare_java_commands(:aenode),
        prepare_java_commands(:middleware),
        {"mix", ["format"]},
        {"rm", ["-f", "#{get_file_name(:generator)}.jar"]},
        {"rm", ["-f", "#{get_file_name(:specification)}.yaml"]},
        {"rm", ["-f", "#{get_file_name(:specification)}.json"]}
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

  defp prepare_java_commands(:aenode) do
    {"java",
     [
       "-jar",
       "./#{get_file_name(:generator)}.jar",
       "generate",
       "--skip-validate-spec",
       "-i",
       "./#{get_file_name(:specification)}.yaml",
       "-g",
       "elixir",
       "-o",
       "./lib/aeternity_node/"
     ]}
  end

  defp prepare_java_commands(:middleware) do
    {"java",
     [
       "-jar",
       "./#{get_file_name(:generator)}.jar",
       "generate",
       "--skip-validate-spec",
       "-i",
       "./#{get_file_name(:specification)}.json",
       "-g",
       "elixir",
       "-o",
       "./lib/middleware/"
     ]}
  end

  defp get_generator(generator_version) do
    {"wget",
     [
       "--verbose",
       "https://github.com/aeternity/openapi-generator/releases/download/#{generator_version}/#{
         get_file_name(:generator)
       }-#{generator_version}-ubuntu-x86_64.tar.gz"
     ]}
  end

  defp get_swagger_spec(:aenode, api_specification_version) do
    {"wget",
     [
       "--verbose",
       "https://raw.githubusercontent.com/aeternity/aeternity/#{api_specification_version}/apps/aehttp/priv/#{
         get_file_name(:specification)
       }.yaml"
     ]}
  end

  defp get_swagger_spec(:middleware, api_specification_version) do
    {"wget",
     [
       "--verbose",
       "https://raw.githubusercontent.com/aeternity/aepp-middleware/#{api_specification_version}/swagger/#{
         get_file_name(:specification)
       }.json"
     ]}
  end
end
