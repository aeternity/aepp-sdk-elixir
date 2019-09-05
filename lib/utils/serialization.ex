defmodule AeppSDK.Utils.Serialization do
  @moduledoc """
  Transaction serialization.
  """
  alias AeppSDK.Utils.SerializationUtils

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
  @tag_sophia_byte_code 70
  @tag_ga_attach_tx 80
  @tag_ga_meta_tx 81

  @tag_channel_create_tx 50
  @tag_channel_deposit_tx 51
  @tag_channel_withdraw_tx 52
  @tag_channel_close_mutual_tx 53
  @tag_channel_close_solo_tx 54
  @tag_channel_slash_tx 55
  @tag_channel_settle_tx 56
  @tag_channel_snapshot_solo_tx 59
  @tag_channel_force_progress_tx 521
  @tag_channel_offchain_update_transfer 570
  @tag_channel_offchain_update_deposit 571
  @tag_channel_offchain_update_withdraw 572
  @tag_channel_offchain_update_create_contract 573
  @tag_channel_offchain_update_call_contract 574

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
  @version_sophia_byte_code 1
  @version_ga_attach_tx 1
  @version_ga_meta_tx 1

  @version_channel_create_tx 1
  @version_channel_deposit_tx 1
  @version_channel_withdraw_tx 1
  @version_channel_close_mutual_tx 1
  @version_channel_close_solo_tx 1
  @version_channel_slash_tx 1
  @version_channel_settle_tx 1
  @version_channel_snapshot_solo_tx 1
  @version_channel_force_progress_tx 1
  @version_poi 1
  @all_trees_names [:accounts, :calls, :channels, :contracts, :ns, :oracles]
  @empty_tree_hash <<0::256>>

  @type state_hash :: binary()
  @type poi_keyword ::
          [
            {:accounts, {state_hash(), map()}},
            {:calls, {state_hash(), map()}},
            {:channels, {state_hash(), map()}},
            {:contracts, {state_hash(), map()}},
            {:ns, {state_hash, map()}},
            {:oracles, {state_hash(), map()}}
          ]
  @version_channel_offchain_update_transfer 1
  @version_channel_offchain_update_deposit 1
  @version_channel_offchain_update_withdraw 1
  @version_channel_offchain_update_create_contract 1
  @version_channel_offchain_update_call_contract 1

  @channel_offchain_update_transfer_name "OffChainTransfer"
  @channel_offchain_update_deposit_name "OffChainDeposit"
  @channel_offchain_update_withdraw_name "OffChainWithdrawal"
  @channel_offchain_update_create_contract_name "OffChainNewContract"
  @channel_offchain_update_call_contract_name "OffChainCallContract"
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
          | :sophia_byte_code
          | :channel_create_tx
          | :channel_deposit_tx
          | :channel_withdraw_tx
          | :channel_close_mutual_tx
          | :channel_close_solo_tx
          | :channel_slash_tx
          | :channel_settle_tx
          | :channel_snapshot_solo_tx
          | :channel_force_progress_tx
          | :transfer_update
          | :deposit_update
          | :withdraw_update
          | :create_contract_update
          | :call_contract_update

  @type tx_type ::
          AeternityNode.Model.SpendTx.t()
          | AeternityNode.Model.OracleRegisterTx.t()
          | AeternityNode.Model.OracleRespondTx.t()
          | AeternityNode.Model.OracleQueryTx.t()
          | AeternityNode.Model.OracleExtendTx.t()
          | AeternityNode.Model.NamePreclaimTx.t()
          | AeternityNode.Model.NameClaimTx.t()
          | AeternityNode.Model.NameRevokeTx.t()
          | AeternityNode.Model.NameTransferTx.t()
          | AeternityNode.Model.NameUpdateTx.t()
          | AeternityNode.Model.ContractCreateTx.t()
          | AeternityNode.Model.ContractCallTx.t()
          | AeternityNode.Model.ChannelCreateTx.t()
          | AeternityNode.Model.ChannelCloseMutualTx.t()
          | AeternityNode.Model.ChannelCloseSoloTx.t()
          | AeternityNode.Model.ChannelDepositTx.t()
          | AeternityNode.Model.ChannelForceProgressTx.t()
          | AeternityNode.Model.ChannelSettleTx.t()
          | AeternityNode.Model.ChannelSlashTx.t()
          | AeternityNode.Model.ChannelSnapshotSoloTx.t()
          | AeternityNode.Model.ChannelWithdrawTx.t()

  @type id :: {:id, id_type(), binary()}
  @type id_type :: :account | :oracle | :name | :commitment | :contract | :channel

  @type rlp_binary :: binary()

  @doc """
  Serializes a list of fields with the template corresponding to the given type

  ## Example
      iex> fields = [{:id, :account,
          <<11, 180, 237, 121, 39, 249, 123, 81, 225, 188, 181, 225, 52, 13, 18, 51,
            91, 42, 43, 18, 200, 188, 82, 33, 214, 60, 75, 203, 57, 212, 30, 97>>},
         8579,
         {:id, :contract,
          <<64, 216, 143, 81, 41, 52, 245, 89, 135, 253, 7, 12, 94, 142, 96, 251, 212,
            96, 76, 248, 1, 152, 97, 16, 144, 62, 43, 186, 148, 174, 76, 114>>},
         1,
         2000000000000000000,
         0,
         0,
         1000000,
         1000000000,
         <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 32, 112, 194, 27, 63, 171, 248, 210, 119, 144, 238, 34,
           30, 100, 222, 2, 111, 12, 11, 11, 82, 86, 82, 53, 206, 145, 155, 60, 13,
           206, 214, 183, 62, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
           0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 33>>]
          iex> type = :contract_call_tx
          iex> AeppSDK.Utils.Serialization.serialize(fields, type)
          <<248, 224, 43, 1, 161, 1, 11, 180, 237, 121, 39, 249, 123, 81, 225, 188, 181,
          225, 52, 13, 18, 51, 91, 42, 43, 18, 200, 188, 82, 33, 214, 60, 75, 203, 57,
          212, 30, 97, 130, 33, 131, 161, 5, 64, 216, 143, 81, 41, 52, 245, 89, 135,
          253, 7, 12, 94, 142, 96, 251, 212, 96, 76, 248, 1, 152, 97, 16, 144, 62, 43,
          186, 148, 174, 76, 114, 1, 136, 27, 193, 109, 103, 78, 200, 0, 0, 0, 0, 131,
          15, 66, 64, 132, 59, 154, 202, 0, 184, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 112, 194, 27,
          63, 171, 248, 210, 119, 144, 238, 34, 30, 100, 222, 2, 111, 12, 11, 11, 82,
          86, 82, 53, 206, 145, 155, 60, 13, 206, 214, 183, 62, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 33>>
  """
  @spec serialize(list(), structure_type()) :: rlp_binary()
  def serialize(fields, type) when is_list(fields) do
    process_serialize(fields, type)
  end

  @doc """
  Serializes a transaction to a binary.

  ## Example
      iex> alias AeternityNode.Model.{Ttl,OracleRegisterTx}
      iex> AeppSDK.Utils.Serialization.serialize( %OracleRegisterTx{
           query_format: <<"query_format">>,
           response_format: <<"response_format">>,
           query_fee: 10,
           oracle_ttl: %Ttl{type: :absolute, value: 10},
           account_id: "ak_542o93BKHiANzqNaFj6UurrJuDuxU61zCGr9LJCwtTUg34kWt",
           nonce: 37122,
           fee: 0,
           ttl: 10,
           abi_version: 0x30001
         })
       <<248, 77, 22, 1, 161, 1, 9, 51, 126, 98, 138, 255, 218, 224, 184, 180, 31, 234,
        251, 255, 59, 141, 224, 214, 250, 79, 248, 30, 246, 237, 55, 83, 153, 134,
        240, 138, 216, 129, 130, 145, 2, 140, 113, 117, 101, 114, 121, 95, 102, 111,
        ...>>
  """
  @spec serialize(tx_type()) :: rlp_binary()
  def serialize(tx) do
    {:ok, fields, type} = SerializationUtils.process_tx_fields(tx)
    process_serialize(fields, type)
  end

  def serialize_for_client(tx, type) do
    serialized_tx = serialize_for_client(tx)
    Map.put(serialized_tx, :type, type)
  end

  @doc """
  Deserialize an RLP binary payload with the template corresponding to the given type

  ## Example
      iex> payload = <<248, 224, 43, 1, 161, 1, 11, 180, 237, 121, 39, 249, 123, 81, 225, 188, 181,
          225, 52, 13, 18, 51, 91, 42, 43, 18, 200, 188, 82, 33, 214, 60, 75, 203, 57,
          212, 30, 97, 130, 33, 131, 161, 5, 64, 216, 143, 81, 41, 52, 245, 89, 135,
          253, 7, 12, 94, 142, 96, 251, 212, 96, 76, 248, 1, 152, 97, 16, 144, 62, 43,
          186, 148, 174, 76, 114, 1, 136, 27, 193, 109, 103, 78, 200, 0, 0, 0, 0, 131,
          15, 66, 64, 132, 59, 154, 202, 0, 184, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 112, 194, 27,
          63, 171, 248, 210, 119, 144, 238, 34, 30, 100, 222, 2, 111, 12, 11, 11, 82,
          86, 82, 53, 206, 145, 155, 60, 13, 206, 214, 183, 62, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 33>>
      iex> type = :contract_call_tx
      iex> AeppSDK.Utils.Serialization.deserialize(payload, type)
      [
        caller_id: {:id, :account,
         <<11, 180, 237, 121, 39, 249, 123, 81, 225, 188, 181, 225, 52, 13, 18, 51,
           91, 42, 43, 18, 200, 188, 82, 33, 214, 60, 75, 203, 57, 212, 30, 97>>},
        nonce: 8579,
        contract_id: {:id, :contract,
         <<64, 216, 143, 81, 41, 52, 245, 89, 135, 253, 7, 12, 94, 142, 96, 251, 212,
           96, 76, 248, 1, 152, 97, 16, 144, 62, 43, 186, 148, 174, 76, 114>>},
        abi_version: 1,
        fee: 2000000000000000000,
        ttl: 0,
        amount: 0,
        gas: 1000000,
        gas_price: 1000000000,
        call_data: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 32, 112, 194, 27, 63, 171, 248, 210, 119, 144,
          238, 34, 30, 100, 222, 2, 111, 12, 11, 11, 82, 86, 82, 53, 206, 145, 155,
          60, 13, 206, 214, 183, 62, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 96, 0, 0, 0, 0, 0, 0, 0, 0, 0,
          0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 33>>
      ]
  """
  @spec deserialize(binary(), structure_type()) :: list()
  def deserialize(payload, type) do
    template = serialization_template(type)
    tag = type_to_tag(type)
    version = version(type)

    :aeserialization.deserialize(type, tag, version, template, payload)
  end

  # this is the way the id record is represented in erlang
  @spec id_to_record(binary(), id_type()) :: id()
  def id_to_record(value, type)
      when type in [:account, :oracle, :name, :commitment, :contract, :channel],
      do: {:id, type, value}

  @doc """
  Serializes a Proof-of-Inclusion to a binary.

  ## Example
      iex> poi = [
          accounts: {<<148, 112, 174, 4, 233, 253, 29, 65, 31, 17, 40, 153, 167, 18, 37,
          179, 35, 141, 97, 95, 132, 162, 158, 78, 103, 11, 230, 39, 208, 27, 176,111>>, %{cache: {0, nil}}}
         ]
      iex> AeppSDK.Utils.Serialization.serialize_poi poi
      <<235, 60, 1, 227, 226, 160, 148, 112, 174, 4, 233, 253, 29, 65, 31,
      17, 40, 153, 167, 18, 37, 179, 35, 141, 97, 95, 132, 162, 158, 78,
      103, 11, 230, 39, 208, 27, 176, 111, 192, 192, 192, 192, 192, 192>>
  """
  @spec serialize_poi(poi_keyword()) :: binary()
  def serialize_poi(state_hashes_list) when is_list(state_hashes_list) do
    fields =
      for tree_name <- @all_trees_names do
        {state_hash, proof_db} =
          Keyword.get(state_hashes_list, tree_name, {@empty_tree_hash, %{cache: {0, nil}}})

        {tree_name, serialize_poi(state_hash, proof_db)}
      end

    :aeser_chain_objects.serialize(
      :trees_poi,
      version(:poi),
      serialization_template(:poi),
      fields
    )
  end

  defp serialize_poi(@empty_tree_hash, _proof_db) do
    []
  end

  defp serialize_poi(<<_::256>> = root_hash, proof_db) do
    [{root_hash, serialize_proof_to_list(proof_db)}]
  end

  defp serialize_proof_to_list(%{cache: cache}) do
    :gb_trees.to_list(cache)
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

  defp serialize_for_client(
         sender_id: sender_id,
         recipient_id: recipient_id,
         amount: amount,
         fee: fee,
         ttl: ttl,
         nonce: nonce,
         payload: payload
       ) do
    %{
      sender_id: :aeser_api_encoder.encode(:id_hash, sender_id),
      recipient_id: :aeser_api_encoder.encode(:id_hash, recipient_id),
      amount: amount,
      fee: fee,
      ttl: ttl,
      nonce: nonce,
      payload: payload
    }
  end

  defp serialize_for_client(
         account_id: account_id,
         nonce: nonce,
         query_format: query_format,
         response_format: response_format,
         query_fee: query_fee,
         ttl_type: ttl_type,
         ttl_value: ttl_value,
         fee: fee,
         ttl: ttl,
         abi_version: abi_version
       ) do
    %{
      account_id: :aeser_api_encoder.encode(:id_hash, account_id),
      nonce: nonce,
      query_format: query_format,
      response_format: response_format,
      query_fee: query_fee,
      ttl_type: SerializationUtils.ttl_type_for_client(ttl_type),
      ttl_value: ttl_value,
      fee: fee,
      ttl: ttl,
      abi_version: abi_version
    }
  end

  defp serialize_for_client(
         sender_id: sender_id,
         nonce: nonce,
         oracle_id: oracle_id,
         query: query,
         query_fee: query_fee,
         query_ttl_type: query_ttl_type,
         query_ttl_value: query_ttl_value,
         response_ttl_type: response_ttl_type,
         response_ttl_value: response_ttl_value,
         fee: fee,
         ttl: ttl
       ) do
    %{
      sender_id: :aeser_api_encoder.encode(:id_hash, sender_id),
      nonce: nonce,
      oracle_id: :aeser_api_encoder.encode(:id_hash, oracle_id),
      query: query,
      query_fee: query_fee,
      query_ttl_type: SerializationUtils.ttl_type_for_client(query_ttl_type),
      query_ttl_value: query_ttl_value,
      response_ttl_type: SerializationUtils.ttl_type_for_client(response_ttl_type),
      response_ttl_value: response_ttl_value,
      fee: fee,
      ttl: ttl
    }
  end

  defp serialize_for_client(
         oracle_id: oracle_id,
         nonce: nonce,
         query_id: query_id,
         response: response,
         response_ttl_type: response_ttl_type,
         response_ttl_value: response_ttl_value,
         fee: fee,
         ttl: ttl
       ) do
    %{
      oracle_id: :aeser_api_encoder.encode(:id_hash, oracle_id),
      nonce: nonce,
      query_id: :aeser_api_encoder.encode(:oracle_query_id, query_id),
      response: response,
      response_ttl_type: SerializationUtils.ttl_type_for_client(response_ttl_type),
      response_ttl_value: response_ttl_value,
      fee: fee,
      ttl: ttl
    }
  end

  defp serialize_for_client(
         oracle_id: oracle_id,
         nonce: nonce,
         oracle_ttl_type: oracle_ttl_type,
         oracle_ttl_value: oracle_ttl_value,
         fee: fee,
         ttl: ttl
       ) do
    %{
      oracle_id: :aeser_api_encoder.encode(:id_hash, oracle_id),
      nonce: nonce,
      oracle_ttl_type: SerializationUtils.ttl_type_for_client(oracle_ttl_type),
      oracle_ttl_value: oracle_ttl_value,
      fee: fee,
      ttl: ttl
    }
  end

  defp serialize_for_client(
         account_id: account_id,
         nonce: nonce,
         name: name,
         name_salt: name_salt,
         fee: fee,
         ttl: ttl
       ) do
    %{
      account_id: :aeser_api_encoder.encode(:id_hash, account_id),
      nonce: nonce,
      name: name,
      name_salt: name_salt,
      fee: fee,
      ttl: ttl
    }
  end

  defp serialize_for_client(
         account_id: account_id,
         nonce: nonce,
         commitment_id: commitment_id,
         fee: fee,
         ttl: ttl
       ) do
    %{
      account_id: :aeser_api_encoder.encode(:id_hash, account_id),
      nonce: nonce,
      commitment_id: :aeser_api_encoder.encode(:id_hash, commitment_id),
      fee: fee,
      ttl: ttl
    }
  end

  defp serialize_for_client(
         account_id: account_id,
         nonce: nonce,
         name_id: name_id,
         name_ttl: name_ttl,
         pointers: pointers,
         client_ttl: client_ttl,
         fee: fee,
         ttl: ttl
       ) do
    serialized_pointers =
      Enum.map(pointers, fn {key, id} ->
        %{key: key, id: :aeser_api_encoder.encode(:id_hash, id)}
      end)

    %{
      account_id: :aeser_api_encoder.encode(:id_hash, account_id),
      nonce: nonce,
      name_id: :aeser_api_encoder.encode(:id_hash, name_id),
      name_ttl: name_ttl,
      pointers: serialized_pointers,
      client_ttl: client_ttl,
      fee: fee,
      ttl: ttl
    }
  end

  defp serialize_for_client(
         account_id: account_id,
         nonce: nonce,
         name_id: name_id,
         fee: fee,
         ttl: ttl
       ) do
    %{
      account_id: :aeser_api_encoder.encode(:id_hash, account_id),
      nonce: nonce,
      name_id: :aeser_api_encoder.encode(:id_hash, name_id),
      fee: fee,
      ttl: ttl
    }
  end

  defp serialize_for_client(
         account_id: account_id,
         nonce: nonce,
         name_id: name_id,
         recipient_id: recipient_id,
         fee: fee,
         ttl: ttl
       ) do
    %{
      account_id: :aeser_api_encoder.encode(:id_hash, account_id),
      nonce: nonce,
      name_id: :aeser_api_encoder.encode(:id_hash, name_id),
      recipient_id: :aeser_api_encoder.encode(:id_hash, recipient_id),
      fee: fee,
      ttl: ttl
    }
  end

  defp serialize_for_client(
         owner_id: owner_id,
         nonce: nonce,
         code: code,
         ct_version: ct_version,
         fee: fee,
         ttl: ttl,
         deposit: deposit,
         amount: amount,
         gas: gas,
         gas_price: gas_price,
         call_data: call_data
       ) do
    %{
      owner_id: :aeser_api_encoder.encode(:id_hash, owner_id),
      nonce: nonce,
      code: :aeser_api_encoder.encode(:contract_bytearray, code),
      ct_version: ct_version,
      fee: fee,
      ttl: ttl,
      deposit: deposit,
      amount: amount,
      gas: gas,
      gas_price: gas_price,
      call_data: :aeser_api_encoder.encode(:contract_bytearray, call_data)
    }
  end

  defp serialize_for_client(
         caller_id: caller_id,
         nonce: nonce,
         contract_id: contract_id,
         abi_version: abi_version,
         fee: fee,
         ttl: ttl,
         amount: amount,
         gas: gas,
         gas_price: gas_price,
         call_data: call_data
       ) do
    %{
      caller_id: :aeser_api_encoder.encode(:id_hash, caller_id),
      nonce: nonce,
      contract_id: :aeser_api_encoder.encode(:id_hash, contract_id),
      abi_version: abi_version,
      fee: fee,
      ttl: ttl,
      amount: amount,
      gas: gas,
      gas_price: gas_price,
      call_data: :aeser_api_encoder.encode(:contract_bytearray, call_data)
    }
  end

  defp serialize_for_client(
         initiator_id: initiator_id,
         initiator_amount: initiator_amount,
         responder_id: responder_id,
         responder_amount: responder_amount,
         channel_reserve: channel_reserve,
         lock_period: lock_period,
         ttl: ttl,
         fee: fee,
         delegate_ids: delegate_ids,
         state_hash: state_hash,
         nonce: nonce
       ) do
    %{
      initiator_id: :aeser_api_encoder.encode(:id_hash, initiator_id),
      initiator_amount: initiator_amount,
      responder_id: :aeser_api_encoder.encode(:id_hash, responder_id),
      responder_amount: responder_amount,
      channel_reserve: channel_reserve,
      lock_period: lock_period,
      ttl: ttl,
      fee: fee,
      delegate_ids: Enum.map(delegate_ids, fn id -> :aeser_api_encoder.encode(:id_hash, id) end),
      state_hash: :aeser_api_encoder.encode(:state, state_hash),
      nonce: nonce
    }
  end

  defp serialize_for_client(
         channel_id: channel_id,
         from_id: from_id,
         amount: amount,
         ttl: ttl,
         fee: fee,
         state_hash: state_hash,
         round: round,
         nonce: nonce
       ) do
    %{
      channel_id: :aeser_api_encoder.encode(:id_hash, channel_id),
      from_id: :aeser_api_encoder.encode(:id_hash, from_id),
      amount: amount,
      ttl: ttl,
      fee: fee,
      state_hash: :aeser_api_encoder.encode(:state, state_hash),
      round: round,
      nonce: nonce
    }
  end

  defp serialize_for_client(
         channel_id: channel_id,
         to_id: to_id,
         amount: amount,
         ttl: ttl,
         fee: fee,
         state_hash: state_hash,
         round: round,
         nonce: nonce
       ) do
    %{
      channel_id: :aeser_api_encoder.encode(:id_hash, channel_id),
      to_id: :aeser_api_encoder.encode(:id_hash, to_id),
      amount: amount,
      ttl: ttl,
      fee: fee,
      state_hash: :aeser_api_encoder.encode(:state, state_hash),
      round: round,
      nonce: nonce
    }
  end

  defp serialize_for_client(
         channel_id: channel_id,
         from_id: from_id,
         initiator_amount_final: initiator_amount_final,
         responder_amount_final: responder_amount_final,
         ttl: ttl,
         fee: fee,
         nonce: nonce
       ) do
    %{
      channel_id: :aeser_api_encoder.encode(:id_hash, channel_id),
      from_id: :aeser_api_encoder.encode(:id_hash, from_id),
      initiator_amount_final: initiator_amount_final,
      responder_amount_final: responder_amount_final,
      ttl: ttl,
      fee: fee,
      nonce: nonce
    }
  end

  defp serialize_for_client(
         channel_id: channel_id,
         from_id: from_id,
         payload: payload,
         poi: poi,
         ttl: ttl,
         fee: fee,
         nonce: nonce
       ) do
    %{
      channel_id: :aeser_api_encoder.encode(:id_hash, channel_id),
      from_id: :aeser_api_encoder.encode(:id_hash, from_id),
      payload: :aeser_api_encoder.encode(:transaction, payload),
      poi: :aeser_api_encoder.encode(:poi, poi),
      ttl: ttl,
      fee: fee,
      nonce: nonce
    }
  end

  defp serialize_for_client(
         channel_id: channel_id,
         from_id: from_id,
         payload: payload,
         ttl: ttl,
         fee: fee,
         nonce: nonce
       ) do
    %{
      channel_id: :aeser_api_encoder.encode(:id_hash, channel_id),
      from_id: :aeser_api_encoder.encode(:id_hash, from_id),
      payload: :aeser_api_encoder.encode(:transaction, payload),
      ttl: ttl,
      fee: fee,
      nonce: nonce
    }
  end

  defp serialize_for_client(
         channel_id: channel_id,
         from_id: from_id,
         payload: payload,
         round: round,
         update: update,
         state_hash: state_hash,
         offchain_trees: offchain_trees,
         ttl: ttl,
         fee: fee,
         nonce: nonce
       ) do
    {type, _, _} = :aeser_chain_objects.deserialize_type_and_vsn(update)

    serialized_for_client_channel_offchain_update =
      update |> deserialize(type) |> serialize_for_client()

    %{
      channel_id: :aeser_api_encoder.encode(:id_hash, channel_id),
      from_id: :aeser_api_encoder.encode(:id_hash, from_id),
      payload: :aeser_api_encoder.encode(:transaction, payload),
      round: round,
      update: serialized_for_client_channel_offchain_update,
      state_hash: :aeser_api_encoder.encode(:state, state_hash),
      offchain_trees: :aeser_api_encoder.encode(:state_trees, offchain_trees),
      ttl: ttl,
      fee: fee,
      nonce: nonce
    }
  end

  defp serialize_for_client(from: from, to: to, amount: amount) do
    %{
      op: @channel_offchain_update_transfer_name,
      from: :aeser_api_encoder.encode(:id_hash, from),
      to: :aeser_api_encoder.encode(:id_hash, to),
      amount: amount
    }
  end

  defp serialize_for_client(from: from, amount: amount) do
    %{
      op: @channel_offchain_update_deposit_name,
      from: :aeser_api_encoder.encode(:id_hash, from),
      amount: amount
    }
  end

  defp serialize_for_client(to: to, amount: amount) do
    %{
      op: @channel_offchain_update_withdraw_name,
      to: :aeser_api_encoder.encode(:id_hash, to),
      amount: amount
    }
  end

  defp serialize_for_client(
         owner: owner,
         ct_version: ct_version,
         code: code,
         deposit: deposit,
         call_data: call_data
       ) do
    %{
      op: @channel_offchain_update_create_contract_name,
      owner: :aeser_api_encoder.encode(:id_hash, owner),
      ct_version: ct_version,
      code: :aeser_api_encoder.encode(:contract_bytearray, code),
      deposit: deposit,
      call_data: :aeser_api_encoder.encode(:contract_bytearray, call_data)
    }
  end

  defp serialize_for_client(
         caller: caller,
         contract: contract,
         abi_version: abi_version,
         amount: amount,
         gas: gas,
         gas_price: gas_price,
         call_data: call_data,
         call_stack: call_stack
       ) do
    %{
      op: @channel_offchain_update_call_contract_name,
      caller: :aeser_api_encoder.encode(:id_hash, caller),
      contract: :aeser_api_encoder.encode(:id_hash, contract),
      abi_version: abi_version,
      amount: amount,
      gas: gas,
      gas_price: gas_price,
      call_data: :aeser_api_encoder.encode(:contract_bytearray, call_data),
      call_stack: call_stack
    }
  end

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

  defp serialization_template(:sophia_byte_code) do
    [
      source_code_hash: :binary,
      type_info: [{:binary, :binary, :binary, :binary}],
      byte_code: :binary
    ]
  end

  defp serialization_template(:channel_create_tx) do
    [
      initiator_id: :id,
      initiator_amount: :int,
      responder_id: :id,
      responder_amount: :int,
      channel_reserve: :int,
      lock_period: :int,
      ttl: :int,
      fee: :int,
      delegate_ids: [:id],
      state_hash: :binary,
      nonce: :int
    ]
  end

  defp serialization_template(:channel_deposit_tx) do
    [
      channel_id: :id,
      from_id: :id,
      amount: :int,
      ttl: :int,
      fee: :int,
      state_hash: :binary,
      round: :int,
      nonce: :int
    ]
  end

  defp serialization_template(:channel_withdraw_tx) do
    [
      channel_id: :id,
      to_id: :id,
      amount: :int,
      ttl: :int,
      fee: :int,
      state_hash: :binary,
      round: :int,
      nonce: :int
    ]
  end

  defp serialization_template(:channel_close_mutual_tx) do
    [
      channel_id: :id,
      from_id: :id,
      initiator_amount_final: :int,
      responder_amount_final: :int,
      ttl: :int,
      fee: :int,
      nonce: :int
    ]
  end

  defp serialization_template(:channel_close_solo_tx) do
    [
      channel_id: :id,
      from_id: :id,
      payload: :binary,
      # TODO: specially for this kind of tx's, which has PoI field,  serializations/deserializations of Proof of Inclusions should be implemented.. ?
      poi: :binary,
      ttl: :int,
      fee: :int,
      nonce: :int
    ]
  end

  defp serialization_template(:channel_slash_tx) do
    [
      channel_id: :id,
      from_id: :id,
      payload: :binary,
      # TODO: specially for this kind of tx's, which has PoI field,  serializations/deserializations of Proof of Inclusions should be implemented.. ?
      poi: :binary,
      ttl: :int,
      fee: :int,
      nonce: :int
    ]
  end

  defp serialization_template(:channel_settle_tx) do
    [
      channel_id: :id,
      from_id: :id,
      initiator_amount_final: :int,
      responder_amount_final: :int,
      ttl: :int,
      fee: :int,
      nonce: :int
    ]
  end

  defp serialization_template(:channel_snapshot_solo_tx) do
    [
      channel_id: :id,
      from_id: :id,
      payload: :binary,
      ttl: :int,
      fee: :int,
      nonce: :int
    ]
  end

  defp serialization_template(:channel_force_progress_tx) do
    [
      channel_id: :id,
      from_id: :id,
      payload: :binary,
      round: :int,
      update: :binary,
      state_hash: :binary,
      offchain_trees: :binary,
      ttl: :int,
      fee: :int,
      nonce: :int
    ]
  end

  defp serialization_template(:ga_attach_tx) do
    [
      owner_id: :id,
      nonce: :int,
      code: :binary,
      auth_fun: :binary,
      ct_version: :int,
      fee: :int,
      ttl: :int,
      gas: :int,
      gas_price: :int,
      call_data: :binary
    ]
  end

  defp serialization_template(:ga_meta_tx) do
    [
      ga_id: :id,
      auth_data: :binary,
      abi_version: :int,
      fee: :int,
      gas: :int,
      gas_price: :int,
      ttl: :int,
      tx: :binary
    ]
  end

  defp serialization_template(:poi) do
    [
      accounts: [{:binary, [{:binary, [:binary]}]}],
      calls: [{:binary, [{:binary, [:binary]}]}],
      channels: [{:binary, [{:binary, [:binary]}]}],
      contracts: [{:binary, [{:binary, [:binary]}]}],
      ns: [{:binary, [{:binary, [:binary]}]}],
      oracles: [{:binary, [{:binary, [:binary]}]}]
    ]
  end

  defp serialization_template(:channel_offchain_update_transfer) do
    [from: :id, to: :id, amount: :int]
  end

  defp serialization_template(:channel_offchain_update_deposit) do
    [from: :id, amount: :int]
  end

  defp serialization_template(:channel_offchain_update_withdraw) do
    [to: :id, amount: :int]
  end

  defp serialization_template(:channel_offchain_update_create_contract) do
    [owner: :id, ct_version: :int, code: :binary, deposit: :int, call_data: :binary]
  end

  defp serialization_template(:channel_offchain_update_call_contract) do
    [
      caller: :id,
      contract: :id,
      abi_version: :int,
      amount: :int,
      gas: :int,
      gas_price: :int,
      call_data: :binary,
      call_stack: [:int]
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
  defp type_to_tag(:sophia_byte_code), do: @tag_sophia_byte_code
  defp type_to_tag(:ga_attach_tx), do: @tag_ga_attach_tx
  defp type_to_tag(:ga_meta_tx), do: @tag_ga_meta_tx

  defp type_to_tag(:channel_create_tx), do: @tag_channel_create_tx
  defp type_to_tag(:channel_deposit_tx), do: @tag_channel_deposit_tx
  defp type_to_tag(:channel_withdraw_tx), do: @tag_channel_withdraw_tx
  defp type_to_tag(:channel_close_mutual_tx), do: @tag_channel_close_mutual_tx
  defp type_to_tag(:channel_close_solo_tx), do: @tag_channel_close_solo_tx
  defp type_to_tag(:channel_slash_tx), do: @tag_channel_slash_tx
  defp type_to_tag(:channel_settle_tx), do: @tag_channel_settle_tx
  defp type_to_tag(:channel_snapshot_solo_tx), do: @tag_channel_snapshot_solo_tx
  defp type_to_tag(:channel_force_progress_tx), do: @tag_channel_force_progress_tx
  defp type_to_tag(:channel_offchain_update_transfer), do: @tag_channel_offchain_update_transfer
  defp type_to_tag(:channel_offchain_update_deposit), do: @tag_channel_offchain_update_deposit
  defp type_to_tag(:channel_offchain_update_withdraw), do: @tag_channel_offchain_update_withdraw

  defp type_to_tag(:channel_offchain_update_create_contract),
    do: @tag_channel_offchain_update_create_contract

  defp type_to_tag(:channel_offchain_update_call_contract),
    do: @tag_channel_offchain_update_call_contract

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
  defp version(:sophia_byte_code), do: @version_sophia_byte_code
  defp version(:channel_create_tx), do: @version_channel_create_tx
  defp version(:channel_deposit_tx), do: @version_channel_deposit_tx
  defp version(:channel_withdraw_tx), do: @version_channel_withdraw_tx
  defp version(:channel_close_mutual_tx), do: @version_channel_close_mutual_tx
  defp version(:channel_close_solo_tx), do: @version_channel_close_solo_tx
  defp version(:channel_slash_tx), do: @version_channel_slash_tx
  defp version(:channel_settle_tx), do: @version_channel_settle_tx
  defp version(:channel_snapshot_solo_tx), do: @version_channel_snapshot_solo_tx
  defp version(:channel_force_progress_tx), do: @version_channel_force_progress_tx
  defp version(:ga_attach_tx), do: @version_ga_attach_tx
  defp version(:ga_meta_tx), do: @version_ga_meta_tx
  defp version(:poi), do: @version_poi
  defp version(:channel_offchain_update_transfer), do: @version_channel_offchain_update_transfer
  defp version(:channel_offchain_update_deposit), do: @version_channel_offchain_update_deposit
  defp version(:channel_offchain_update_withdraw), do: @version_channel_offchain_update_withdraw

  defp version(:channel_offchain_update_create_contract),
    do: @version_channel_offchain_update_create_contract

  defp version(:channel_offchain_update_call_contract),
    do: @version_channel_offchain_update_call_contract
end
