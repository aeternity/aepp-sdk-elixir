defmodule CoreContractTest do
  use ExUnit.Case

  alias AeppSDK.{Account, Client, Contract, Utils.Keys}

  setup_all do
    client =
      Client.new(
        %{
          public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
          secret:
            "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
        },
        "my_test",
        "http://localhost:3013/v2",
        "http://localhost:3113/v2"
      )

    source_code = "contract Identity =
      datatype event = AddedNumberEvent(indexed int, string)

      record state = { number : int }

      entrypoint init(x : int) =
        { number = x }

      entrypoint get_number() =
        state.number

      stateful entrypoint add_to_number(x : int) =
        Chain.event(AddedNumberEvent(x, \"Added a number\"))
        put(state{number = state.number + x})"

    [client: client, source_code: source_code]
  end

  @tag :travis_test
  test "create, call, call static and decode contract with aevms", setup_data do
    deploy_result =
      Contract.deploy(
        setup_data.client,
        setup_data.source_code,
        ["42"],
        vm: :aevm
      )

    assert match?({:ok, _}, deploy_result)

    {:ok, %{contract_id: ct_address}} = deploy_result

    on_chain_call_result =
      Contract.call(
        setup_data.client,
        ct_address,
        setup_data.source_code,
        "add_to_number",
        ["33"]
      )

    assert match?({:ok, %{return_value: _, return_type: "ok"}}, on_chain_call_result)

    refute on_chain_call_result |> elem(1) |> Map.get(:log) |> Enum.empty?()

    static_call_result =
      Contract.call(
        setup_data.client,
        ct_address,
        setup_data.source_code,
        "get_number",
        [],
        fee: 10_000_000_000_000_000
      )

    assert match?({:ok, %{return_value: _, return_type: "ok"}}, static_call_result)

    {:ok, %{return_value: data, return_type: "ok"}} = static_call_result

    assert {:ok, data} ==
             Contract.decode_return_value(
               "int",
               "cb_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEvrXnzA",
               "ok"
             )

    %{public: low_balance_public_key} = low_balance_keypair = Keys.generate_keypair()
    Account.spend(setup_data.client, low_balance_public_key, 1)

    static_call_result_ =
      Contract.call(
        %Client{setup_data.client | keypair: low_balance_keypair},
        ct_address,
        setup_data.source_code,
        "get_number",
        [],
        fee: 10_000_000_000_000_000
      )

    assert match?({:ok, %{return_value: _, return_type: "ok"}}, static_call_result_)
  end

  @tag :travis_test
  test "create, call, call static and decode contract with fate vm", setup_data do
    deploy_result =
      Contract.deploy(
        setup_data.client,
        setup_data.source_code,
        ["42"]
      )

    assert match?({:ok, _}, deploy_result)

    {:ok, %{contract_id: ct_address}} = deploy_result

    on_chain_call_result =
      Contract.call(
        setup_data.client,
        ct_address,
        setup_data.source_code,
        "add_to_number",
        ["33"]
      )

    assert match?({:ok, %{return_value: _, return_type: "ok"}}, on_chain_call_result)

    refute on_chain_call_result |> elem(1) |> Map.get(:log) |> Enum.empty?()

    static_call_result =
      Contract.call(
        setup_data.client,
        ct_address,
        setup_data.source_code,
        "get_number",
        [],
        fee: 10_000_000_000_000_000
      )

    assert match?({:ok, %{return_value: _, return_type: "ok"}}, static_call_result)

    {:ok, %{return_value: data, return_type: "ok"}} = static_call_result

    assert {:ok, data} ==
             Contract.decode_return_value(
               "int",
               "cb_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEvrXnzA",
               "ok"
             )

    %{public: low_balance_public_key} = low_balance_keypair = Keys.generate_keypair()
    Account.spend(setup_data.client, low_balance_public_key, 1)

    static_call_result_ =
      Contract.call(
        %Client{setup_data.client | keypair: low_balance_keypair},
        ct_address,
        setup_data.source_code,
        "get_number",
        [],
        fee: 10_000_000_000_000_000
      )

    assert match?({:ok, %{return_value: _, return_type: "ok"}}, static_call_result_)
  end

  @tag :travis_test
  test "create invalid contract", setup_data do
    invalid_source_code = String.replace(setup_data.source_code, "x : int", "x : list(int)")

    deploy_result = Contract.deploy(setup_data.client, invalid_source_code, ["42"])

    assert match?({:error, _}, deploy_result)
  end

  @tag :travis_test
  test "call non-existent function", setup_data do
    deploy_result =
      Contract.deploy(
        setup_data.client,
        setup_data.source_code,
        ["42"]
      )

    assert match?({:ok, _}, deploy_result)

    {:ok, %{contract_id: ct_address}} = deploy_result

    on_chain_call_result =
      Contract.call(
        setup_data.client,
        ct_address,
        setup_data.source_code,
        "non_existing_function",
        ["33"]
      )

    assert match?({:error, "Undefined function non_existing_function"}, on_chain_call_result)
  end

  @tag :travis_test
  test "call static non-existent function", setup_data do
    deploy_result =
      Contract.deploy(
        setup_data.client,
        setup_data.source_code,
        ["42"]
      )

    assert match?({:ok, _}, deploy_result)

    {:ok, %{contract_id: ct_address}} = deploy_result

    static_call_result =
      Contract.call(
        setup_data.client,
        ct_address,
        setup_data.source_code,
        "non_existing_function",
        ["33"],
        fee: 10_000_000_000_000_000
      )

    assert match?({:error, "Undefined function non_existing_function"}, static_call_result)
  end

  @tag :travis_test
  test "decode data wrong type", setup_data do
    deploy_result =
      Contract.deploy(
        setup_data.client,
        setup_data.source_code,
        ["42"]
      )

    assert match?({:ok, _}, deploy_result)

    {:ok, %{contract_id: ct_address}} = deploy_result

    on_chain_call_result =
      Contract.call(
        setup_data.client,
        ct_address,
        setup_data.source_code,
        "add_to_number",
        ["33"]
      )

    assert match?({:ok, %{return_value: _, return_type: "ok"}}, on_chain_call_result)

    {:ok, %{return_value: _, return_type: "ok"}} = on_chain_call_result

    assert {:error,
            {:badmatch,
             <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0,
               75>>}} ==
             Contract.decode_return_value(
               "list(int)",
               "cb_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEvrXnzA",
               "ok"
             )
  end
end
