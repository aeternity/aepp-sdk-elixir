defmodule CoreOracleTest do
  use ExUnit.Case

  alias AeppSDK.Oracle

  setup_all do
    Code.require_file("test_utils.ex", "test/")
    TestUtils.get_test_data()
  end

  @tag :travis_test
  test "register, query, respond, extend, get oracle, get queries", setup_data do
    {:ok, %{oracle_id: oracle_id}} =
      register =
      Oracle.register(
        setup_data.client,
        "map(string, int)",
        "map(string, int)",
        %{type: :relative, value: 500},
        30,
        abi_version: 1
      )

    assert match?({:ok, _}, register)

    {:ok, %{query_id: query_id}} =
      query =
      Oracle.query(
        setup_data.client,
        oracle_id,
        %{"a" => 1},
        %{type: :relative, value: 100},
        100
      )

    {:ok, queries} = Oracle.get_queries(setup_data.client, oracle_id)

    assert length(queries) == 1

    assert match?(
             {:ok, %{query: %{"a" => 1}}},
             Oracle.get_query(setup_data.client, oracle_id, query_id)
           )

    assert match?({:ok, _}, query)

    assert match?(
             {:ok, _},
             Oracle.respond(
               setup_data.client,
               oracle_id,
               query_id,
               %{"b" => 2},
               100
             )
           )

    assert match?(
             {:ok, _},
             Oracle.extend(setup_data.client, oracle_id, 100)
           )

    assert match?({:ok, _}, Oracle.get_oracle(setup_data.client, oracle_id))
  end

  @tag :travis_test
  test "get oracle queries with bad oracle_id", setup_data do
    assert match?(
             {:error, _},
             Oracle.get_queries(setup_data.client, setup_data.client.keypair.public)
           )
  end

  @tag :travis_test
  test "get oracle query with bad query_id", setup_data do
    assert match?(
             {:error, _},
             Oracle.get_query(
               setup_data.client,
               String.replace_prefix(setup_data.client.keypair.public, "ak", "ok"),
               "oq_123"
             )
           )
  end

  @tag :travis_test
  test "register oracle with bad formats", setup_data do
    assert match?(
             {:error, "Bad Sophia type: bad format"},
             Oracle.register(
               setup_data.client,
               "bad format",
               "bad format",
               %{type: :relative, value: 30},
               30,
               abi_version: 1
             )
           )
  end

  @tag :travis_test
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

  @tag :travis_test
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

  @tag :travis_test
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

  @tag :travis_test
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
