defmodule CoreContractTest do
  use ExUnit.Case

  alias Core.{Client, Contract}

  setup_all do
    client =
      Client.new(
        %{
          public: "ak_6A2vcm1Sz6aqJezkLCssUXcyZTX7X8D5UwbuS2fRJr9KkYpRU",
          secret:
            "a7a695f999b1872acb13d5b63a830a8ee060ba688a478a08c6e65dfad8a01cd70bb4ed7927f97b51e1bcb5e1340d12335b2a2b12c8bc5221d63c4bcb39d41e61"
        },
        "ae_uat",
        "https://sdk-testnet.aepps.com/v2",
        "https://sdk-testnet.aepps.com/v2"
      )

    source_code = "contract Identity =
        record state = { number : int }

        function init(x : int) =
          { number = x }

        function add_to_number(x : int) = state.number + x"
    [client: client, source_code: source_code]
  end

  test "create, call, call static and decode contract", setup_data do
    deploy_result = Contract.deploy(setup_data.client, setup_data.source_code, "42")
    assert match?({:ok, _}, deploy_result)

    {:ok, ct_address} = deploy_result
    call_result = Contract.call(setup_data.client, ct_address, "add_to_number", "33")
    assert match?({:ok, %{return_value: _, return_type: "ok"}}, call_result)

    call_static_result =
      Contract.call_static(setup_data.client, ct_address, "add_to_number", "33")

    assert match?({:ok, %{return_value: _, return_type: "ok"}}, call_static_result)

    {:ok, %{return_value: data, return_type: "ok"}} = call_result

    assert {:ok, 75} == Contract.decode_return_value("int", data)
  end

  test "create invalid contract", setup_data do
    invalid_source_code = String.replace(setup_data.source_code, "x : int", "x : list(int)")
    deploy_result = Contract.deploy(setup_data.client, invalid_source_code, "42")
    assert match?({:error, _}, deploy_result)
  end

  test "call non-existent function", setup_data do
    deploy_result = Contract.deploy(setup_data.client, setup_data.source_code, "42")
    assert match?({:ok, _}, deploy_result)

    {:ok, ct_address} = deploy_result
    call_result = Contract.call(setup_data.client, ct_address, "non_existing_function", "33")
    assert match?({:error, _}, call_result)
  end

  test "call static non-existent function", setup_data do
    deploy_result = Contract.deploy(setup_data.client, setup_data.source_code, "42")
    assert match?({:ok, _}, deploy_result)

    {:ok, ct_address} = deploy_result

    call_result =
      Contract.call_static(setup_data.client, ct_address, "non_existing_function", "33")

    assert match?({:error, _}, call_result)
  end

  test "decode data wrong type", setup_data do
    deploy_result = Contract.deploy(setup_data.client, setup_data.source_code, "42")
    assert match?({:ok, _}, deploy_result)

    {:ok, ct_address} = deploy_result
    call_result = Contract.call(setup_data.client, ct_address, "add_to_number", "33")
    assert match?({:ok, %{return_value: _, return_type: "ok"}}, call_result)

    {:ok, %{return_value: data, return_type: "ok"}} = call_result

    assert {:error,
            {:badmatch,
             <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 75>>}} == Contract.decode_return_value("list(int)", data)
  end
end
