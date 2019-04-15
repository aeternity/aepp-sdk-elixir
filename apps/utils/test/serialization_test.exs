defmodule UtilsSerializationTest do
  use ExUnit.Case

  alias Utils.Serialization

  alias AeternityNode.Model.{
    SpendTx,
    OracleRegisterTx,
    OracleRespondTx,
    OracleQueryTx,
    OracleExtendTx,
    NamePreclaimTx,
    NameClaimTx,
    NameRevokeTx,
    NameTransferTx,
    NameUpdateTx,
    ContractCreateTx,
    ContractCallTx,
    RelativeTtl,
    Ttl
  }

  setup_all do
    account_id = Serialization.id_to_record(<<0::256>>, :account)
    oracle_id = Serialization.id_to_record(<<0::256>>, :oracle)
    commitment_id = Serialization.id_to_record(<<0::256>>, :commitment)
    name_id = Serialization.id_to_record(<<0::256>>, :name)
    contract_id = Serialization.id_to_record(<<0::256>>, :contract)

    spend_fields = [
      account_id,
      account_id,
      10,
      10,
      10,
      10,
      <<"payload">>
    ]

    oracle_register_fields = [
      account_id,
      10,
      <<"query_format">>,
      <<"response_format">>,
      10,
      1,
      10,
      10,
      10,
      1
    ]

    oracle_query_fields = [
      account_id,
      10,
      oracle_id,
      <<"query">>,
      10,
      1,
      10,
      1,
      10,
      10,
      10
    ]

    oracle_response_fields = [
      oracle_id,
      10,
      <<0::256>>,
      <<"response">>,
      1,
      10,
      10,
      10
    ]

    oracle_extend_fields = [
      oracle_id,
      10,
      1,
      10,
      10,
      10
    ]

    name_claim_fields = [
      account_id,
      10,
      <<"name">>,
      10,
      10,
      10
    ]

    name_preclaim_fields = [
      account_id,
      10,
      commitment_id,
      10,
      10
    ]

    name_update_fields = [
      account_id,
      10,
      name_id,
      10,
      [{<<1>>, name_id}],
      10,
      10,
      10
    ]

    name_revoke_fields = [
      account_id,
      10,
      name_id,
      10,
      10
    ]

    name_transfer_fields = [
      account_id,
      10,
      name_id,
      account_id,
      10,
      10
    ]

    contract_create_fields = [
      account_id,
      10,
      <<"code">>,
      10,
      10,
      10,
      10,
      10,
      10,
      10,
      <<"call data">>
    ]

    contract_call_fields = [
      account_id,
      10,
      contract_id,
      10,
      10,
      10,
      10,
      10,
      10,
      <<"call data">>
    ]

    spend_tx = %SpendTx{
      amount: 5_018_857_520_000_000_000,
      fee: 0,
      nonce: 37181,
      payload: "",
      recipient_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      sender_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      ttl: 0
    }

    oracle_register_tx = %OracleRegisterTx{
      query_format: <<"query_format">>,
      response_format: <<"response_format">>,
      query_fee: 10,
      oracle_ttl: %Ttl{type: "block", value: 10},
      account_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      nonce: 37122,
      fee: 0,
      ttl: 10,
      vm_version: 0x30001,
      abi_version: 0x30001
    }

    oracle_respond_tx = %OracleRespondTx{
      query_id: <<"query_id">>,
      response: <<"response_format">>,
      response_ttl: %RelativeTtl{type: "delta", value: 10},
      fee: 0,
      ttl: 10,
      oracle_id: "ok_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      nonce: 0
    }

    oracle_query_tx = %OracleQueryTx{
      oracle_id: "ok_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      query: <<"query">>,
      query_fee: 10,
      query_ttl: %Ttl{type: "delta", value: 10},
      response_ttl: %RelativeTtl{type: "delta", value: 10},
      fee: 0,
      ttl: 10,
      sender_id: "ct_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      nonce: 0
    }

    oracle_extend_tx = %OracleExtendTx{
      fee: 0,
      oracle_ttl: %RelativeTtl{type: "delta", value: 10},
      oracle_id: "ok_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      nonce: 0,
      ttl: 0
    }

    name_pre_claim_tx = %NamePreclaimTx{
      commitment_id: "cm_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      fee: 0,
      ttl: 0,
      account_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      nonce: 0
    }

    name_claim_tx = %NameClaimTx{
      name: "nm_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      name_salt: 123,
      fee: 0,
      ttl: 0,
      account_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      nonce: 0
    }

    name_revoke_tx = %NameRevokeTx{
      name_id: "nm_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      fee: 0,
      ttl: 0,
      account_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      nonce: 0
    }

    name_transfer_tx = %NameTransferTx{
      name_id: "nm_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      recipient_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      fee: 0,
      ttl: 0,
      account_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      nonce: 0
    }

    name_update_tx = %NameUpdateTx{
      name_id: "nm_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      name_ttl: 0,
      pointers: [],
      client_ttl: 0,
      fee: 0,
      ttl: 0,
      account_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      nonce: 0
    }

    contract_create_tx = %ContractCreateTx{
      owner_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      nonce: 0,
      code: "contract Identity =
               record state = { number : int }
               function init(x : int) =
                 { number = x }
               function add_to_number(x : int) = state.number + x",
      vm_version: 0x30001,
      abi_version: 0x30001,
      deposit: 1000,
      amount: 1000,
      gas: 10,
      gas_price: 1,
      fee: 0,
      ttl: 0,
      call_data: "call_data"
    }

    contract_call_tx = %ContractCallTx{
      caller_id: "ct_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      nonce: 0,
      contract_id: "ct_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      vm_version: 0x30001,
      abi_version: 0x30001,
      fee: 0,
      ttl: 0,
      amount: 1000,
      gas: 10,
      gas_price: 1,
      call_data: "call_data"
    }

    [
      spend_fields: spend_fields,
      oracle_register_fields: oracle_register_fields,
      oracle_query_fields: oracle_query_fields,
      oracle_response_fields: oracle_response_fields,
      oracle_extend_fields: oracle_extend_fields,
      name_claim_fields: name_claim_fields,
      name_preclaim_fields: name_preclaim_fields,
      name_revoke_fields: name_revoke_fields,
      name_update_fields: name_update_fields,
      name_transfer_fields: name_transfer_fields,
      contract_create_fields: contract_create_fields,
      contract_call_fields: contract_call_fields,
      spend_tx: spend_tx,
      oracle_register_tx: oracle_register_tx,
      oracle_respond_tx: oracle_respond_tx,
      oracle_query_tx: oracle_query_tx,
      oracle_extend_tx: oracle_extend_tx,
      name_pre_claim_tx: name_pre_claim_tx,
      name_claim_tx: name_claim_tx,
      name_revoke_tx: name_revoke_tx,
      name_transfer_tx: name_transfer_tx,
      name_update_tx: name_update_tx,
      contract_create_tx: contract_create_tx,
      contract_call_tx: contract_call_tx
    ]
  end

  test "serialization of valid fields doesn't raise error", fields do
    Serialization.serialize(fields.spend_fields, :spend_tx)
    Serialization.serialize(fields.oracle_register_fields, :oracle_register_tx)
    Serialization.serialize(fields.oracle_query_fields, :oracle_query_tx)
    Serialization.serialize(fields.oracle_response_fields, :oracle_response_tx)
    Serialization.serialize(fields.oracle_extend_fields, :oracle_extend_tx)
    Serialization.serialize(fields.name_claim_fields, :name_claim_tx)
    Serialization.serialize(fields.name_preclaim_fields, :name_preclaim_tx)
    Serialization.serialize(fields.name_update_fields, :name_update_tx)
    Serialization.serialize(fields.name_revoke_fields, :name_revoke_tx)
    Serialization.serialize(fields.name_transfer_fields, :name_transfer_tx)
    Serialization.serialize(fields.contract_create_fields, :contract_create_tx)
    Serialization.serialize(fields.contract_call_fields, :contract_call_tx)
  end

  test "serialization of invalid fields raises error", fields do
    assert_raise ErlangError,
                 "Erlang error: {:illegal_field, :sender_id, :id, \"invalid account\", :id, \"invalid account\"}",
                 fn ->
                   Serialization.serialize(
                     List.replace_at(fields.spend_fields, 0, "invalid account"),
                     :spend_tx
                   )
                 end

    assert_raise ErlangError,
                 "Erlang error: {:illegal_field, :amount, :int, \"invalid amount\", :int, \"invalid amount\"}",
                 fn ->
                   Serialization.serialize(
                     List.replace_at(fields.spend_fields, 2, "invalid amount"),
                     :spend_tx
                   )
                 end

    assert_raise ErlangError,
                 "Erlang error: {:illegal_field, :payload, :binary, 0, :binary, 0}",
                 fn ->
                   Serialization.serialize(
                     List.replace_at(fields.spend_fields, 6, 0),
                     :spend_tx
                   )
                 end

    assert_raise ErlangError,
                 "Erlang error: {:illegal_field, :pointers, [binary: :id], [{1, 2}, {\"a\", \"b\"}], :binary, 1}",
                 fn ->
                   Serialization.serialize(
                     List.replace_at(fields.name_update_fields, 4, [{1, 2}, {"a", "b"}]),
                     :name_update_tx
                   )
                 end
  end

  test "valid serialization of transactions", fields do
    Serialization.serialize(fields.spend_tx)
    Serialization.serialize(fields.oracle_register_tx)
    Serialization.serialize(fields.oracle_respond_tx)
    Serialization.serialize(fields.oracle_query_tx)
    Serialization.serialize(fields.oracle_extend_tx)
    Serialization.serialize(fields.name_pre_claim_tx)
    Serialization.serialize(fields.name_claim_tx)
    Serialization.serialize(fields.name_revoke_tx)
    Serialization.serialize(fields.name_update_tx)
    Serialization.serialize(fields.name_transfer_tx)
    Serialization.serialize(fields.contract_create_tx)
    Serialization.serialize(fields.contract_call_tx)
  end
end
