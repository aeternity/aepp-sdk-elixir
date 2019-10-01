defmodule AeppSDK.Utils.SerializationUtils do
  @moduledoc false

  alias AeppSDK.Utils.{Encoding, Keys}

  alias AeternityNode.Model.{
    ChannelCloseMutualTx,
    ChannelCloseSoloTx,
    ChannelCreateTx,
    ChannelDepositTx,
    ChannelForceProgressTx,
    ChannelSettleTx,
    ChannelSlashTx,
    ChannelSnapshotSoloTx,
    ChannelWithdrawTx,
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

  @ct_version 0x40001

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
        name_fee: name_fee,
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
       name_fee,
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
        delegate_ids: delegate_ids,
        state_hash: <<"st_", state_hash::binary>>,
        nonce: nonce
      }) do
    decoded_state_hash = Encoding.decode_base58c(state_hash)
    initiator_id = proccess_id_to_record(initiator)
    responder_id = proccess_id_to_record(responder)

    list_delegate_ids =
      for id <- delegate_ids do
        proccess_id_to_record(id)
      end

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
       list_delegate_ids,
       decoded_state_hash,
       nonce
     ], :channel_create_tx}
  end

  def process_tx_fields(%ChannelCloseMutualTx{
        channel_id: channel,
        fee: fee,
        from_id: from,
        initiator_amount_final: initiator_amount_final,
        nonce: nonce,
        responder_amount_final: responder_amount_final,
        ttl: ttl
      }) do
    channel_id = proccess_id_to_record(channel)
    from_id = proccess_id_to_record(from)

    {:ok,
     [
       channel_id,
       from_id,
       initiator_amount_final,
       responder_amount_final,
       ttl,
       fee,
       nonce
     ], :channel_close_mutual_tx}
  end

  def process_tx_fields(%ChannelCloseSoloTx{
        channel_id: channel,
        fee: fee,
        from_id: from,
        nonce: nonce,
        payload: payload,
        poi: poi,
        ttl: ttl
      }) do
    channel_id = proccess_id_to_record(channel)
    from_id = proccess_id_to_record(from)

    {:ok,
     [
       channel_id,
       from_id,
       payload,
       poi,
       ttl,
       fee,
       nonce
     ], :channel_close_solo_tx}
  end

  def process_tx_fields(%ChannelDepositTx{
        amount: amount,
        channel_id: channel,
        fee: fee,
        from_id: from,
        nonce: nonce,
        round: round,
        state_hash: <<"st_", state_hash::binary>>,
        ttl: ttl
      }) do
    decoded_state_hash = Encoding.decode_base58c(state_hash)
    channel_id = proccess_id_to_record(channel)
    from_id = proccess_id_to_record(from)

    {:ok,
     [
       channel_id,
       from_id,
       amount,
       ttl,
       fee,
       decoded_state_hash,
       round,
       nonce
     ], :channel_deposit_tx}
  end

  def process_tx_fields(%ChannelForceProgressTx{
        channel_id: channel,
        fee: fee,
        from_id: from,
        nonce: nonce,
        offchain_trees: offchain_trees,
        payload: payload,
        round: round,
        state_hash: <<"st_", state_hash::binary>>,
        ttl: ttl,
        update: update
      }) do
    decoded_state_hash = Encoding.decode_base58c(state_hash)
    channel_id = proccess_id_to_record(channel)
    from_id = proccess_id_to_record(from)

    {:ok,
     [
       channel_id,
       from_id,
       payload,
       round,
       update,
       decoded_state_hash,
       offchain_trees,
       ttl,
       fee,
       nonce
     ], :channel_force_progress_tx}
  end

  def process_tx_fields(%ChannelSettleTx{
        channel_id: channel,
        fee: fee,
        from_id: from,
        initiator_amount_final: initiator_amount_final,
        nonce: nonce,
        responder_amount_final: responder_amount_final,
        ttl: ttl
      }) do
    channel_id = proccess_id_to_record(channel)
    from_id = proccess_id_to_record(from)

    {:ok, [channel_id, from_id, initiator_amount_final, responder_amount_final, ttl, fee, nonce],
     :channel_settle_tx}
  end

  def process_tx_fields(%ChannelSlashTx{
        channel_id: channel,
        fee: fee,
        from_id: from,
        nonce: nonce,
        payload: payload,
        poi: poi,
        ttl: ttl
      }) do
    channel_id = proccess_id_to_record(channel)
    from_id = proccess_id_to_record(from)

    {:ok,
     [
       channel_id,
       from_id,
       payload,
       poi,
       ttl,
       fee,
       nonce
     ], :channel_slash_tx}
  end

  def process_tx_fields(%ChannelSnapshotSoloTx{
        channel_id: channel,
        from_id: from,
        payload: payload,
        ttl: ttl,
        fee: fee,
        nonce: nonce
      }) do
    channel_id = proccess_id_to_record(channel)
    from_id = proccess_id_to_record(from)

    {:ok, [channel_id, from_id, payload, ttl, fee, nonce], :channel_snapshot_solo_tx}
  end

  def process_tx_fields(%ChannelWithdrawTx{
        channel_id: channel,
        to_id: to,
        amount: amount,
        ttl: ttl,
        fee: fee,
        nonce: nonce,
        state_hash: <<"st_", state_hash::binary>>,
        round: round
      }) do
    decoded_state_hash = Encoding.decode_base58c(state_hash)
    channel_id = proccess_id_to_record(channel)
    to_id = proccess_id_to_record(to)

    {:ok, [channel_id, to_id, amount, ttl, fee, decoded_state_hash, round, nonce],
     :channel_withdraw_tx}
  end

  def process_tx_fields(%{
        owner_id: owner_id,
        nonce: nonce,
        code: code,
        auth_fun: auth_fun,
        ct_version: ct_version,
        fee: fee,
        ttl: ttl,
        gas: gas,
        gas_price: gas_price,
        call_data: call_data
      }) do
    owner_id_record = proccess_id_to_record(owner_id)

    {:ok,
     [
       owner_id_record,
       nonce,
       code,
       auth_fun,
       ct_version,
       fee,
       ttl,
       gas,
       gas_price,
       call_data
     ], :ga_attach_tx}
  end

  def process_tx_fields(%{
        ga_id: ga_id,
        auth_data: auth_data,
        abi_version: abi_version,
        fee: fee,
        gas: gas,
        gas_price: gas_price,
        ttl: ttl,
        tx: tx
      }) do
    ga_id_record = proccess_id_to_record(ga_id)

    {:ok,
     [
       ga_id_record,
       auth_data,
       abi_version,
       fee,
       gas,
       gas_price,
       ttl,
       tx
     ], :ga_meta_tx}
  end

  def process_tx_fields(%{
        channel_id: channel_id,
        round: round,
        state_hash: <<"st_", state_hash::binary>>,
        version: 1,
        updates: updates
      }) do
    channel_id_record = proccess_id_to_record(channel_id)
    decoded_state_hash = Encoding.decode_base58c(state_hash)

    {:ok,
     [
       channel_id_record,
       round,
       updates,
       decoded_state_hash
     ], :channel_offchain_tx}
  end

  def process_tx_fields(%{
        channel_id: channel_id,
        round: round,
        state_hash: <<"st_", state_hash::binary>>,
        version: 2
      }) do
    channel_id_record = proccess_id_to_record(channel_id)
    decoded_state_hash = Encoding.decode_base58c(state_hash)

    {:ok,
     [
       channel_id_record,
       round,
       decoded_state_hash
     ], :channel_offchain_tx_no_updates}
  end

  def process_tx_fields(tx) do
    {:error, "Unknown or invalid tx: #{inspect(tx)}"}
  end

  def ttl_type_for_client(type) do
    case type do
      0 ->
        :relative

      1 ->
        :absolute
    end
  end

  defp proccess_id_to_record(id) when is_binary(id) do
    {type, binary_data} =
      id
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

    {:id, id, binary_data}
  end
end
