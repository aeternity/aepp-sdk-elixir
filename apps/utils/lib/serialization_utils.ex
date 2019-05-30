defmodule Utils.SerializationUtils do
  @moduledoc """
  Serialization helper module.
  """

  alias Utils.{Encoding, Keys}

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
    Ttl,
    ChannelCreateTx,
    ChannelCloseMutualTx,
    ChannelCloseSoloTx,
    ChannelDepositTx,
    ChannelForceProgressTx,
    ChannelSettleTx,
    ChannelSlashTx,
    ChannelSnapshotSoloTx,
    ChannelWithdrawTx
  }

  @ct_version 0x30001

  @doc """
  Serializes a transaction to a tuple of list of fields and type, depending on its structure.

  ## Examples
  iex> alias AeternityNode.Model.SpendTx
  AeternityNode.Model.SpendTx
  iex> spend_tx = %SpendTx{
      amount: 5_018_857_520_000_000_000,
      fee: 0,
      nonce: 37181,
      payload: "",
      recipient_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      sender_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
      ttl: 0
    }
  iex> Utils.SerializationUtils.process_tx_fields(spend_tx)
  {:ok,
    [{:id, :account,
    <<9, 51, 126, 98, 138, 255, 218, 224, 184, 180, 31, 234, 251, 255, 59, 141,
      224, 214, 250, 79, 248, 30, 246, 237, 55, 83, 153, 134, 240, 138, 216,
      129>>},
   {:id, :account,
    <<9, 51, 126, 98, 138, 255, 218, 224, 184, 180, 31, 234, 251, 255, 59, 141,
      224, 214, 250, 79, 248, 30, 246, 237, 55, 83, 153, 134, 240, 138, 216,
      129>>},
   5018857520000000000,
   0,
   0,
   37181,
   ""], :spend_tx}

  """
  @spec process_tx_fields(struct()) :: tuple()
  def process_tx_fields(%SpendTx{
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
     ], :spend_tx}
  end

  def process_tx_fields(%OracleRegisterTx{
        query_format: query_format,
        response_format: response_format,
        query_fee: query_fee,
        oracle_ttl: %Ttl{type: type, value: value},
        account_id: tx_account_id,
        nonce: nonce,
        fee: fee,
        ttl: ttl,
        abi_version: abi_version
      }) do
    account_id = proccess_id_to_record(tx_account_id)

    ttl_type =
      case type do
        :absolute -> 1
        :relative -> 0
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
     ], :oracle_register_tx}
  end

  def process_tx_fields(%OracleRespondTx{
        query_id: query_id,
        response: response,
        response_ttl: %RelativeTtl{type: _type, value: value},
        fee: fee,
        ttl: ttl,
        oracle_id: tx_oracle_id,
        nonce: nonce
      }) do
    oracle_id = proccess_id_to_record(tx_oracle_id)
    binary_query_id = Encoding.prefix_decode_base58c(query_id)

    {:ok,
     [
       oracle_id,
       nonce,
       binary_query_id,
       response,
       # Ttl type is always relative https://github.com/aeternity/aeternity/blob/master/apps/aeoracle/src/aeo_response_tx.erl#L48
       0,
       value,
       fee,
       ttl
     ], :oracle_response_tx}
  end

  def process_tx_fields(%OracleQueryTx{
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
        :absolute -> 1
        :relative -> 0
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
     ], :oracle_query_tx}
  end

  def process_tx_fields(%OracleExtendTx{
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
     ], :oracle_extend_tx}
  end

  def process_tx_fields(%NameClaimTx{
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
     ], :name_claim_tx}
  end

  def process_tx_fields(%NamePreclaimTx{
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
     ], :name_preclaim_tx}
  end

  def process_tx_fields(%NameUpdateTx{
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
     ], :name_update_tx}
  end

  def process_tx_fields(%NameRevokeTx{
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
     ], :name_revoke_tx}
  end

  def process_tx_fields(%NameTransferTx{
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
     ], :name_transfer_tx}
  end

  def process_tx_fields(%ContractCreateTx{
        owner_id: tx_owner_id,
        nonce: nonce,
        code: code,
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
     ], :contract_create_tx}
  end

  def process_tx_fields(%ContractCallTx{
        caller_id: tx_caller_id,
        nonce: nonce,
        contract_id: tx_contract_id,
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
     ], :contract_call_tx}
  end

  def process_tx_fields(%ChannelCreateTx{
        initiator_id: initiator,
        initiator_amount: initiator_amount,
        responder_id: responder,
        responder_amount: responder_amount,
        channel_reserve: channel_reserve,
        lock_period: lock_period,
        ttl: ttl,
        fee: fee,
        # delegate_ids: delegate_ids,
        state_hash: state_hash,
        nonce: nonce
      }) do
    initiator_id = proccess_id_to_record(initiator)
    responder_id = proccess_id_to_record(responder)

    # list_delegate_ids =
    #   for id <- delegate_ids do
    #     proccess_id_to_record(id)
    #   end

    {:ok,
     [
       initiator_id,
       initiator_amount,
       responder_id,
       responder_amount,
       channel_reserve,
       lock_period,
       ttl,
       fee,
       #  list_delegate_ids,
       # TODO: Have to be checked!!!
       state_hash,
       nonce
     ], :channel_create_tx}
  end

  def process_tx_fields(tx) do
    {:error, "Unknown or invalid tx: #{inspect(tx)}"}
  end

  defp proccess_id_to_record(tx_public_key) when is_binary(tx_public_key) do
    {type, public_key} =
      tx_public_key
      |> Keys.public_key_to_binary(:with_prefix)

    id =
      case type do
        "ak_" -> :account
        "ok_" -> :oracle
        "ct_" -> :contract
        "nm_" -> :name
        "cm_" -> :commitment
        "ch_" -> :channel
      end

    {:id, id, public_key}
  end
end
