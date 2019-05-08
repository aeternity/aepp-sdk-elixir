defmodule CoreOracleTest do
  use ExUnit.Case

  alias Core.{Client, Oracle}

  setup_all do
    client =
      Client.new(
        %{
          public: "ak_Rro7GgyG3gJ7Tsu4k4YvZ45P1GtNfMyRX4Xfv8VWDjbvLDphN",
          secret:
            "57f62f3f370e34f93c0cd4d25d1c83287de75b9a6008a31cf02ec7c379d8e5f43871c06a8f08eaf7e79ba4d7633668ffbeb2f4745aef75f2c9775e714856f088"
        },
        "ae_uat",
        "https://sdk-testnet.aepps.com/v2",
        "https://sdk-testnet.aepps.com/v2"
      )

    [client: client]
  end

  test "register, query, respond, extend oracle", setup_data do
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
