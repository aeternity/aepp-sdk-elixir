defmodule CoreOracleTest do
  use ExUnit.Case

  alias Core.{Client, Oracle}

  setup_all do
    client =
      Client.new(
        %{
          public: "ak_4K1dYTkXcLwoUEat9fMgVp3RrG3HTD51v4VzszYDgt2MqxzKM",
          secret:
            "303ef8fb879e9ef8e4f13f0d964d48f64a7f4591c2402901e87dce9a99fd018007845806798e4eaa6cdfb4e5400675b0ebca5d1f806bae3e7ae1633d38efc5cd"
        },
        "ae_uat",
        "https://sdk-testnet.aepps.com/v2",
        "https://sdk-testnet.aepps.com/v2"
      )

    [client: client]
  end

  test "register oracle", setup_data do
    {:ok, %{oracle_id: oracle_id}} =
      register =
      Oracle.register(
        setup_data.client,
        "map(string, int)",
        "map(string, int)",
        %{type: :relative, value: 30},
        30
      )

    assert match?({:ok, _}, register)

    {:ok, %{query_id: query_id}} =
      query =
      Oracle.query(
        setup_data.client,
        oracle_id,
        %{"a" => 1},
        %{type: :relative, value: 10},
        10
      )

    assert match?({:ok, _}, query)

    assert match?(
             {:ok, _},
             Oracle.respond(
               setup_data.client,
               oracle_id,
               query_id,
               %{"b" => 2},
               10
             )
           )

    assert match?({:ok, _}, Oracle.extend(setup_data.client, oracle_id, 10))
  end
end
