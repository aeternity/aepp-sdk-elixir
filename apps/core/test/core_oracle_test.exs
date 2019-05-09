defmodule CoreOracleTest do
  use ExUnit.Case

  alias Core.{Client, Oracle}

  setup_all do
    client =
      Client.new(
        %{
          public: "ak_Qsto9j1HqiigTvVzYb74MgktHYystCZvQwtjLw85jJu3VrXu9",
          secret:
            "31a17b6c9d6dfaee7c382ea467cd1367bd973d495645a499e6dfb7c55bcf0cd736377a264cf6175cae1a7767558041add576d562e24572075cb069682b30e155"
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
        30,
        fee: 10_000_000_000_000_000
      )

    assert match?({:ok, _}, register)

    {:ok, %{query_id: query_id}} =
      query =
      Oracle.query(
        setup_data.client,
        oracle_id,
        %{"a" => 1},
        %{type: :relative, value: 10},
        10,
        fee: 10_000_000_000_000_000
      )

    assert match?({:ok, _}, query)

    assert match?(
             {:ok, _},
             Oracle.respond(
               setup_data.client,
               oracle_id,
               query_id,
               %{"b" => 2},
               10,
               fee: 10_000_000_000_000_000
             )
           )

    assert match?(
             {:ok, _},
             Oracle.extend(setup_data.client, oracle_id, 10, fee: 10_000_000_000_000_000)
           )

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
               30,
               fee: 10_000_000_000_000_000
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
               10,
               fee: 10_000_000_000_000_000
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
               10,
               fee: 10_000_000_000_000_000
             )
           )
  end

  test "extend non-existent oracle", setup_data do
    assert match?(
             {:error, _},
             Oracle.extend(
               setup_data.client,
               "ok_Aro7GgyG3gJ7Tsu4k4YvZ45P1GtNfMyRX4Xfv8VWDjbvLDphN",
               10,
               fee: 10_000_000_000_000_000
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
