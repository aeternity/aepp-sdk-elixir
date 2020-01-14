defmodule CoreContractTest do
  use ExUnit.Case

  alias AeppSDK.{Account, Client, Contract, Utils.Keys}

  setup_all do
    Code.require_file("test_utils.ex", "test/")
    TestUtils.get_test_data()
  end

  @tag :travis_test
  test "create, call, call static and decode contract", setup_data do
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

    {:ok, %{return_value: data, return_type: "ok"}} = on_chain_call_result

    assert {:ok, data} ==
             Contract.decode_return_value(
               "int",
               "cb_AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEvrXnzA",
               "ok"
             )

    %{public: low_balance_public_key} = low_balance_keypair = Keys.generate_keypair()
    Account.spend(setup_data.client, low_balance_public_key, 1)

    static_call_result_1 =
      Contract.call(
        %Client{setup_data.client | keypair: low_balance_keypair},
        ct_address,
        setup_data.source_code,
        "get_number",
        [],
        fee: 10_000_000_000_000_000
      )

    assert match?({:ok, %{return_value: _, return_type: "ok"}}, static_call_result_1)

    non_existing_keypair = Keys.generate_keypair()

    static_call_result_2 =
      Contract.call(
        %Client{setup_data.client | keypair: non_existing_keypair},
        ct_address,
        setup_data.source_code,
        "get_number",
        [],
        fee: 10_000_000_000_000_000
      )

    assert match?({:ok, %{return_value: _, return_type: "ok"}}, static_call_result_2)
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
