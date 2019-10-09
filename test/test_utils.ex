defmodule TestUtils do
  alias AeppSDK.Client
  alias AeppSDK.Utils.Serialization

  alias AeternityNode.Model.{
    ContractCallTx,
    ContractCreateTx,
    NameClaimTx,
    NamePreclaimTx,
    NameRevokeTx,
    NameTransferTx,
    NameUpdateTx,
    OracleExtendTx,
    OracleQueryTx,
    OracleRegisterTx,
    OracleRespondTx,
    RelativeTtl,
    SpendTx,
    Ttl
  }

  def get_test_data do
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
      nonce: 37_181,
      payload: "",
      recipient_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      sender_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      ttl: 0
    }

    oracle_register_tx = %OracleRegisterTx{
      query_format: <<"query_format">>,
      response_format: <<"response_format">>,
      query_fee: 10,
      oracle_ttl: %Ttl{type: :absolute, value: 10},
      account_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      nonce: 37_122,
      fee: 0,
      ttl: 10,
      abi_version: 0x30001
    }

    oracle_respond_tx = %OracleRespondTx{
      query_id: "oq_u7sgmMQNjZQ4ffsN9sSmEhzqsag1iEfx8SkHDeG1y8EbDB5Aq",
      response: <<"response_format">>,
      response_ttl: %RelativeTtl{type: :relative, value: 10},
      fee: 0,
      ttl: 10,
      oracle_id: "ok_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      nonce: 0
    }

    oracle_query_tx = %OracleQueryTx{
      oracle_id: "ok_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      query: <<"query">>,
      query_fee: 10,
      query_ttl: %Ttl{type: :relative, value: 10},
      response_ttl: %RelativeTtl{type: "delta", value: 10},
      fee: 0,
      ttl: 10,
      sender_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      nonce: 0
    }

    oracle_extend_tx = %OracleExtendTx{
      fee: 0,
      oracle_ttl: %RelativeTtl{type: :relative, value: 10},
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
               entrypoint init(x : int) =
                 { number = x }
               entrypoint add_to_number(x : int) = state.number + x",
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
      abi_version: 0x30001,
      fee: 0,
      ttl: 0,
      amount: 1000,
      gas: 10,
      gas_price: 1,
      call_data: "call_data"
    }

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

    valid_pub_key = "ak_nv5B93FPzRHrGNmMdTDfGdd5xGZvep3MVSpJqzcQmMp59bBCv"
    amount = 40_000_000

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
      contract_call_tx: contract_call_tx,
      client: client,
      valid_pub_key: valid_pub_key,
      amount: amount
    ]
  end
end
