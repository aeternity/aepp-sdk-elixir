defmodule Utils.Serialization do
  @moduledoc """
  false
  """
  alias Utils.Keys

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

  @tag_signed_tx 11
  @tag_spend_tx 12
  @tag_oracle_register_tx 22
  @tag_oracle_query_tx 23
  @tag_oracle_response_tx 24
  @tag_oracle_extend_tx 25
  @tag_name_claim_tx 32
  @tag_name_preclaim_tx 33
  @tag_name_update_tx 34
  @tag_name_revoke_tx 35
  @tag_name_transfer_tx 36
  @tag_contract_create_tx 42
  @tag_contract_call_tx 43

  @version_signed_tx 1
  @version_spend_tx 1
  @version_oracle_register_tx 1
  @version_oracle_query_tx 1
  @version_oracle_response_tx 1
  @version_oracle_extend_tx 1
  @version_name_claim_tx 1
  @version_name_preclaim_tx 1
  @version_name_update_tx 1
  @version_name_revoke_tx 1
  @version_name_transfer_tx 1
  @version_contract_create_tx 1
  @version_contract_call_tx 1

  @type structure_type ::
          :signed_tx
          | :spend_tx
          | :oracle_register_tx
          | :oracle_query_tx
          | :oracle_response_tx
          | :oracle_extend_tx
          | :name_claim_tx
          | :name_preclaim_tx
          | :name_update_tx
          | :name_revoke_tx
          | :name_transfer_tx
          | :contract_create_tx
          | :contract_call_tx

  @type tx_type ::
          SpendTx
          | OracleRegisterTx
          | OracleRespondTx
          | OracleQueryTx
          | OracleExtendTx
          | NamePreclaimTx
          | NameClaimTx
          | NameRevokeTx
          | NameTransferTx
          | NameUpdateTx
          | ContractCreateTx
          | ContractCallTx

  @type id :: {:id, id_type(), binary()}
  @type id_type :: :account | :oracle | :name | :commitment | :contract | :channel

  @type rlp_binary :: binary()

  @ct_version 0x30001

  @spec serialize(list(), structure_type()) :: rlp_binary()
  def serialize(fields, type) when is_list(fields) do
    process_serialize(fields, type)
  end

  @spec serialize(tx_type(), structure_type()) :: rlp_binary()
  def serialize(tx, type)
      when type in [
             :signed_tx,
             :spend_tx,
             :oracle_register_tx,
             :oracle_query_tx,
             :oracle_extend_tx,
             :oracle_response_tx,
             :name_claim_tx,
             :name_preclaim_tx,
             :name_update_tx,
             :name_revoke_tx,
             :name_transfer_tx,
             :contract_create_tx,
             :contract_call_tx
           ] do
    {:ok, fields} = process_tx_fields(tx)
    process_serialize(fields, type)
  end

  # this is the way the id record is represented in erlang
  @spec id_to_record(binary(), id_type()) :: id()
  def id_to_record(value, type)
      when type in [:account, :oracle, :name, :commitment, :contract, :channel],
      do: {:id, type, value}

  defp process_tx_fields(%SpendTx{
         recipient_id: tx_recipient_id,
         amount: amount,
         fee: fee,
         ttl: ttl,
         sender_id: tx_sender_id,
         nonce: nonce,
         payload: payload
       }) do
    sender_id = proccess_id_to_record(tx_sender_id)
    recipient_id = proccess_id_to_record(tx_recipient_id)

    {:ok,
     [
       sender_id,
       recipient_id,
       amount,
       fee,
       ttl,
       nonce,
       payload
     ]}
  end

  defp process_tx_fields(%OracleRegisterTx{
         query_format: query_format,
         response_format: response_format,
         query_fee: query_fee,
         oracle_ttl: %Ttl{type: type, value: value},
         account_id: tx_account_id,
         nonce: nonce,
         fee: fee,
         ttl: ttl,
         vm_version: _vm_version,
         abi_version: abi_version
       }) do
    account_id = proccess_id_to_record(tx_account_id)

    ttl_type =
      case type do
        "block" -> 1
        "delta" -> 0
      end

    {:ok,
     [
       account_id,
       nonce,
       query_format,
       response_format,
       query_fee,
       ttl_type,
       value,
       fee,
       ttl,
       abi_version
     ]}
  end

  defp process_tx_fields(%OracleRespondTx{
         query_id: query_id,
         response: response,
         response_ttl: %RelativeTtl{type: _type, value: value},
         fee: fee,
         ttl: ttl,
         oracle_id: tx_oracle_id,
         nonce: nonce
       }) do
    oracle_id = proccess_id_to_record(tx_oracle_id)

    {:ok,
     [
       oracle_id,
       nonce,
       query_id,
       response,
       # Ttl type is always relative https://github.com/aeternity/aeternity/blob/master/apps/aeoracle/src/aeo_response_tx.erl#L48
       0,
       value,
       fee,
       ttl
     ]}
  end

  defp process_tx_fields(%OracleQueryTx{
         oracle_id: tx_oracle_id,
         query: query,
         query_fee: query_fee,
         query_ttl: %Ttl{type: query_type, value: query_value},
         response_ttl: %RelativeTtl{type: _response_type, value: response_value},
         fee: fee,
         ttl: ttl,
         sender_id: tx_sender_id,
         nonce: nonce
       }) do
    sender_id = proccess_id_to_record(tx_sender_id)
    oracle_id = proccess_id_to_record(tx_oracle_id)

    query_ttl_type =
      case query_type do
        "block" -> 1
        "delta" -> 0
      end

    {:ok,
     [
       sender_id,
       nonce,
       oracle_id,
       query,
       query_fee,
       query_ttl_type,
       query_value,
       # Ttl type is always relative https://github.com/aeternity/aeternity/blob/master/apps/aeoracle/src/aeo_query_tx.erl#L54
       0,
       response_value,
       fee,
       ttl
     ]}
  end

  defp process_tx_fields(%OracleExtendTx{
         fee: fee,
         oracle_ttl: %RelativeTtl{type: _type, value: value},
         oracle_id: tx_oracle_id,
         nonce: nonce,
         ttl: ttl
       }) do
    oracle_id = proccess_id_to_record(tx_oracle_id)

    {:ok,
     [
       oracle_id,
       nonce,
       # Ttl type is always relative https://github.com/aeternity/aeternity/blob/master/apps/aeoracle/src/aeo_extend_tx.erl#L43
       0,
       value,
       fee,
       ttl
     ]}
  end

  defp process_tx_fields(%NameClaimTx{
         name: name,
         name_salt: name_salt,
         fee: fee,
         ttl: ttl,
         account_id: tx_account_id,
         nonce: nonce
       }) do
    account_id = proccess_id_to_record(tx_account_id)

    {:ok,
     [
       account_id,
       nonce,
       name,
       name_salt,
       fee,
       ttl
     ]}
  end

  defp process_tx_fields(%NamePreclaimTx{
         commitment_id: tx_commitment_id,
         fee: fee,
         ttl: ttl,
         account_id: tx_account_id,
         nonce: nonce
       }) do
    account_id = proccess_id_to_record(tx_account_id)
    commitment_id = proccess_id_to_record(tx_commitment_id)

    {:ok,
     [
       account_id,
       nonce,
       commitment_id,
       fee,
       ttl
     ]}
  end

  defp process_tx_fields(%NameUpdateTx{
         name_id: tx_name_id,
         name_ttl: name_ttl,
         pointers: pointers,
         client_ttl: client_ttl,
         fee: fee,
         ttl: ttl,
         account_id: tx_account_id,
         nonce: nonce
       }) do
    account_id = proccess_id_to_record(tx_account_id)
    name_id = proccess_id_to_record(tx_name_id)

    {:ok,
     [
       account_id,
       nonce,
       name_id,
       name_ttl,
       pointers,
       client_ttl,
       fee,
       ttl
     ]}
  end

  defp process_tx_fields(%NameRevokeTx{
         name_id: tx_name_id,
         fee: fee,
         ttl: ttl,
         account_id: tx_account_id,
         nonce: nonce
       }) do
    account_id = proccess_id_to_record(tx_account_id)
    name_id = proccess_id_to_record(tx_name_id)

    {:ok,
     [
       account_id,
       nonce,
       name_id,
       fee,
       ttl
     ]}
  end

  defp process_tx_fields(%NameTransferTx{
         name_id: tx_name_id,
         recipient_id: tx_recipient_id,
         fee: fee,
         ttl: ttl,
         account_id: tx_account_id,
         nonce: nonce
       }) do
    account_id = proccess_id_to_record(tx_account_id)
    name_id = proccess_id_to_record(tx_name_id)
    recipient_id = proccess_id_to_record(tx_recipient_id)

    {:ok,
     [
       account_id,
       nonce,
       name_id,
       recipient_id,
       fee,
       ttl
     ]}
  end

  defp process_tx_fields(%ContractCreateTx{
         owner_id: tx_owner_id,
         nonce: nonce,
         code: code,
         vm_version: _vm_version,
         abi_version: _abi_version,
         deposit: deposit,
         amount: amount,
         gas: gas,
         gas_price: gas_price,
         fee: fee,
         ttl: ttl,
         call_data: call_data
       }) do
    owner_id = proccess_id_to_record(tx_owner_id)

    {:ok,
     [
       owner_id,
       nonce,
       code,
       @ct_version,
       fee,
       ttl,
       deposit,
       amount,
       gas,
       gas_price,
       call_data
     ]}
  end

  defp process_tx_fields(%ContractCallTx{
         caller_id: tx_caller_id,
         nonce: nonce,
         contract_id: tx_contract_id,
         vm_version: _vm_version,
         abi_version: abi_version,
         fee: fee,
         ttl: ttl,
         amount: amount,
         gas: gas,
         gas_price: gas_price,
         call_data: call_data
       }) do
    caller_id = proccess_id_to_record(tx_caller_id)
    contract_id = proccess_id_to_record(tx_contract_id)

    {:ok,
     [
       caller_id,
       nonce,
       contract_id,
       abi_version,
       fee,
       ttl,
       amount,
       gas,
       gas_price,
       call_data
     ]}
  end

  defp process_tx_fields(tx) do
    {:error, "Unknown or invalid tx: #{inspect(tx)}"}
  end

  defp proccess_id_to_record(tx_pubkey) when is_binary(tx_pubkey) do
    {type, pubkey} =
      tx_pubkey
      |> Keys.pubkey_to_binary(:with_prefix)

    id =
      case type do
        "ak_" -> :account
        "ok_" -> :oracle
        "ct_" -> :contract
        "nm_" -> :name
        "cm_" -> :commitment
        "ch_" -> :channel
      end

    {:id, id, pubkey}
  end

  defp process_serialize(fields, type) do
    template = serialization_template(type)
    fields_with_keys = set_keys(fields, template, [])
    tag = type_to_tag(type)
    version = version(type)
    :aeserialization.serialize(tag, version, template, fields_with_keys)
  end

  defp set_keys([field | rest_fields], [{key, _type} | rest_template], fields_with_keys),
    do: set_keys(rest_fields, rest_template, [{key, field} | fields_with_keys])

  defp set_keys([], [], fields_with_keys), do: Enum.reverse(fields_with_keys)

  defp serialization_template(:signed_tx) do
    [
      signatures: [:binary],
      transaction: :binary
    ]
  end

  defp serialization_template(:spend_tx) do
    [
      sender_id: :id,
      recipient_id: :id,
      amount: :int,
      fee: :int,
      ttl: :int,
      nonce: :int,
      payload: :binary
    ]
  end

  defp serialization_template(:oracle_register_tx) do
    [
      account_id: :id,
      nonce: :int,
      query_format: :binary,
      response_format: :binary,
      query_fee: :int,
      ttl_type: :int,
      ttl_value: :int,
      fee: :int,
      ttl: :int,
      abi_version: :int
    ]
  end

  defp serialization_template(:oracle_query_tx) do
    [
      sender_id: :id,
      nonce: :int,
      oracle_id: :id,
      query: :binary,
      query_fee: :int,
      query_ttl_type: :int,
      query_ttl_value: :int,
      response_ttl_type: :int,
      response_ttl_value: :int,
      fee: :int,
      ttl: :int
    ]
  end

  defp serialization_template(:oracle_response_tx) do
    [
      oracle_id: :id,
      nonce: :int,
      query_id: :binary,
      response: :binary,
      response_ttl_type: :int,
      response_ttl_value: :int,
      fee: :int,
      ttl: :int
    ]
  end

  defp serialization_template(:oracle_extend_tx) do
    [
      oracle_id: :id,
      nonce: :int,
      oracle_ttl_type: :int,
      oracle_ttl_value: :int,
      fee: :int,
      ttl: :int
    ]
  end

  defp serialization_template(:name_claim_tx) do
    [account_id: :id, nonce: :int, name: :binary, name_salt: :int, fee: :int, ttl: :int]
  end

  defp serialization_template(:name_preclaim_tx) do
    [account_id: :id, nonce: :int, commitment_id: :id, fee: :int, ttl: :int]
  end

  defp serialization_template(:name_update_tx) do
    [
      account_id: :id,
      nonce: :int,
      name_id: :id,
      name_ttl: :int,
      pointers: [{:binary, :id}],
      client_ttl: :int,
      fee: :int,
      ttl: :int
    ]
  end

  defp serialization_template(:name_revoke_tx) do
    [account_id: :id, nonce: :int, name_id: :id, fee: :int, ttl: :int]
  end

  defp serialization_template(:name_transfer_tx) do
    [account_id: :id, nonce: :int, name_id: :id, recipient_id: :id, fee: :int, ttl: :int]
  end

  defp serialization_template(:contract_create_tx) do
    [
      owner_id: :id,
      nonce: :int,
      code: :binary,
      ct_version: :int,
      fee: :int,
      ttl: :int,
      deposit: :int,
      amount: :int,
      gas: :int,
      gas_price: :int,
      call_data: :binary
    ]
  end

  defp serialization_template(:contract_call_tx) do
    [
      caller_id: :id,
      nonce: :int,
      contract_id: :id,
      abi_version: :int,
      fee: :int,
      ttl: :int,
      amount: :int,
      gas: :int,
      gas_price: :int,
      call_data: :binary
    ]
  end

  defp type_to_tag(:signed_tx), do: @tag_signed_tx
  defp type_to_tag(:spend_tx), do: @tag_spend_tx
  defp type_to_tag(:oracle_register_tx), do: @tag_oracle_register_tx
  defp type_to_tag(:oracle_query_tx), do: @tag_oracle_query_tx
  defp type_to_tag(:oracle_response_tx), do: @tag_oracle_response_tx
  defp type_to_tag(:oracle_extend_tx), do: @tag_oracle_extend_tx
  defp type_to_tag(:name_claim_tx), do: @tag_name_claim_tx
  defp type_to_tag(:name_preclaim_tx), do: @tag_name_preclaim_tx
  defp type_to_tag(:name_update_tx), do: @tag_name_update_tx
  defp type_to_tag(:name_revoke_tx), do: @tag_name_revoke_tx
  defp type_to_tag(:name_transfer_tx), do: @tag_name_transfer_tx
  defp type_to_tag(:contract_create_tx), do: @tag_contract_create_tx
  defp type_to_tag(:contract_call_tx), do: @tag_contract_call_tx

  defp version(:signed_tx), do: @version_signed_tx
  defp version(:spend_tx), do: @version_spend_tx
  defp version(:oracle_register_tx), do: @version_oracle_register_tx
  defp version(:oracle_query_tx), do: @version_oracle_query_tx
  defp version(:oracle_response_tx), do: @version_oracle_response_tx
  defp version(:oracle_extend_tx), do: @version_oracle_extend_tx
  defp version(:name_claim_tx), do: @version_name_claim_tx
  defp version(:name_preclaim_tx), do: @version_name_preclaim_tx
  defp version(:name_update_tx), do: @version_name_update_tx
  defp version(:name_revoke_tx), do: @version_name_revoke_tx
  defp version(:name_transfer_tx), do: @version_name_transfer_tx
  defp version(:contract_create_tx), do: @version_contract_create_tx
  defp version(:contract_call_tx), do: @version_contract_call_tx
end
