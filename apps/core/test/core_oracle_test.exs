defmodule CoreOracleTest do
  use ExUnit.Case

  alias Core.{Client, Oracle}

  setup_all do
    client =
      Client.new(
        %{
          public: "ak_2BiD4FJmm75NHTcPpmrmyQv1LsqXbShqw8aMiZVhhK7TswbLd2",
          secret:
            "6c4e21d09e4c4f5b68fe154a6248cce16583e7f4693a24a13734f99cf2e57f999c03fb2aaf3948cf01c44053c38545b2c0d849accad48faa7f743b013710ec50"
        },
        "ae_uat",
        "https://sdk-testnet.aepps.com/v2",
        "https://sdk-testnet.aepps.com/v2"
      )

    [client: client]
  end

  test "register, query, respond, extend, get oracle", setup_data do
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

    assert match?({:ok, _}, Oracle.get_oracle(setup_data.client, oracle_id))
  end

  test "register oracle with bad formats", setup_data do
    assert match?(
             {:error, "Bad Sophia type: bad format"},
             Oracle.register(
               setup_data.client,
               "bad format",
               "bad format",
               %{type: :relative, value: 30},
               30
             )
           )
  end

  test "query non-existent oracle", setup_data do
    assert match?(
             {:error, _},
             Oracle.query(
               setup_data.client,
               "ok_123",
               "a query",
               %{type: :relative, value: 10},
               10
             )
           )
  end

  test "respond to non-existent query", setup_data do
    assert match?(
             {:error, _},
             Oracle.respond(
               setup_data.client,
               String.replace_prefix(setup_data.client.keypair.public, "ak", "ok"),
               String.replace_prefix(setup_data.client.keypair.public, "ak", "oq"),
               %{"b" => 2},
               10
             )
           )
  end

  test "extend non-existent oracle", setup_data do
    assert match?(
             {:error, _},
             Oracle.extend(
               setup_data.client,
               "ok_Aro7GgyG3gJ7Tsu4k4YvZ45P1GtNfMyRX4Xfv8VWDjbvLDphN",
               10
             )
           )
  end

  test "get non-existent oracle", setup_data do
    assert match?(
             {:error, _},
             Oracle.get_oracle(
               setup_data.client,
               "ok_Aro7GgyG3gJ7Tsu4k4YvZ45P1GtNfMyRX4Xfv8VWDjbvLDphN"
             )
           )
  end
end
